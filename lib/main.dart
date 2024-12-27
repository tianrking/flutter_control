import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'bluetooth_manager.dart';
import 'location_service.dart';
import 'sensors_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remote Control App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RootScreen(), // 使用 RootScreen 作为主页面
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  _RootScreenState createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0; // 当前选中的页面索引

  final List<Widget> _pages = [
    const MainPage(), // 主页面
    const TestPage(), // 测试页面
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // 根据索引显示页面
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'MAIN'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'TEST'),
        ],
      ),
    );
  }
}


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final BluetoothManager _bluetoothManager = BluetoothManager();
  final LocationService _locationService = LocationService();
  final SensorsService _sensorsService = SensorsService();

  BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  Position? _currentPosition;
  GyroscopeEvent? _gyroData;
  AccelerometerEvent? _accelData;

  Offset _joystickPosition = Offset.zero;
  final double _joystickRadius = 80.0;
  final double _smallCircleRadius = 20.0;
  double _xValue = 0.0;
  double _yValue = 0.0;

  bool _isGyroAvailable = false;
  bool _isAccelAvailable = false;


  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    FlutterBluePlus.adapterState.listen((state) {
      setState(() => _bluetoothState = state);
    });

    _bluetoothManager.devices.listen((devices) {
      setState(() {
        _devices = devices;
      });
    });

    if (await _locationService.checkPermission()) {
      _locationService.getLocationStream().listen((position) {
        setState(() => _currentPosition = position);
      });
    }


    // 检查陀螺仪是否可用
    gyroscopeEvents.listen((event) {
      setState(() {
          _isGyroAvailable = true;
          _gyroData = event;
      });
    }, onError: (e) {
      setState(() => _isGyroAvailable = false);
      print('Gyroscope error: $e');
    });

    // 检查加速度计是否可用
    accelerometerEvents.listen((event) {
      setState(() {
         _isAccelAvailable = true;
         _accelData = event;
      });
    }, onError: (e){
      setState(() => _isAccelAvailable = false);
      print('Accelerometer error: $e');
    });

  }

  Future<void> _checkAndRequestBluetooth() async {
    if (_bluetoothState != BluetoothAdapterState.on) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('蓝牙未开启'),
          content: Text('请在系统设置中开启蓝牙'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('确定'),
            ),
          ],
        ),
      );
      return;
    }

    if (_bluetoothManager.isScanning) {
      await _bluetoothManager.stopScan();
    } else {
      await _bluetoothManager.startScan();
    }
    setState(() {});
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() => _selectedDevice = device);
      await _bluetoothManager.connect(device);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.platformName}')),
      );
    } catch (e) {
      print('Connection error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    }
  }

  void _handleJoystickPan(DragUpdateDetails details) {
    setState(() {
      Offset newPosition = _joystickPosition + Offset(details.delta.dx, -details.delta.dy);
      if (newPosition.distance > _joystickRadius - _smallCircleRadius) {
        newPosition = Offset.fromDirection(
            newPosition.direction, _joystickRadius - _smallCircleRadius);
      }
      _joystickPosition = newPosition;
    });
    _sendMoveCommand(_joystickPosition);
  }

  void _handleJoystickDragEnd(DragEndDetails details) {
    setState(() {
      _joystickPosition = Offset.zero;
      _xValue = 0.0;
      _yValue = 0.0;
    });
    _sendStopCommand();
  }

  void _sendMoveCommand(Offset direction) {
    _xValue = direction.dx;
    _yValue = direction.dy;
    setState(() {});
  }

  void _sendStopCommand() {
    print('Stop Command');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Control'),
        actions: [
          IconButton(
            icon: Icon(_bluetoothManager.isScanning
                ? Icons.bluetooth_searching
                : Icons.bluetooth),
            onPressed: _checkAndRequestBluetooth,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_devices.isNotEmpty || _bluetoothManager.isScanning)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Found Devices (${_devices.length})',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (_selectedDevice != null)
                        Text(
                          'Connected: ${_selectedDevice!.platformName}',
                          style: TextStyle(color: Colors.green),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final isSelected = device == _selectedDevice;
                        return ListTile(
                          title: Text(device.platformName.isEmpty
                              ? 'Unknown Device'
                              : device.platformName),
                          subtitle: Text(device.remoteId.toString()),
                          trailing: isSelected ? Icon(Icons.check, color: Colors.green) : null,
                          selected: isSelected,
                          onTap: () => _connectToDevice(device),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey[100],
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GPS Data
                Text(
                    'GPS: ${_currentPosition != null ?
                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                        'Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}, '
                        'Alt: ${_currentPosition!.altitude.toStringAsFixed(1)}m, '
                        'Speed: ${_currentPosition!.speed.toStringAsFixed(1)}m/s, '
                        'Heading: ${_currentPosition!.heading.toStringAsFixed(1)}°'
                        : 'No GPS data'}'
                ),
                const SizedBox(height: 4),
                // IMU Data
                Text(
                    'Gyroscope: ${_isGyroAvailable ? 
                     (_gyroData != null ?
                    'X: ${_gyroData!.x.toStringAsFixed(3)}, '
                        'Y: ${_gyroData!.y.toStringAsFixed(3)}, '
                        'Z: ${_gyroData!.z.toStringAsFixed(3)} rad/s'
                    : 'Waiting data...')
                     : 'Gyroscope not available' }'
                ),
                const SizedBox(height: 4),
                Text(
                    'Accelerometer: ${_isAccelAvailable ?
                     (_accelData != null ?
                    'X: ${_accelData!.x.toStringAsFixed(3)}, '
                        'Y: ${_accelData!.y.toStringAsFixed(3)}, '
                        'Z: ${_accelData!.z.toStringAsFixed(3)} g'
                    : 'Waiting data...')
                     : 'Accelerometer not available'}'
                ),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                Positioned(
                  bottom: 50,
                  left: 50,
                  child: Container(
                    width: _joystickRadius * 2,
                    height: _joystickRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 50 + _joystickRadius - _smallCircleRadius + _joystickPosition.dy,
                  left: 50 + _joystickRadius - _smallCircleRadius + _joystickPosition.dx,
                  child: GestureDetector(
                    onPanUpdate: _handleJoystickPan,
                    onPanEnd: _handleJoystickDragEnd,
                    child: Container(
                      width: _smallCircleRadius * 2,
                      height: _smallCircleRadius * 2,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 50 + _joystickRadius * 2 + 10,
                  left: 50,
                  child: Text(
                    'X: ${_xValue.toStringAsFixed(2)}, Y: ${_yValue.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),

                Positioned(
                  bottom: 50,
                  right: 50,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => print('Button A pressed'),
                        child: const Text('Button A'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => print('Button B pressed'),
                        child: const Text('Button B'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => print('Button C pressed'),
                        child: const Text('Button C'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Page'),
      ),
      body: const Center(
        child: Text(
          'This is the Test Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}