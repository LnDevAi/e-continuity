import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

final clipboardHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.getClipboardHistory();
  return (response.data as List)
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});

final latestClipboardProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.getLatestClipboard();
    if (response.data == null) return null;
    return Map<String, dynamic>.from(response.data);
  } catch (_) {
    return null;
  }
});

class ClipboardNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiClient _api;
  final Ref _ref;

  ClipboardNotifier(this._api, this._ref) : super(const AsyncData(null));

  Future<void> push({
    required String content,
    required String contentType,
    String? sourceDevice,
  }) async {
    state = const AsyncLoading();
    try {
      await _api.pushClipboard({
        'content': content,
        'contentType': contentType,
        if (sourceDevice != null) 'sourceDevice': sourceDevice,
      });
      _ref.invalidate(clipboardHistoryProvider);
      _ref.invalidate(latestClipboardProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> delete(String id) async {
    final api = _api;
    await api.deleteClipboardItem(id);
    _ref.invalidate(clipboardHistoryProvider);
    _ref.invalidate(latestClipboardProvider);
  }
}

final clipboardProvider =
    StateNotifierProvider<ClipboardNotifier, AsyncValue<void>>((ref) {
  final api = ref.watch(apiClientProvider);
  return ClipboardNotifier(api, ref);
});
