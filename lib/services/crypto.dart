import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart' as pc;

/// Manages End-to-End Encryption (E2EE) using RSA and AES.
/// RSA is used for exchanging AES keys, and AES is used for encrypting messages.
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  static const _backupKeyPrefix = 'vertex-edge-e2ee-v1:';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'vertex_edge_e2ee',
    ),
    webOptions: WebOptions(
      dbName: 'vertex_edge_secure',
      publicKey: 'vertex_edge_e2ee',
    ),
  );
  
  static const _privateKeyKey = 'e2ee_private_key';
  static const _publicKeyKey = 'e2ee_public_key';

  /// Generates an RSA Key Pair (2048 bits) and stores the Private Key in Secure Storage.
  /// Returns the Public Key in PEM format to be uploaded to Firestore.
  Future<String> generateAndStoreKeys() async {
    final keyPair = _generateRSAKeyPair();
    
    final publicKey = keyPair.publicKey as pc.RSAPublicKey;
    final privateKey = keyPair.privateKey as pc.RSAPrivateKey;

    final publicKeyPem = _encodeRSAPublicKeyToPem(publicKey);
    final privateKeyPem = _encodeRSAPrivateKeyToPem(privateKey);

    await _storage.write(key: _privateKeyKey, value: privateKeyPem);
    await _storage.write(key: _publicKeyKey, value: publicKeyPem);

    return publicKeyPem;
  }

  /// Check if keys exist in secure storage
  Future<bool> hasKeys() async {
    try {
      final priv = await _storage.read(key: _privateKeyKey);
      return priv != null && priv.isNotEmpty;
    } catch (e) {
      debugPrint('E2EE: hasKeys check failed: $e');
      return false;
    }
  }

  /// Get the stored public key PEM
  Future<String?> getPublicKey() async {
    return await _storage.read(key: _publicKeyKey);
  }

  /// Import an existing key pair into secure storage (e.g. after cloud restore).
  Future<void> importKeys({
    required String privateKeyPem,
    required String publicKeyPem,
  }) async {
    await _storage.write(key: _privateKeyKey, value: privateKeyPem);
    await _storage.write(key: _publicKeyKey, value: publicKeyPem);
  }

  /// Encrypt the private key for Firestore backup (scoped to user id).
  Future<String?> createKeyBackup(String userId) async {
    final privateKeyPem = await _storage.read(key: _privateKeyKey);
    if (privateKeyPem == null) return null;

    final key = enc.Key(_deriveBackupKeyBytes(userId));
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(privateKeyPem, iv: iv);

    return jsonEncode({
      'iv': iv.base64,
      'data': encrypted.base64,
    });
  }

  /// Restore private key from Firestore backup and derive public key locally.
  Future<bool> restoreFromKeyBackup(String userId, String backupJson) async {
    try {
      final payload = jsonDecode(backupJson) as Map<String, dynamic>;
      final iv = enc.IV.fromBase64(payload['iv'] as String);
      final key = enc.Key(_deriveBackupKeyBytes(userId));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final privateKeyPem = encrypter.decrypt64(payload['data'] as String, iv: iv);

      final privateKey = _parseRSAPrivateKeyFromPem(privateKeyPem);
      final publicKeyPem = _encodeRSAPublicKeyToPem(
        pc.RSAPublicKey(privateKey.modulus!, privateKey.publicExponent!),
      );

      await importKeys(privateKeyPem: privateKeyPem, publicKeyPem: publicKeyPem);
      return await hasKeys();
    } catch (e) {
      debugPrint('E2EE: restoreFromKeyBackup failed: $e');
      return false;
    }
  }

  /// Normalizes Firestore public key values to JSON string format.
  static String normalizePublicKey(dynamic raw) {
    if (raw is String) return raw;
    if (raw is Map) return jsonEncode(raw);
    throw Exception('Invalid public key format');
  }

  /// Encrypts a message for a specific user using their public key.
  /// Generates a random AES key, encrypts the message with AES, 
  /// and encrypts the AES key with the receiver's RSA public key.
  Future<Map<String, String>> encryptMessage(String plaintext, dynamic receiverPublicKeyRaw) async {
    final receiverPublicKeyPem = normalizePublicKey(receiverPublicKeyRaw);
    // Generate AES key (256-bit) and IV
    final aesKey = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);

    // Encrypt message with AES
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
    final encryptedMessage = encrypter.encrypt(plaintext, iv: iv);

    // Encrypt AES key and IV with Receiver's RSA Public Key
    final rsaPublicKey = _parseRSAPublicKeyFromPem(receiverPublicKeyPem);
    final rsaEncrypter = enc.Encrypter(enc.RSA(publicKey: rsaPublicKey));
    
    // Combine AES key and IV, then encrypt
    final combinedKeyIv = '${aesKey.base64}:${iv.base64}';
    final encryptedKeyIv = rsaEncrypter.encrypt(combinedKeyIv);

    return {
      'message': encryptedMessage.base64,
      'key': encryptedKeyIv.base64,
    };
  }

  /// Decrypts a received message using the local Private Key.
  Future<String> decryptMessage(String encryptedMessageBase64, String encryptedKeyIvBase64) async {
    final privateKeyPem = await _storage.read(key: _privateKeyKey);
    if (privateKeyPem == null) throw Exception("Private key not found");

    final rsaPrivateKey = _parseRSAPrivateKeyFromPem(privateKeyPem);
    final rsaEncrypter = enc.Encrypter(enc.RSA(privateKey: rsaPrivateKey));

    // Decrypt the AES key and IV
    final decryptedKeyIv = rsaEncrypter.decrypt64(encryptedKeyIvBase64);
    final parts = decryptedKeyIv.split(':');
    if (parts.length != 2) throw Exception("Invalid key payload");

    final aesKey = enc.Key.fromBase64(parts[0]);
    final iv = enc.IV.fromBase64(parts[1]);

    // Decrypt the actual message with AES
    final aesEncrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
    final decryptedMessage = aesEncrypter.decrypt64(encryptedMessageBase64, iv: iv);

    return decryptedMessage;
  }

  // --- Helpers ---

  Uint8List _deriveBackupKeyBytes(String userId) {
    final digest = pc.SHA256Digest();
    return digest.process(Uint8List.fromList(utf8.encode('$_backupKeyPrefix$userId')));
  }

  pc.AsymmetricKeyPair<pc.PublicKey, pc.PrivateKey> _generateRSAKeyPair() {
    final secureRandom = pc.SecureRandom('Fortuna')
      ..seed(pc.KeyParameter(Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(255)))));

    final keyGen = pc.KeyGenerator('RSA');
    keyGen.init(pc.ParametersWithRandom(
      pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
      secureRandom,
    ));

    return keyGen.generateKeyPair();
  }

  String _encodeRSAPublicKeyToPem(pc.RSAPublicKey publicKey) {
    // Using a simplistic encoding, but actually package:encrypt RSAKeyParser might only read.
    // For simplicity we will use basic DER encoding wrapped in base64 as pseudo-PEM since 
    // pointycastle parsing is complex, or better use encrypt's own utilities.
    // Wait, encrypt package does not expose PEM encoders.
    // We can use dart's ASN1 structure or manually construct it.
    // Actually, encrypt provides no direct public key to PEM.
    // Let's implement a basic one or just store n and e as strings.
    // Storing Modulus and Exponent is much easier than ASN.1 encoding.
    final Map<String, String> keyData = {
      'n': publicKey.modulus!.toString(),
      'e': publicKey.exponent!.toString(),
    };
    return jsonEncode(keyData);
  }

  pc.RSAPublicKey _parseRSAPublicKeyFromPem(String pem) {
    final map = jsonDecode(pem);
    return pc.RSAPublicKey(BigInt.parse(map['n']), BigInt.parse(map['e']));
  }

  String _encodeRSAPrivateKeyToPem(pc.RSAPrivateKey privateKey) {
    final Map<String, String> keyData = {
      'n': privateKey.modulus!.toString(),
      'e': privateKey.publicExponent!.toString(),
      'd': privateKey.privateExponent!.toString(),
      'p': privateKey.p!.toString(),
      'q': privateKey.q!.toString(),
    };
    return jsonEncode(keyData);
  }

  pc.RSAPrivateKey _parseRSAPrivateKeyFromPem(String pem) {
    final map = jsonDecode(pem);
    return pc.RSAPrivateKey(
      BigInt.parse(map['n']),
      BigInt.parse(map['d']),
      BigInt.parse(map['p']),
      BigInt.parse(map['q']),
    );
  }
}
