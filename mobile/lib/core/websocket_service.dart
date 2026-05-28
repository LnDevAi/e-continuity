import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _wsUrl = 'ws://api.econtinuity.edefence.tech/signaling';
const _storage = FlutterSecureStorage();

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.disconnect());
  return service;
});

enum WsEventType {
  clipboardUpdate,
  deviceCommand,
  deviceStatus,
  offer,
  answer,
  iceCandidate,
}

class WsEvent {
  final WsEventType type;
  final Map<String, dynamic> data;

  WsEvent({required this.type, required this.data});
}

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<WsEvent> _eventController =
      StreamController<WsEvent>.broadcast();

  bool _isConnected = false;
  String? _deviceId;
  String? _userId;

  Stream<WsEvent> get events => _eventController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect({
    required String deviceId,
    required String userId,
  }) async {
    _deviceId = deviceId;
    _userId = userId;

    final token = await _storage.read(key: 'access_token');
    final uri = Uri.parse('$_wsUrl?token=$token');

    _channel = WebSocketChannel.connect(uri);
    _isConnected = true;

    // Enregistrer l'appareil sur le signaling server
    _send({
      'event': 'register-device',
      'data': {'deviceId': deviceId},
    });

    _channel!.stream.listen(
      (message) => _handleMessage(message),
      onDone: () => _handleDisconnect(),
      onError: (error) => _handleError(error),
    );
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> parsed = jsonDecode(message as String);
      final event = parsed['event'] as String?;
      final data = parsed['data'] as Map<String, dynamic>? ?? {};

      WsEventType? type;
      switch (event) {
        case 'clipboard-update':
          type = WsEventType.clipboardUpdate;
          break;
        case 'device-command':
          type = WsEventType.deviceCommand;
          break;
        case 'device-status':
          type = WsEventType.deviceStatus;
          break;
        case 'offer':
          type = WsEventType.offer;
          break;
        case 'answer':
          type = WsEventType.answer;
          break;
        case 'ice-candidate':
          type = WsEventType.iceCandidate;
          break;
      }

      if (type != null) {
        _eventController.add(WsEvent(type: type, data: data));
      }
    } catch (e) {
      print('[WS] Erreur parsing message: $e');
    }
  }

  void sendOffer(String targetDeviceId, Map<String, dynamic> offer) {
    _send({
      'event': 'offer',
      'data': {
        'targetDeviceId': targetDeviceId,
        'offer': offer,
        'fromDeviceId': _deviceId,
      },
    });
  }

  void sendAnswer(String targetDeviceId, Map<String, dynamic> answer) {
    _send({
      'event': 'answer',
      'data': {
        'targetDeviceId': targetDeviceId,
        'answer': answer,
        'fromDeviceId': _deviceId,
      },
    });
  }

  void sendIceCandidate(String targetDeviceId, Map<String, dynamic> candidate) {
    _send({
      'event': 'ice-candidate',
      'data': {
        'targetDeviceId': targetDeviceId,
        'candidate': candidate,
        'fromDeviceId': _deviceId,
      },
    });
  }

  void _send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    // Reconnexion automatique après 5 secondes
    Future.delayed(const Duration(seconds: 5), () {
      if (_deviceId != null && _userId != null) {
        connect(deviceId: _deviceId!, userId: _userId!);
      }
    });
  }

  void _handleError(dynamic error) {
    print('[WS] Erreur: $error');
    _isConnected = false;
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _eventController.close();
  }
}
