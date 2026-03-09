import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/services/encryption_service.dart';

/// Enhanced local storage service with optional encryption support.
///
/// Features:
/// - Automatic encryption/decryption for sensitive data
/// - Type-safe getter/setter methods
/// - JSON support with encryption
/// - Fallback mechanism for encryption failures
/// - Migration utility for existing unencrypted data
///
/// Usage:
/// ```dart
/// // Store encrypted data
/// await setValue('user_token', 'abc123', encrypt: true);
///
/// // Retrieve encrypted data
/// final token = await getValue<String>('user_token', decrypt: true);
/// ```
class LocalStorage {
  static GetStorage? _localStorage;
  static bool _encryptionEnabled = true;

  /// Initialize the local storage.
  /// Call this once at app startup before using any storage methods.
  static Future<void> init() async {
    await GetStorage.init();
    _localStorage = GetStorage();
  }

  /// Get the storage instance.
  /// Throws StateError if not initialized.
  static GetStorage get localStorage {
    if (_localStorage == null) {
      throw StateError(
        'LocalStorage not initialized. Call init() at app startup.',
      );
    }
    return _localStorage!;
  }

  /// Sets a value with optional encryption.
  ///
  /// Automatically encrypts the value if encryption is enabled and [encrypt] is true.
  /// Falls back to unencrypted storage if encryption fails.
  ///
  /// Parameters:
  /// - [key]: Storage key
  /// - [value]: Value to store (will be converted to string for encryption)
  /// - [encrypt]: Whether to encrypt the value (default: true)
  ///
  /// Example:
  /// ```dart
  /// await setValue('api_key', 'secret123', encrypt: true);
  /// await setValue('theme_mode', 'dark', encrypt: false);
  /// ```
  static Future<void> setValue(
    String key,
    dynamic value, {
    bool encrypt = true,
  }) async {
    try {
      if (_encryptionEnabled && encrypt) {
        final stringValue = value.toString();
        final encryptedValue = await EncryptionService.encrypt(stringValue);
        localStorage.write(key, encryptedValue);
      } else {
        localStorage.write(key, value);
      }
    } catch (e) {
      log('setValue error for key "$key": $e');
      // Fallback to unencrypted storage on error
      localStorage.write(key, value);
    }
  }

  /// Gets a value with optional decryption.
  ///
  /// Automatically decrypts the value if encryption is enabled and [decrypt] is true.
  /// Returns null if key doesn't exist or decryption fails.
  ///
  /// Parameters:
  /// - [key]: Storage key
  /// - [decrypt]: Whether to decrypt the value (default: true)
  ///
  /// Returns: The value cast to type T, or null if not found
  ///
  /// Example:
  /// ```dart
  /// final token = await getValue<String>('user_token');
  /// final userId = await getValue<int>('user_id');
  /// ```
  static Future<T?> getValue<T>(
    String key, {
    bool decrypt = true,
  }) async {
    try {
      final value = localStorage.read(key);
      if (value == null) return null;

      // If encryption is enabled and value is a string, try to decrypt
      if (_encryptionEnabled && decrypt && value is String) {
        try {
          final decryptedValue = await EncryptionService.decrypt(value);

          // Convert to the expected type
          return _convertToType<T>(decryptedValue);
        } catch (e) {
          log('Decryption failed for key "$key", returning raw value: $e');
          // If decryption fails, return raw value (might be unencrypted)
          return value as T?;
        }
      }

      // Return raw value if not encrypted
      return value as T?;
    } catch (e) {
      log('getValue error for key "$key": $e');
      return null;
    }
  }

  /// Helper method to convert string to specific type.
  static T? _convertToType<T>(String value) {
    try {
      if (T == String) return value as T;
      if (T == int) return int.parse(value) as T;
      if (T == double) return double.parse(value) as T;
      if (T == bool) return (value.toLowerCase() == 'true') as T;

      // Default: return as string if type is dynamic
      return value as T;
    } catch (e) {
      log('Type conversion error: $e');
      return null;
    }
  }

