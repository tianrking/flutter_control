# Flutter 遥控上位机

## 简介

本项目是一个使用 Flutter 开发的遥控上位机应用，主要功能是通过一个 360 度自由拖动的透明摇杆和几个功能按钮来控制机器人。该应用支持 Windows 和 Android 平台，使用户能够更加直观和灵活地操作机器人。

## 开发环境

*   Flutter SDK (版本要求：推荐最新稳定版本)
*   Visual Studio 或 Android Studio (用于编译和运行应用)
*   Android 设备 (用于测试 Android 版本)

## 开发过程及命令

### 1. 创建 Flutter 项目

使用以下命令创建一个 Flutter 项目:

   ```bash
   flutter create remote_control_app
   cd remote_control_app
   ```

### 2. 添加 Windows 和 Android 平台支持

在项目根目录运行以下命令添加 Windows 和 Android 支持:

  ```bash
    flutter create . --platforms windows,android
    flutter config --enable-windows-desktop
   ```

   **说明:**
   *  `flutter config --enable-windows-desktop` 是启用 windows 桌面支持。
   * 如果你只需要android平台支持，则可以使用`flutter create . --platforms android`

### 3. 运行 Windows 应用

   ```bash
      flutter run -d windows
   ```

### 4. 运行 Android 应用
    连接 Android 设备后, 使用以下命令运行:
    ```bash
       flutter run -d android
   ```

### 5. 构建 Android APK (可选)
  ```bash
       flutter build apk
    ```

### 6. 代码修改过程

我们主要修改了 `lib/main.dart` 文件。

  *  **初始代码:**  我们创建了基本的 UI 界面, 包括一个透明摇杆和几个功能按钮。
  *  **解决PDB编译错误:** 我们修改了 `windows/CMakeLists.txt` 文件, 加入 `/FS` 编译选项，从而解决多线程编译写入 PDB 文件冲突的问题。
  *  **解决错误：`A value of type 'double' can't be assigned to a variable of type 'Offset'.` 和 `The getter 'newPosition' isn't defined`:**  我们修改了代码中计算摇杆位置和方向的方式, 使用 `Offset.fromDirection` 方法创建合适的偏移量, 将局部变量改为实例变量。
  *  **实现360度自由拖拽:** 我们将 `GestureDetector` 组件的监听事件从 `onHorizontalDragUpdate` 和 `onVerticalDragUpdate` 更改为 `onPanUpdate`。
  *  **修复摇杆上下方向问题：** 我们将计算摇杆位置的时候就对 `details.delta.dy` 进行了取反，解决了上下方向的问题。

## 设计思路

*   **UI 布局:**
    *   使用 `Stack` 组件实现元素的层叠定位，方便实现摇杆和按钮的布局。
    *   透明摇杆放置在屏幕左下方，便于拇指操作。
    *   功能按钮放置在屏幕右侧，便于右手操作。
*   **摇杆交互:**
    *   使用 `GestureDetector` 组件监听用户的拖拽手势。
    *   使用 `onPanUpdate` 事件监听手势变化，实时更新摇杆小圆点的位置。
    *   限制小圆点在摇杆背景圆内移动。
*   **控制逻辑:**
    *   在 `_sendMoveCommand` 函数中，计算摇杆的水平和垂直方向分量。
    *   在实际使用时，需要将这些分量转换为机器人的控制指令。
    *   功能按钮的点击事件被用来发送预设的控制指令。

## 代码原理

### 核心代码片段（`lib/main.dart`）

*   **定义状态变量：**
```dart
   Offset _joystickPosition = Offset.zero; // 摇杆小圆点的位置
   final double _joystickRadius = 80.0; // 摇杆背景的半径
   final double _smallCircleRadius = 20.0; // 摇杆小圆点的半径
```
*   **处理拖拽事件：**
```dart
 void _handleJoystickPan(DragUpdateDetails details) {
      setState(() {
          // 计算摇杆小圆点的新位置, 注意, 这里的y是反向的.
          Offset newPosition = _joystickPosition + Offset(details.delta.dx,-details.delta.dy);

          // 限制小圆点在摇杆背景内
          if (newPosition.distance > _joystickRadius - _smallCircleRadius) {
            double distance = _joystickRadius - _smallCircleRadius;
            newPosition = Offset.fromDirection(newPosition.direction,distance);
          }

        _joystickPosition = newPosition;
      });

      // 计算方向向量，发送给机器人
      _sendMoveCommand(_joystickPosition);

  }
```

*  **获取偏移量和方向分量：**
```dart
   void _sendMoveCommand(Offset direction) {
        // 计算方向向量
        double x = direction.dx;
        double y = direction.dy;

        // 输出水平和垂直分量
        print('Move Command: horizontal = $x , vertical = $y');
    }
```

*   **摇杆 UI：**

```dart
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
```

*  **说明:**
  *  通过`Offset` 来记录摇杆的位置, `_joystickPosition` 是一个实例变量, 保证了整个页面都能访问到.
  *  在 `_handleJoystickPan`  方法中, 我们通过`details.delta` 来获取触摸点距离上一次的偏移量, 并通过 `Offset(details.delta.dx,-details.delta.dy)` 来计算新的摇杆位置, 这里 y 是反向的, 我们直接进行了取反.
  * 在 `_sendMoveCommand` 中, `direction.dx` 表示水平方向分量, `direction.dy` 表示垂直方向分量. 我们可以直接使用这两个值来发送控制指令.
  * `GestureDetector` 组件用来监听手势事件, `onPanUpdate` 监听拖拽移动, `onPanEnd`监听拖拽结束.

## 如何使用

1.  确保你的 Flutter 环境配置正确。
2.  连接你的 Android 设备或运行 Windows 应用。
3.  在应用中拖动摇杆控制机器人，点击按钮发送功能指令。

## 未来扩展

*   **加入网络通信模块:**  实现和机器人之间的网络连接，发送控制指令和接收机器人状态信息.
*   **完善UI:**  加入更多的UI元素, 以及更好的动画效果.
*   **加入配置功能:**  允许用户自定义摇杆灵敏度, 按钮的功能等.
*    **支持更多的平台：** 可以考虑扩展到 iOS、Web 等平台。



