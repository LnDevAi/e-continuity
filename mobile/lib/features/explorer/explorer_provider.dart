import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileEntry {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime? modifiedAt;

  const FileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    this.modifiedAt,
  });

  factory FileEntry.fromJson(Map<String, dynamic> json) {
    return FileEntry(
      name: json['name'] as String,
      path: json['path'] as String,
      isDirectory: json['isDirectory'] as bool,
      size: (json['size'] as num).toInt(),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.tryParse(json['modifiedAt'] as String)
          : null,
    );
  }
}

// État de navigation P2P
class ExplorerState {
  final String currentPath;
  final List<FileEntry> entries;
  final bool isLoading;
  final bool isConnected;
  final String? targetDeviceId;
  final String? error;
  final List<String> pathHistory;

  const ExplorerState({
    this.currentPath = '/',
    this.entries = const [],
    this.isLoading = false,
    this.isConnected = false,
    this.targetDeviceId,
    this.error,
    this.pathHistory = const [],
  });

  ExplorerState copyWith({
    String? currentPath,
    List<FileEntry>? entries,
    bool? isLoading,
    bool? isConnected,
    String? targetDeviceId,
    String? error,
    List<String>? pathHistory,
  }) {
    return ExplorerState(
      currentPath: currentPath ?? this.currentPath,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      error: error,
      pathHistory: pathHistory ?? this.pathHistory,
    );
  }
}

class ExplorerNotifier extends StateNotifier<ExplorerState> {
  ExplorerNotifier() : super(const ExplorerState());

  // Dans la production, on utilise WebRTC DataChannel pour transmettre
  // les requêtes listDirectory() à l'appareil PC distant
  Future<void> connectToDevice(String deviceId) async {
    state = state.copyWith(
      isLoading: true,
      targetDeviceId: deviceId,
      error: null,
    );

    // Simulation d'une connexion WebRTC P2P
    await Future.delayed(const Duration(seconds: 1));

    // Données simulées — en production, provient du MethodChannel C# via WebRTC
    final simulatedEntries = [
      FileEntry(
        name: 'Documents',
        path: '/Documents',
        isDirectory: true,
        size: 0,
        modifiedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      FileEntry(
        name: 'Desktop',
        path: '/Desktop',
        isDirectory: true,
        size: 0,
        modifiedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      FileEntry(
        name: 'Pictures',
        path: '/Pictures',
        isDirectory: true,
        size: 0,
        modifiedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      FileEntry(
        name: 'rapport-2026.pdf',
        path: '/Desktop/rapport-2026.pdf',
        isDirectory: false,
        size: 2457600,
        modifiedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      FileEntry(
        name: 'config.json',
        path: '/Desktop/config.json',
        isDirectory: false,
        size: 1024,
        modifiedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    state = state.copyWith(
      isLoading: false,
      isConnected: true,
      currentPath: '/',
      entries: simulatedEntries,
    );
  }

  Future<void> navigateTo(String path) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));

    final newHistory = [...state.pathHistory, state.currentPath];
    // Dans la production, envoie une requête WebRTC DataChannel à l'appareil PC
    state = state.copyWith(
      currentPath: path,
      pathHistory: newHistory,
      isLoading: false,
    );
  }

  void navigateBack() {
    if (state.pathHistory.isEmpty) return;
    final history = List<String>.from(state.pathHistory);
    final previous = history.removeLast();
    state = state.copyWith(
      currentPath: previous,
      pathHistory: history,
    );
  }

  void disconnect() {
    state = const ExplorerState();
  }
}

final explorerProvider =
    StateNotifierProvider<ExplorerNotifier, ExplorerState>((ref) {
  return ExplorerNotifier();
});
