// sensors_service.dart
import 'package:sensors_plus/sensors_plus.dart';

class SensorsService {
  Stream<GyroscopeEvent> getGyroscope() {
    return gyroscopeEvents;
  }

  Stream<AccelerometerEvent> getAccelerometer() {
    return accelerometerEvents;
  }
}