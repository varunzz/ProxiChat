import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

class NearbyService {
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;
  NearbyService._internal();

  final Strategy strategy = Strategy.P2P_CLUSTER;
  String _username = '';

  // Guards to prevent starting twice
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  Function(String id, String name)? onDeviceFound;
  Function(String id)? onDeviceLost;
  Function(String id, String name)? onConnectionRequest;
  Function(String message, String senderName)? onMessageReceived;
  Function(String id)? onConnected;
  Function(String id)? onDisconnected;

  final Map<String, String> connectedDevices = {};

  void setUsername(String username) {
    _username = username;
  }

  // ─── PERMISSIONS ────────────────────────────────────────────────
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    bool allGranted = statuses.values.every(
      (status) => status == PermissionStatus.granted,
    );

    return allGranted;
  }

  // ─── ADVERTISING ────────────────────────────────────────────────
  Future<void> startAdvertising() async {
    if (_isAdvertising) return; // already running, skip
    try {
      _isAdvertising = true;
      await Nearby().startAdvertising(
        _username,
        strategy,
        onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              _handlePayload(endpointId, payload);
            },
          );
          connectedDevices[id] = info.endpointName;
          onConnected?.call(id);
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            onConnected?.call(id);
          }
        },
        onDisconnected: (id) {
          connectedDevices.remove(id);
          onDisconnected?.call(id);
        },
      );
    } catch (e) {
      _isAdvertising = false; // reset if failed
      print('Advertising error: $e');
    }
  }

  // ─── DISCOVERY ──────────────────────────────────────────────────
  Future<void> startDiscovery() async {
    if (_isDiscovering) return; // already running, skip
    try {
      _isDiscovering = true;
      await Nearby().startDiscovery(
        _username,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          onDeviceFound?.call(id, name);
        },
        onEndpointLost: (id) {
          if (id != null) onDeviceLost?.call(id);
        },
      );
    } catch (e) {
      _isDiscovering = false; // reset if failed
      print('Discovery error: $e');
    }
  }

  // ─── CONNECT ────────────────────────────────────────────────────
  Future<void> connectToDevice(String endpointId) async {
    try {
      await Nearby().requestConnection(
        _username,
        endpointId,
        onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              _handlePayload(endpointId, payload);
            },
          );
          connectedDevices[id] = info.endpointName;
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            onConnected?.call(id);
          }
        },
        onDisconnected: (id) {
          connectedDevices.remove(id);
          onDisconnected?.call(id);
        },
      );
    } catch (e) {
      print('Connection error: $e');
    }
  }

  // ─── SEND MESSAGE ────────────────────────────────────────────────
  Future<void> sendMessage(String endpointId, String message) async {
    try {
      await Nearby().sendBytesPayload(
        endpointId,
        _toBytes(message),
      );
    } catch (e) {
      print('Send error: $e');
    }
  }

  Future<void> broadcastMessage(String message) async {
    for (String endpointId in connectedDevices.keys) {
      await sendMessage(endpointId, message);
    }
  }

  // ─── HANDLE INCOMING PAYLOAD ─────────────────────────────────────
  void _handlePayload(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      String message = String.fromCharCodes(payload.bytes!);
      String senderName = connectedDevices[endpointId] ?? 'Unknown';
      onMessageReceived?.call(message, senderName);
    }
  }

  // ─── STOP EVERYTHING ─────────────────────────────────────────────
  Future<void> stopAll() async {
    _isAdvertising = false; // reset guards
    _isDiscovering = false;
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
    connectedDevices.clear();
  }

  // converts String to Uint8List (bytes)
  Uint8List _toBytes(String str) {
    return Uint8List.fromList(str.codeUnits);
  }
}