  /// Sets JSON data with encryption.
  ///
  /// Automatically converts Map to JSON string and encrypts it.
  ///
  /// Parameters:
  /// - [key]: Storage key
  /// - [jsonData]: Map to store
  /// - [encrypt]: Whether to encrypt (default: true)
  ///
  /// Throws: Exception if JSON encoding fails
  ///
  /// Example:
  /// ```dart
  /// await setJsonToLocal('user_data', {
  ///   'name': 'John',
  ///   'age': 30,
  /// });
  /// ```
  static Future<void> setJsonToLocal(
    String key,
    Map<String, dynamic> jsonData, {
    bool encrypt = true,
  }) async {
    try {
      final jsonString = jsonEncode(jsonData);
      await setValue(key, jsonString, encrypt: encrypt);
    } catch (e) {
      log('setJsonToLocal error for key "$key": $e');
      throw Exception('Failed to store JSON data: $e');
    }
  }

  /// Gets JSON data with decryption.
  ///
  /// Automatically decrypts and parses JSON string to Map.
  ///
  /// Parameters:
  /// - [key]: Storage key
  /// - [decrypt]: Whether to decrypt (default: true)
  ///
  /// Returns: Parsed Map or null if not found/invalid
  ///
  /// Example:
  /// ```dart
  /// final userData = await getJsonFromLocal('user_data');
  /// print(userData?['name']); // 'John'
  /// ```
  static Future<Map<String, dynamic>?> getJsonFromLocal(
    String key, {
    bool decrypt = true,
  }) async {
    try {
      final jsonString = await getValue<String>(key, decrypt: decrypt);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      log('getJsonFromLocal error for key "$key": $e');
      return null;
    }
  }

  /// Sets a boolean value with encryption.
  ///
  /// Example:
  /// ```dart
  /// await setBoolToLocal('is_logged_in', true);
  /// ```
  static Future<void> setBoolToLocal(
    String key,
    bool value, {
    bool encrypt = true,
  }) async {
    await setValue(key, value.toString(), encrypt: encrypt);
  }

  /// Gets a boolean value with decryption.
  ///
  /// Parameters:
  /// - [key]: Storage key
  /// - [defaultValue]: Value to return if key doesn't exist (default: false)
  /// - [decrypt]: Whether to decrypt (default: true)
  ///
  /// Example:
  /// ```dart
  /// final isLoggedIn = await getBoolFromLocal('is_logged_in');
  /// ```
  static Future<bool> getBoolFromLocal(
    String key, {
    bool defaultValue = false,
    bool decrypt = true,
  }) async {
    try {
      final value = await getValue<String>(key, decrypt: decrypt);
      if (value == null) return defaultValue;
      return value.toLowerCase() == 'true';
    } catch (e) {
      log('getBoolFromLocal error for key "$key": $e');
      return defaultValue;
    }
  }

  /// Sets an integer value with encryption.
  ///
  /// Example:
  /// ```dart
  /// await setIntToLocal('user_id', 12345);
  /// ```
  static Future<void> setIntToLocal(
    String key,
    int value, {
    bool encrypt = true,
  }) async {
    await setValue(key, value.toString(), encrypt: encrypt);
  }

  /// Gets an integer value with decryption.
  ///
  /// Parameters:
  /// - [key]: Storage key
  /// - [defaultValue]: Value to return if key doesn't exist (default: 0)
  /// - [decrypt]: Whether to decrypt (default: true)
  ///
  /// Example:
  /// ```dart
  /// final userId = await getIntFromLocal('user_id', defaultValue: -1);
  /// ```
  static Future<int> getIntFromLocal(
    String key, {
    int defaultValue = 0,
    bool decrypt = true,
  }) async {
    try {
      final value = await getValue<String>(key, decrypt: decrypt);
      if (value == null) return defaultValue;
      return int.parse(value);
    } catch (e) {
      log('getIntFromLocal error for key "$key": $e');
      return defaultValue;
    }
  }

  /// Sets a double value with encryption.
  ///
  /// Example:
  /// ```dart
  /// await setDoubleToLocal('rating', 4.5);
  /// ```
  static Future<void> setDoubleToLocal(
    String key,
    double value, {
    bool encrypt = true,
  }) async {
    await setValue(key, value.toString(), encrypt: encrypt);
  }

  /// Gets a double value with decryption.
  ///
  /// Parameters:
  /// - [key]: Storage key
  /// - [defaultValue]: Value to return if key doesn't exist (default: 0.0)
  /// - [decrypt]: Whether to decrypt (default: true)
  ///
  /// Example:
  /// ```dart
  /// final rating = await getDoubleFromLocal('rating', defaultValue: 0.0);
  /// ```
  static Future<double> getDoubleFromLocal(
    String key, {
    double defaultValue = 0.0,
    bool decrypt = true,
  }) async {
    try {
      final value = await getValue<String>(key, decrypt: decrypt);
      if (value == null) return defaultValue;
      return double.parse(value);
    } catch (e) {
      log('getDoubleFromLocal error for key "$key": $e');
      return defaultValue;
    }
  }

