import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

final devicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.getDevices();
  return (response.data as List)
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
});
