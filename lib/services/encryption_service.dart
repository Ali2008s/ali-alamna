import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Project-wide encryption service for downloads and secure local data.
///
/// Features:
/// - 256-bit AES encryption key stored securely in Keystore (Android) / Keychain (iOS)
/// - AES-CBC mode with a fresh random IV (Initialization Vector) per encryption
/// - Cipher format: 'base64(iv):base64(cipher)' for easy storage
/// - File-level encryption/decryption support
/// - Additional utility methods for hashing and simple obfuscation
///
/// Usage:
/// 1. Call `initialize()` once at app startup
/// 2. Use encrypt/decrypt methods as needed
/// 3. All encryption operations use the same device-bound key
class EncryptionService {
  static const String _keyName = 'encryption_device_key_v1';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Encrypter? _encrypter;

  /// Initializes the encryption service.
  ///
  /// This method MUST be called once at app startup (e.g., in main()).
  /// - Retrieves or generates a 256-bit AES key
  /// - Stores the key securely in device Keystore/Keychain
  /// - Initializes the Encrypter instance with AES-CBC mode
  ///
  /// Throws: Exception if secure storage is unavailable
  static Future<void> initialize() async {
    String? base64Key = await _secureStorage.read(key: _keyName);

    // Generate and store a new key if one doesn't exist
    if (base64Key == null) {
      base64Key = _generateKeyBase64();
      await _secureStorage.write(key: _keyName, value: base64Key);
    }

    final key = Key.fromBase64(base64Key);
    _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  }

  /// Generates a cryptographically secure random 256-bit AES key.
  ///
  /// Returns: Base64-encoded key string
  static String _generateKeyBase64() {
    final key = Key.fromSecureRandom(32); // 32 bytes = 256 bits
    return key.base64;
  }

  /// Encrypts a UTF-8 string using AES-256-CBC.
  ///
  /// Process:
  /// 1. Generates a random 16-byte IV for this encryption
  /// 2. Encrypts the plaintext using AES-CBC
  /// 3. Returns format: 'base64(iv):base64(cipher)'
  ///
  /// Parameters:
  /// - [plainText]: The string to encrypt
  ///
  /// Returns: Encrypted string in 'iv:cipher' format
  ///
  /// Example:
  /// ```dart
  /// final encrypted = await EncryptionService.encrypt('my secret');
  /// // Returns: 'dGVzdGl2MTIzNDU2Nzg=:YWJjZGVmZ2hpamtsbW5vcA=='
  /// ```
  static Future<String> encrypt(String plainText) async {
    _ensureInit();
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter!.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts an AES-256-CBC encrypted string.
  ///
  /// Process:
  /// 1. Splits the input into IV and ciphertext
  /// 2. Decrypts using AES-CBC with the extracted IV
  /// 3. Decodes the result as UTF-8 string
  ///
  /// Parameters:
  /// - [encryptedText]: Encrypted string in 'base64(iv):base64(cipher)' format
  ///
  /// Returns: Decrypted plaintext string
  ///
  /// Throws: FormatException if input format is invalid
  static Future<String> decrypt(String encryptedText) async {
    _ensureInit();
    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw const FormatException(
        'Invalid encrypted data format. Expected "iv:cipher"',
      );
    }

    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    final bytes = _encrypter!.decryptBytes(encrypted, iv: iv);
    return utf8.decode(bytes);
  }

