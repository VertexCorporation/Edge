import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart' as pc;

/// Manages End-to-End Encryption (E2EE) using RSA and AES.
/// RSA is used for exchanging AES keys, and AES is used for encrypting messages.
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _storage = const FlutterSecureStorage();
  
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
    final priv = await _storage.read(key: _privateKeyKey);
    return priv != null;
  }

  /// Get the stored public key PEM
  Future<String?> getPublicKey() async {
    return await _storage.read(key: _publicKeyKey);
  }

  /// Encrypts a message for a specific user using their public key.
  /// Generates a random AES key, encrypts the message with AES, 
  /// and encrypts the AES key with the receiver's RSA public key.
  Future<Map<String, String>> encryptMessage(String plaintext, String receiverPublicKeyPem) async {
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
