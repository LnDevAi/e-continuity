import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

final syncConfigProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.getSyncConfig();
    if (response.data == null) return null;
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return null;
  }
});

class SyncNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiClient _api;
  final Ref _ref;

  SyncNotifier(this._api, this._ref) : super(const AsyncData(null));

  Future<void> updatePaths(List<String> paths) async {
    state = const AsyncLoading();
    try {
      await _api.updateSyncConfig({'syncedPaths': paths, 'backupEnabled': true});
      _ref.invalidate(syncConfigProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> triggerSync() async {
    state = const AsyncLoading();
    try {
      await _api.triggerSync();
      _ref.invalidate(syncConfigProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiClientProvider);
  return SyncNotifier(api, ref);
});