  /// Encrypts raw binary data using AES-256-CBC.
  ///
  /// Useful for encrypting file contents, images, or any binary data.
  ///
  /// Parameters:
  /// - [bytes]: Raw bytes to encrypt
  ///
  /// Returns: Encrypted data in 'base64(iv):base64(cipher)' format
  ///
  /// Example:
  /// ```dart
  /// final videoBytes = await File('video.mp4').readAsBytes();
  /// final encrypted = await EncryptionService.encryptBytes(videoBytes);
  /// ```
  static Future<String> encryptBytes(List<int> bytes) async {
    _ensureInit();
    final iv = IV.fromSecureRandom(16);
    final encrypted = _encrypter!.encryptBytes(bytes, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts to raw binary data.
  ///
  /// Converts encrypted string back to original bytes.
  ///
  /// Parameters:
  /// - [serializedCipher]: Encrypted string in 'base64(iv):base64(cipher)' format
  ///
  /// Returns: Decrypted bytes as List of int
  ///
  /// Throws: FormatException if input format is invalid
  static Future<List<int>> decryptToBytes(String serializedCipher) async {
    _ensureInit();
    final parts = serializedCipher.split(':');
    if (parts.length != 2) {
      throw const FormatException(
        'Invalid encrypted data format. Expected "iv:cipher"',
      );
    }

    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    return _encrypter!.decryptBytes(encrypted, iv: iv);
  }

  /// Encrypts a file and saves it with '.enc' extension.
  ///
  /// Process:
  /// 1. Reads the entire file into memory
  /// 2. Encrypts the bytes
  /// 3. Writes the encrypted string to '{{original_path}}.enc'
  ///
  /// Parameters:
  /// - [filePath]: Path to the file to encrypt
  ///
  /// Returns: Path to the encrypted file
  ///
  /// Example:
  /// ```dart
  /// final encPath = await EncryptionService.encryptFile('/path/video.mp4');
  /// // Creates: '/path/video.mp4.enc'
  /// ```
  ///
  /// Warning: Loads entire file into memory - not suitable for very large files
  static Future<String> encryptFile(String filePath) async {
    _ensureInit();
    final data = await File(filePath).readAsBytes();
    final serialized = await encryptBytes(data);
    final out = '$filePath.enc';
    await File(out).writeAsString(serialized, flush: true);
    return out;
  }

  /// Decrypts a '.enc' file and saves it with '.dec' extension.
  ///
  /// Process:
  /// 1. Reads the encrypted file as string
  /// 2. Decrypts to binary data
  /// 3. Writes decrypted bytes to file (replaces '.enc' with '.dec')
  ///
  /// Parameters:
  /// - [encPath]: Path to the encrypted '.enc' file
  ///
  /// Returns: Path to the decrypted file
  ///
  /// Example:
  /// ```dart
  /// final decPath = await EncryptionService.decryptFile('/path/video.mp4.enc');
  /// // Creates: '/path/video.mp4.dec'
  /// ```
  ///
  /// Warning: Loads entire file into memory - not suitable for very large files
  static Future<String> decryptFile(String encPath) async {
    _ensureInit();
    final serialized = await File(encPath).readAsString();
    final bytes = await decryptToBytes(serialized);
    final out = encPath.replaceFirst('.enc', '.dec');
    await File(out).writeAsBytes(bytes, flush: true);
    return out;
  }

  /// Simple XOR-based obfuscation (NOT cryptographically secure).
  ///
  /// ⚠️ WARNING: This is NOT real encryption! Use only for:
  /// - Light obfuscation of non-sensitive data
  /// - Preventing casual inspection
  /// - NOT for security-critical data
  ///
  /// Parameters:
  /// - [plainText]: Text to obfuscate
  /// - [key]: Obfuscation key (any string)
  ///
  /// Returns: Base64-encoded obfuscated text
  static String simpleEncrypt(String plainText, String key) {
    final keyBytes = utf8.encode(key);
    final textBytes = utf8.encode(plainText);
    final encrypted = List<int>.generate(
      textBytes.length,
          (i) => textBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64.encode(encrypted);
  }

  /// Simple XOR-based deobfuscation.
  ///
  /// Reverses the simpleEncrypt operation.
  ///
  /// Parameters:
  /// - [encryptedText]: Base64-encoded obfuscated text
  /// - [key]: Same key used for obfuscation
  ///
  /// Returns: Original plaintext
  static String simpleDecrypt(String encryptedText, String key) {
    final keyBytes = utf8.encode(key);
    final encryptedBytes = base64.decode(encryptedText);
    final decrypted = List<int>.generate(
      encryptedBytes.length,
          (i) => encryptedBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return utf8.decode(decrypted);
  }

  /// Generates SHA-256 hash of input string.
  ///
  /// Useful for:
  /// - Creating checksums
  /// - Verifying data integrity
  /// - Generating unique identifiers
  ///
  /// Parameters:
  /// - [input]: String to hash
  ///
  /// Returns: Hexadecimal SHA-256 hash (64 characters)
  ///
  /// Example:
  /// ```dart
  /// final hash = EncryptionService.hashString('password123');
  /// // Returns: 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f'
  /// ```
  static String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a device-specific random key.
  ///
  /// Creates a unique key based on:
  /// - Current timestamp
  /// - Cryptographically secure random number
  /// - Hashed with SHA-256
  ///
  /// Returns: SHA-256 hash string (64 characters)
  ///
  /// Use case: Generating unique device identifiers
  static String generateDeviceKey() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final rnd = Random.secure().nextInt(999999).toString().padLeft(6, '0');
    return hashString('$ts$rnd');
  }

  /// Clears all encrypted data from secure storage.
  ///
  /// ⚠️ WARNING: This will delete the encryption key!
  /// - All previously encrypted data will become unrecoverable
  /// - Use only for logout, account deletion, or factory reset scenarios
  ///
  /// After calling this, you must call initialize() again before using encryption.
  static Future<void> clearAllEncryptedData() async {
    await _secureStorage.deleteAll();
    _encrypter = null; // Reset encrypter instance
  }

  /// Checks if encryption is available on this device.
  ///
  /// Tests if FlutterSecureStorage is working properly.
  ///
  /// Returns: true if encryption is available, false otherwise
  static Future<bool> isEncryptionAvailable() async {
    try {
      await _secureStorage.containsKey(key: _keyName);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Internal check to ensure initialization.
  ///
  /// Throws StateError if initialize() hasn't been called.
  static void _ensureInit() {
    if (_encrypter == null) {
      throw StateError(
        'EncryptionService not initialized. Call initialize() at app startup.',
      );
    }
  }
}