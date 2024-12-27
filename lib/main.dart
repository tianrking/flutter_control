import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_manager.dart';

void main() {
 runApp(const MyApp());
}

class MyApp extends StatelessWidget {
 const MyApp({super.key});

 @override
 Widget build(BuildContext context) {
   return MaterialApp(
     title: 'Remote Control App',
     theme: ThemeData(primarySwatch: Colors.blue),
     home: const RemoteControlScreen(),
   );
 }
}

class RemoteControlScreen extends StatefulWidget {
 const RemoteControlScreen({super.key});

 @override
 _RemoteControlScreenState createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen> {
 final BluetoothManager _bluetoothManager = BluetoothManager();
 BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;
 List<BluetoothDevice> _devices = [];
 Offset _joystickPosition = Offset.zero;
 final double _joystickRadius = 80.0;
 final double _smallCircleRadius = 20.0;
 double _xValue = 0.0;
 double _yValue = 0.0;
 BluetoothDevice? _selectedDevice;

 @override
 void initState() {
   super.initState();
   
   FlutterBluePlus.adapterState.listen((state) {
     setState(() => _bluetoothState = state);
   });

   _bluetoothManager.devices.listen((devices) {
     print('Found ${devices.length} devices');
     setState(() {
       _devices = devices;
       devices.forEach((device) {
         print('Device: ${device.platformName} (${device.remoteId})');
       });
     });
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
             height: 250, // 增加高度
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(
                       'Found Devices (${_devices.length})', 
                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
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