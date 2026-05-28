import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../devices/devices_provider.dart';

class KillSwitchNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiClient _api;
  final Ref _ref;

  KillSwitchNotifier(this._api, this._ref) : super(const AsyncData(null));

  Future<bool> lock(String deviceId) async {
    state = const AsyncLoading();
    try {
      await _api.lockDevice(deviceId);
      _ref.invalidate(devicesProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> wipe(String deviceId) async {
    state = const AsyncLoading();
    try {
      await _api.wipeDevice(deviceId);
      _ref.invalidate(devicesProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final killSwitchProvider =
    StateNotifierProvider<KillSwitchNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiClientProvider);
  return KillSwitchNotifier(api, ref);
});
