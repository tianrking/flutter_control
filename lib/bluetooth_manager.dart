// bluetooth_manager.dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
 Stream<List<BluetoothDevice>> get devices {
   return FlutterBluePlus.scanResults.map((results) {
     return results.map((r) => r.device).toList();
   });
 }

 bool _isScanning = false;
 bool get isScanning => _isScanning;

 Future<void> startScan() async {
   try {
     _isScanning = true;
     await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
     await Future.delayed(const Duration(seconds: 4));
     _isScanning = false;
   } catch (e) {
     _isScanning = false;
     print('Scan error: $e');
   }
 }

 Future<void> stopScan() async {
   await FlutterBluePlus.stopScan();
   _isScanning = false;
 }

 Future<void> connect(BluetoothDevice device) async {
   try {
     await device.connect();
   } catch (e) {
     print('Error connecting to device: $e');
   }
 }
}