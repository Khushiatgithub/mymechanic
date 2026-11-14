import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract contract for low-level secure key-value platform storage.
///
/// Phase 3 Step 4.2: Secure Token Storage.
///
/// Enables seamless injection of mock or in-memory implementations in unit tests
/// without requiring an active Android Keystore or iOS Keychain.
abstract interface class SecureStorageDriver {
  /// Reads a secure value by key. Returns null if key does not exist.
  Future<String?> read({required String key});

  /// Writes a secure key-value pair.
  Future<void> write({required String key, required String value});

  /// Deletes a key from secure storage.
  Future<void> delete({required String key});

  /// Deletes all entries from secure storage.
  Future<void> deleteAll();
}

/// Production implementation backed by [FlutterSecureStorage].
class FlutterSecureStorageDriver implements SecureStorageDriver {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageDriver([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
