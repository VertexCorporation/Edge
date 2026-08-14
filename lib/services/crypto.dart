import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart' as pc;

class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  static const _backupKeyPrefix = 'vertex-edge-e2ee-v1:';
  static const _privateKeyKey = 'e2ee_private_key';
  static const _publicKeyKey = 'e2ee_public_key';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'vertex_edge_e2ee',
    ),
    webOptions: WebOptions(
      dbName: 'vertex_edge_secure',
      publicKey: 'vertex_edge_e2ee',
    ),
  );

  Future<String> generateAndStoreKeys() async {
    final keyPair = _generateRSAKeyPair();
    final publicKey = keyPair.publicKey as pc.RSAPublicKey;
    final privateKey = keyPair.privateKey as pc.RSAPrivateKey;
    final publicKeyPem = _encodePublicKey(publicKey);
    final privateKeyPem = _encodePrivateKey(privateKey);
    await _storage.write(key: _privateKeyKey, value: privateKeyPem);
    await _storage.write(key: _publicKeyKey, value: publicKeyPem);
    return publicKeyPem;
  }

  Future<bool> hasKeys() async {
    try {
      final priv = await _storage.read(key: _privateKeyKey);
      return priv != null && priv.isNotEmpty;
    } catch (e) {
      debugPrint('E2EE: hasKeys check failed: $e');
      return false;
    }
  }

  Future<String?> getPublicKey() async {
    return _storage.read(key: _publicKeyKey);
  }

  Future<void> importKeys({
    required String privateKeyPem,
    required String publicKeyPem,
  }) async {
    await _storage.write(key: _privateKeyKey, value: privateKeyPem);
    await _storage.write(key: _publicKeyKey, value: publicKeyPem);
  }

  Future<String?> createKeyBackup(String userId) async {
    final privateKeyPem = await _storage.read(key: _privateKeyKey);
    if (privateKeyPem == null) return null;
    final key = enc.Key(_deriveBackupKeyBytes(userId));
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(privateKeyPem, iv: iv);
    return jsonEncode({'iv': iv.base64, 'data': encrypted.base64});
  }

  Future<bool> restoreFromKeyBackup(String userId, String backupJson) async {
    try {
      final payload = jsonDecode(backupJson) as Map<String, dynamic>;
      final iv = enc.IV.fromBase64(payload['iv'] as String);
      final key = enc.Key(_deriveBackupKeyBytes(userId));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final privateKeyPem = encrypter.decrypt64(payload['data'] as String, iv: iv);
      final privateKey = _parsePrivateKey(privateKeyPem);
      final publicKeyPem = _encodePublicKey(
        pc.RSAPublicKey(privateKey.modulus!, privateKey.publicExponent!),
      );
      await importKeys(privateKeyPem: privateKeyPem, publicKeyPem: publicKeyPem);
      return await hasKeys();
    } catch (e) {
      debugPrint('E2EE: restoreFromKeyBackup failed: $e');
      return false;
    }
  }

  static String normalizePublicKey(dynamic raw) {
    if (raw is String) return raw;
    if (raw is Map) return jsonEncode(raw);
    throw Exception('Invalid public key format');
  }

  Future<Map<String, String>> encryptMessage(
      String plaintext, dynamic receiverPublicKeyRaw) async {
    final receiverPublicKeyPem = normalizePublicKey(receiverPublicKeyRaw);
    final aesKey = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
    final encryptedMessage = encrypter.encrypt(plaintext, iv: iv);
    final rsaPublicKey = _parsePublicKey(receiverPublicKeyPem);
    final rsaEncrypter = enc.Encrypter(enc.RSA(publicKey: rsaPublicKey));
    final combinedKeyIv = '${aesKey.base64}:${iv.base64}';
    final encryptedKeyIv = rsaEncrypter.encrypt(combinedKeyIv);
    return {
      'message': encryptedMessage.base64,
      'key': encryptedKeyIv.base64,
    };
  }

  Future<String> decryptMessage(
      String encryptedMessageBase64, String encryptedKeyIvBase64) async {
    final privateKeyPem = await _storage.read(key: _privateKeyKey);
    if (privateKeyPem == null) throw Exception('Private key not found');
    final rsaPrivateKey = _parsePrivateKey(privateKeyPem);
    final rsaEncrypter = enc.Encrypter(enc.RSA(privateKey: rsaPrivateKey));
    final decryptedKeyIv = rsaEncrypter.decrypt64(encryptedKeyIvBase64);
    final parts = decryptedKeyIv.split(':');
    if (parts.length != 2) throw Exception('Invalid key payload');
    final aesKey = enc.Key.fromBase64(parts[0]);
    final iv = enc.IV.fromBase64(parts[1]);
    final aesEncrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
    return aesEncrypter.decrypt64(encryptedMessageBase64, iv: iv);
  }

  // --- Helpers ---

  Uint8List _deriveBackupKeyBytes(String userId) {
    final digest = pc.SHA256Digest();
    return digest.process(
        Uint8List.fromList(utf8.encode('$_backupKeyPrefix$userId')));
  }

  pc.AsymmetricKeyPair<pc.PublicKey, pc.PrivateKey> _generateRSAKeyPair() {
    final secureRandom = pc.SecureRandom('Fortuna')
      ..seed(pc.KeyParameter(Uint8List.fromList(
          List.generate(32, (_) => Random.secure().nextInt(255)))));
    final keyGen = pc.KeyGenerator('RSA');
    keyGen.init(pc.ParametersWithRandom(
      pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
      secureRandom,
    ));
    return keyGen.generateKeyPair();
  }

  String _encodePublicKey(pc.RSAPublicKey key) => jsonEncode({
        'n': key.modulus!.toString(),
        'e': key.exponent!.toString(),
      });

  pc.RSAPublicKey _parsePublicKey(String json) {
    final m = jsonDecode(json) as Map;
    return pc.RSAPublicKey(BigInt.parse(m['n']), BigInt.parse(m['e']));
  }

  String _encodePrivateKey(pc.RSAPrivateKey key) => jsonEncode({
        'n': key.modulus!.toString(),
        'e': key.publicExponent!.toString(),
        'd': key.privateExponent!.toString(),
        'p': key.p!.toString(),
        'q': key.q!.toString(),
      });

  pc.RSAPrivateKey _parsePrivateKey(String json) {
    final m = jsonDecode(json) as Map;
    return pc.RSAPrivateKey(
      BigInt.parse(m['n']),
      BigInt.parse(m['d']),
      BigInt.parse(m['p']),
      BigInt.parse(m['q']),
    );
  }
}
