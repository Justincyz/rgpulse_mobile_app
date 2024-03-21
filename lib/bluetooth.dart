import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:first_flutter_project/constants.dart';
import 'package:flutter/cupertino.dart';
import 'const';

class BluetoothHelper {
  static final BluetoothHelper instance = BluetoothHelper._internal();

  BluetoothHelper._internal();
  factory BluetoothHelper() {
    return instance;
  }


  Future<void> startBlueToothScan() async {
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 20),
      //continuousUpdates: true
      );
  }


  Future<void> connect(BluetoothDevice device) async {
    await device.connect(timeout: const Duration(seconds: 20));
  }

  Future<void> disconnect(BluetoothDevice device) async {
    await device.disconnect();
  }

  List<BluetoothDevice> getConnectedDevices() {
    return FlutterBluePlus.connectedDevices;
  }

  //停止扫描接口
  Future<void> stopBleScan() async {
    await FlutterBluePlus.stopScan();
  }  
}

//----------------
class BluetoothToggleButton extends StatefulWidget {
  final BluetoothDevice device;
  final BuildContext context;
  const BluetoothToggleButton({
    Key? key, 
    required this.device, 
    required this.context}) : super(key: key);

  @override
  BluetoothToggleButtonState createState() => BluetoothToggleButtonState();
}

class BluetoothToggleButtonState extends State<BluetoothToggleButton> {
  bool displayConnectingAnime = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothConnectionState>(
      stream: widget.device.connectionState,
      initialData: BluetoothConnectionState.disconnected,
      builder: (context, snapshot) {
        var deviceState = snapshot.data;
        bool isConnect = deviceState == BluetoothConnectionState.connected;

        return displayConnectingAnime ?
        const CircularProgressIndicator.adaptive(strokeCap: StrokeCap.round)
        : CupertinoSwitch(
                value: isConnect,
                onChanged: (bool toggleValue) {
                  _onSwitchChanged(toggleValue, isConnect);
                });
      },
    );
  }

  Future<void> _onSwitchChanged(toggleValue, bool isConnect) {
    setState(() {
      displayConnectingAnime = true;
    });
    //connect -> disconnect and vice versa
    return isConnect ? _disconnectToDevice() : _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    try {
      await BluetoothHelper().connect(widget.device);
    } catch (e) {
      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoCustomDialog(BT_CONNECTION_UNSUCCESS_TITLE, BT_CONNECTION_UNSUCCESS_MESSAGE); // 显示自定义对话框
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          displayConnectingAnime = false;
        });
      }
    }
  }

  Future<void> _disconnectToDevice() async {
    try {
      await BluetoothHelper().disconnect(widget.device);
    } catch (e) {
      if (!mounted) return;

      print('Disconnection Error: $e');
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoCustomDialog(
              BT_DISCONNECTION_UNSUCCESS_TITLE, BT_DISCONNECTION_UNSUCCESS_MESSAGE); // 显示自定义对话框
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          displayConnectingAnime = false;
        });
      }
    }
  }
}

//----------------------------

class CupertinoCustomDialog extends StatelessWidget {
  String title;
  String message;

  CupertinoCustomDialog(this.title, this.message);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        CupertinoDialogAction(
          child: const Text(OK),
          onPressed: () {
            Navigator.of(context).pop(); // 关闭对话框
          },
        ),
      ],
    );
  }
}