  /// Sets a string list with encryption.
  ///
  /// Automatically converts list to JSON and encrypts it.
  ///
  /// Example:
  /// ```dart
  /// await setStringListToLocal('favorite_ids', ['1', '2', '3']);
  /// ```
  static Future<void> setStringListToLocal(
    String key,
    List<String> value, {
    bool encrypt = true,
  }) async {
    try {
      final jsonString = jsonEncode(value);
      await setValue(key, jsonString, encrypt: encrypt);
    } catch (e) {
      log('setStringListToLocal error for key "$key": $e');
      throw Exception('Failed to store string list: $e');
    }
  }

  /// Gets a string list with decryption.
  ///
  /// Automatically decrypts and parses JSON array to List os String.
  ///
  /// Example:
  /// ```dart
  /// final favoriteIds = await getStringListFromLocal('favorite_ids');
  /// ```
  static Future<List<String>?> getStringListFromLocal(
    String key, {
    bool decrypt = true,
  }) async {
    try {
      final jsonString = await getValue<String>(key, decrypt: decrypt);
      if (jsonString == null) return null;

      final List<dynamic> list = jsonDecode(jsonString);
      return list.cast<String>();
    } catch (e) {
      log('getStringListFromLocal error for key "$key": $e');
      return null;
    }
  }

  /// Removes a value from storage.
  ///
  /// Example:
  /// ```dart
  /// removeValue('user_token');
  /// ```
  static void removeValue(String key) {
    try {
      localStorage.remove(key);
    } catch (e) {
      log('removeValue error for key "$key": $e');
    }
  }

  /// Checks if a key exists in storage.
  ///
  /// Example:
  /// ```dart
  /// if (hasKey('user_token')) {
  ///   // User is logged in
  /// }
  /// ```
  static bool hasKey(String key) {
    try {
      return localStorage.hasData(key);
    } catch (e) {
      log('hasKey error for key "$key": $e');
      return false;
    }
  }

  /// Gets all keys stored in local storage.
  ///
  /// Example:
  /// ```dart
  /// final keys = getAllKeys();
  /// print('Total keys: ${keys.length}');
  /// ```
  static List<String> getAllKeys() {
    try {
      return localStorage.getKeys().toList();
    } catch (e) {
      log('getAllKeys error: $e');
      return [];
    }
  }

  /// Clears all data from storage.
  ///
  /// ⚠️ WARNING: This will delete ALL stored data!
  ///
  /// Example:
  /// ```dart
  /// clearAll(); // Use for logout
  /// ```
  static void clearAll() {
    try {
      localStorage.erase();
    } catch (e) {
      log('clearAll error: $e');
    }
  }

  /// Migrates existing unencrypted data to encrypted storage.
  ///
  /// This method:
  /// 1. Reads all existing keys
  /// 2. Re-encrypts their values
  /// 3. Writes them back to storage
  ///
  /// ⚠️ WARNING: Run this only once during app update!
  ///
  /// Example:
  /// ```dart
  /// await migrateToEncrypted(); // Run once after adding encryption
  /// ```
  static Future<void> migrateToEncrypted() async {
    try {
      final keys = localStorage.getKeys().toList();
      log('Starting migration for ${keys.length} keys...');

      int successCount = 0;
      int failureCount = 0;

      for (final key in keys) {
        try {
          final value = localStorage.read(key);
          if (value != null) {
            await setValue(key, value, encrypt: true);
            successCount++;
          }
        } catch (e) {
          log('Migration failed for key "$key": $e');
          failureCount++;
        }
      }

      log('Migration complete: $successCount succeeded, $failureCount failed');
    } catch (e) {
      log('Migration error: $e');
      throw Exception('Failed to migrate data to encrypted storage: $e');
    }
  }

