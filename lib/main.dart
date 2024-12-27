import 'package:flutter/material.dart';

void main() {
  runApp(const RobotControllerApp());
}

class RobotControllerApp extends StatelessWidget {
  const RobotControllerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '机器人控制器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const ControllerPage(),
    );
  }
}

class ControllerPage extends StatefulWidget {
  const ControllerPage({Key? key}) : super(key: key);

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  String _lastCommand = '无';
  bool _isConnected = false;
  double _speed = 50;
  
  void _sendCommand(String command) {
    setState(() {
      _lastCommand = command;
    });
    // TODO: 实现实际的命令发送逻辑
    print('发送命令: $command, 速度: $_speed%');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('机器人控制台'),
        actions: [
          Switch(
            value: _isConnected,
            onChanged: (value) {
              setState(() {
                _isConnected = value;
              });
            },
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Column(
        children: [
          // 状态面板
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('连接状态: ${_isConnected ? "已连接" : "未连接"}',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('最后命令: $_lastCommand',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                Icon(
                  _isConnected ? Icons.link : Icons.link_off,
                  size: 32,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),

          // 速度控制滑块
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.speed),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: _speed,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '${_speed.round()}%',
                    onChanged: (value) {
                      setState(() {
                        _speed = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text('${_speed.round()}%'),
              ],
            ),
          ),

          const Spacer(),
          
          // 方向控制按钮
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDirectionButton(Icons.arrow_upward, '前进', Colors.blue),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDirectionButton(Icons.arrow_back, '左转', Colors.orange),
                    const SizedBox(width: 80),
                    _buildDirectionButton(Icons.arrow_forward, '右转', Colors.orange),
                  ],
                ),
                const SizedBox(height: 10),
                _buildDirectionButton(Icons.arrow_downward, '后退', Colors.blue),
              ],
            ),
          ),

          // 停止按钮
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _isConnected ? () => _sendCommand('停止') : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop_circle),
                  SizedBox(width: 8),
                  Text('紧急停止', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(IconData icon, String command, Color color) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTapDown: (_) => _isConnected ? _sendCommand(command) : null,
        onTapUp: (_) => _isConnected ? _sendCommand('停止') : null,
        onTapCancel: () => _isConnected ? _sendCommand('停止') : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}