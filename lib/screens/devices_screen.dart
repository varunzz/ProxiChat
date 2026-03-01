import 'package:flutter/material.dart';
import '../services/nearby_service.dart';
import 'chat_screen.dart';

class DevicesScreen extends StatefulWidget {
  final String username;

  const DevicesScreen({super.key, required this.username});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final NearbyService _nearbyService = NearbyService();

  // Real discovered devices — id -> name
  final Map<String, String> _discoveredDevices = {};
  final Map<String, String> _connectedDevices = {};
  bool _isScanning = false;
  String _status = 'Tap scan to find nearby devices';

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    _startNearby();
  }

  // Set up what happens when nearby events occur
  void _setupCallbacks() {
    // When a new device is found nearby
    _nearbyService.onDeviceFound = (id, name) {
      setState(() {
        _discoveredDevices[id] = name;
        _status = '${_discoveredDevices.length} device(s) found nearby';
      });
    };

    // When a device goes out of range
    _nearbyService.onDeviceLost = (id) {
      setState(() {
        _discoveredDevices.remove(id);
        _status = '${_discoveredDevices.length} device(s) found nearby';
      });
    };

    // When successfully connected to a device
    _nearbyService.onConnected = (id) {
      setState(() {
        String name = _discoveredDevices[id] ?? 'Unknown';
        _connectedDevices[id] = name;
        _status = 'Connected to $name!';
      });
    };

    // When a device disconnects
    _nearbyService.onDisconnected = (id) {
      setState(() {
        _connectedDevices.remove(id);
      });
    };
  }

  Future<void> _startNearby() async {
    setState(() {
      _isScanning = true;
      _status = 'Requesting permissions...';
    });

    // Request permissions first
    bool granted = await _nearbyService.requestPermissions();

    if (!granted) {
      setState(() {
        _isScanning = false;
        _status = 'Permissions denied. Please allow in settings.';
      });
      return;
    }

    _nearbyService.setUsername(widget.username);

    // Start both advertising and discovery simultaneously
    await _nearbyService.startAdvertising();
    await _nearbyService.startDiscovery();

    setState(() {
      _isScanning = false;
      _status = 'Scanning for nearby devices...';
    });
  }

  Future<void> _connectToDevice(String id, String name) async {
    setState(() {
      _status = 'Connecting to $name...';
    });
    await _nearbyService.connectToDevice(id);
  }

  @override
  void dispose() {
    // Stop everything when leaving this screen
    _nearbyService.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          'Hi, ${widget.username}!',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF7C4DFF)),
            onPressed: () {
              _nearbyService.stopAll();
              _discoveredDevices.clear();
              _startNearby();
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF16213E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isScanning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Device list
          Expanded(
            child: _discoveredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_tethering,
                          size: 60,
                          color: Colors.white12,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No devices found nearby',
                          style: TextStyle(color: Colors.white38, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Make sure others have ProxiChat open',
                          style: TextStyle(color: Colors.white24, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            _nearbyService.stopAll();
                            _discoveredDevices.clear();
                            _startNearby();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text(
                            'Scan Again',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C4DFF),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _discoveredDevices.length,
                    itemBuilder: (context, index) {
                      String id = _discoveredDevices.keys.elementAt(index);
                      String name = _discoveredDevices[id]!;
                      bool isConnected = _connectedDevices.containsKey(id);
                      return _buildDeviceCard(id, name, isConnected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(String id, String name, bool isConnected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? Colors.greenAccent.withValues(alpha: 0.4)
              : Color(0xFF7C4DFF).withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isConnected
              ? Colors.greenAccent
              : const Color(0xFF7C4DFF),
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isConnected ? 'Connected' : 'Nearby • Tap to connect',
          style: TextStyle(
            color: isConnected ? Colors.greenAccent : Colors.white38,
            fontSize: 12,
          ),
        ),
        trailing: isConnected
            ? ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        currentUser: widget.username,
                        peerName: name,
                        peerId: id,
                        nearbyService: _nearbyService,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Chat',
                  style: TextStyle(color: Colors.black),
                ),
              )
            : ElevatedButton(
                onPressed: () => _connectToDevice(id, name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }
}