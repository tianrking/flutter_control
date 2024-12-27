import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remote Control App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  Offset _joystickPosition = Offset.zero; // 摇杆小圆点的位置
  final double _joystickRadius = 80.0; // 摇杆背景的半径
  final double _smallCircleRadius = 20.0; // 摇杆小圆点的半径
  double _xValue = 0.0; // X 轴分量
  double _yValue = 0.0; // Y 轴分量

  // 处理摇杆触摸事件
  void _handleJoystickPan(DragUpdateDetails details) {
    setState(() {
      // 计算摇杆小圆点的新位置
      Offset newPosition =
          _joystickPosition + Offset(details.delta.dx, -details.delta.dy);

      // 限制小圆点在摇杆背景内
      if (newPosition.distance > _joystickRadius - _smallCircleRadius) {
        double distance = _joystickRadius - _smallCircleRadius;
        newPosition = Offset.fromDirection(newPosition.direction, distance);
      }

      _joystickPosition = newPosition;
    });

    // 计算方向向量，发送给机器人
    _sendMoveCommand(_joystickPosition);
  }

  void _handleJoystickDragEnd(DragEndDetails details) {
    setState(() {
      _joystickPosition = Offset.zero; // 回到中心
      _xValue = 0.0; // 重置 X 轴分量
      _yValue = 0.0; // 重置 Y 轴分量
    });
    _sendStopCommand();
  }

  // 模拟发送移动命令
  void _sendMoveCommand(Offset direction) {
    // 计算方向向量
    _xValue = direction.dx;
    _yValue = direction.dy;


      setState(() {
       //  更新 state,  触发重新绘制, 更新 UI
      });


  }

  void _sendStopCommand() {
    print('Stop Command');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remote Control')),
      body: Stack(
        children: [
          // 摇杆背景
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

          // 可拖动的摇杆小圆点
          Positioned(
            bottom:
                50 + _joystickRadius - _smallCircleRadius + _joystickPosition.dy,
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
         // 显示当前控制映射的数值
            Positioned(
              bottom: 50 + _joystickRadius * 2 + 10, // 在摇杆下方显示
                left: 50,
              child: Text(
                'X: ${_xValue.toStringAsFixed(2)}, Y: ${_yValue.toStringAsFixed(2)}', // 保留两位小数
                style: const TextStyle(fontSize: 16, color: Colors.black),
              )
          ),


          // 功能按钮
          Positioned(
            bottom: 50,
            right: 50,
            child: Column(
              children: [
                ElevatedButton(
                    onPressed: () {
                      _sendCommand('Button A');
                    },
                    child: const Text('Button A')),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () {
                      _sendCommand('Button B');
                    },
                    child: const Text('Button B')),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () {
                      _sendCommand('Button C');
                    },
                    child: const Text('Button C')),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _sendCommand(String command) {
    print('Send Command: $command');
  }
}