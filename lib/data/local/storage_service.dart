import 'package:get_storage/get_storage.dart';

class StorageService {
  final _box = GetStorage();

  // Read
  T? read<T>({required String key}) {
    return _box.read(key);
  }

  // Write
  Future<void> write({required String key, required dynamic value}) async {
    await _box.write(key, value);
  }

  // Remove
  Future<void> remove({required String key}) async {
    await _box.remove(key);
  }

  // Clear all
  Future<void> clear() async {
    await _box.erase();
  }

  // Get driver ID
  int? getDriverId() {
    return _box.read('id');
  }
}