  /// Toggles encryption on/off globally.
  ///
  /// ⚠️ Use with caution! Disabling encryption affects all future operations.
  ///
  /// Parameters:
  /// - [enabled]: true to enable encryption, false to disable
  ///
  /// Example:
  /// ```dart
  /// toggleEncryption(false); // Disable for debugging
  /// ```
  static void toggleEncryption(bool enabled) {
    _encryptionEnabled = enabled;
    log('Encryption ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Checks if encryption is currently enabled.
  ///
  /// Example:
  /// ```dart
  /// if (isEncryptionEnabled) {
  ///   print('Data is encrypted');
  /// }
  /// ```
  static bool get isEncryptionEnabled => _encryptionEnabled;

  /// Re-encrypts a specific key with a new encryption.
  ///
  /// Useful when updating encryption keys or algorithms.
  ///
  /// Example:
  /// ```dart
  /// await reEncryptKey('user_token');
  /// ```
  static Future<void> reEncryptKey(String key) async {
    try {
      final value = await getValue<String>(key, decrypt: true);
      if (value != null) {
        await setValue(key, value, encrypt: true);
        log('Successfully re-encrypted key: $key');
      }
    } catch (e) {
      log('Re-encryption failed for key "$key": $e');
      throw Exception('Failed to re-encrypt key: $e');
    }
  }

  /// Gets storage statistics.
  ///
  /// Returns information about stored data.
  ///
  /// Example:
  /// ```dart
  /// final stats = getStorageStats();
  /// print('Total keys: ${stats['totalKeys']}');
  /// ```
  static Map<String, dynamic> getStorageStats() {
    try {
      final keys = getAllKeys();
      return {
        'totalKeys': keys.length,
        'encryptionEnabled': _encryptionEnabled,
        'keys': keys,
      };
    } catch (e) {
      log('getStorageStats error: $e');
      return {
        'totalKeys': 0,
        'encryptionEnabled': _encryptionEnabled,
        'keys': [],
        'error': e.toString(),
      };
    }
  }
}

// Legacy compatibility - delegates to LocalStorage
GetStorage get localStorage => LocalStorage.localStorage;

Future<void> setStringToLocal(String key, dynamic value, {bool encrypt = true}) => LocalStorage.setValue(key, value, encrypt: encrypt);

Future<T?> getStringFromLocal<T>(String key, {bool decrypt = true}) => LocalStorage.getValue<T>(key, decrypt: decrypt);

Future<void> setJsonToLocal(String key, Map<String, dynamic> jsonData, {bool encrypt = true}) => LocalStorage.setJsonToLocal(key, jsonData, encrypt: encrypt);

Future<Map<String, dynamic>?> getJsonFromLocal(String key, {bool decrypt = true}) => LocalStorage.getJsonFromLocal(key, decrypt: decrypt);

Future<void> setBoolToLocal(String key, bool value, {bool encrypt = true}) => LocalStorage.setBoolToLocal(key, value, encrypt: encrypt);

Future<bool> getBoolFromLocal(String key, {bool defaultValue = false, bool decrypt = true}) => LocalStorage.getBoolFromLocal(key, defaultValue: defaultValue, decrypt: decrypt);

Future<void> setIntToLocal(String key, int value, {bool encrypt = true}) => LocalStorage.setIntToLocal(key, value, encrypt: encrypt);

Future<int> getIntFromLocal(String key, {int defaultValue = 0, bool decrypt = true}) => LocalStorage.getIntFromLocal(key, defaultValue: defaultValue, decrypt: decrypt);

Future<void> setDoubleToLocal(String key, double value, {bool encrypt = true}) => LocalStorage.setDoubleToLocal(key, value, encrypt: encrypt);

Future<double> getDoubleFromLocal(String key, {double defaultValue = 0.0, bool decrypt = true}) => LocalStorage.getDoubleFromLocal(key, defaultValue: defaultValue, decrypt: decrypt);

Future<void> setStringListToLocal(String key, List<String> value, {bool encrypt = true}) => LocalStorage.setStringListToLocal(key, value, encrypt: encrypt);

Future<List<String>?> getStringListFromLocal(String key, {bool decrypt = true}) => LocalStorage.getStringListFromLocal(key, decrypt: decrypt);

void removeValue(String key) => LocalStorage.removeValue(key);

bool hasKey(String key) => LocalStorage.hasKey(key);

List<String> getAllKeys() => LocalStorage.getAllKeys();

void clearAll() => LocalStorage.clearAll();

Future<void> migrateToEncrypted() => LocalStorage.migrateToEncrypted();

void toggleEncryption(bool enabled) => LocalStorage.toggleEncryption(enabled);

bool get isEncryptionEnabled => LocalStorage.isEncryptionEnabled;