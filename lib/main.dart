

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'permission/AppPermission.dart';
import 'dart:core';
import 'bluetooth.dart';
import 'dart:async';
import 'package:flutter_spinkit/flutter_spinkit.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: _generateRoute,
      home: const HomeScreen(),
    );
  }

  // 路由生成器，用于根据路由名称生成对应的路由对象
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => const HomeScreen()); //settings的作用是debug, 追溯目前navigator stack中访问过的页面

      case '/bluetooth':
        
        return MaterialPageRoute(settings: settings, builder: (context) => BluetoothPage());
      case '/locationPermission':
        return MaterialPageRoute(settings: settings, builder: (context) => LocationPermissionWidget());

      default:
        return null;
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                BluetoothHelper().startBlueToothScan();
                Navigator.of(context).pushNamed('/bluetooth');
              },
              child: const Text('bluetooth'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/locationPermission');
              },
              child: const Text('Access location service'),
            ),

          ],
        ),
      ),
    );
  }
}

class LocationPermissionWidget extends StatefulWidget {
  const LocationPermissionWidget({Key? key}) : super(key: key);

  @override
  State<LocationPermissionWidget> createState() => _LocationPermissionScreen();
}

class _LocationPermissionScreen extends State<LocationPermissionWidget> {
  @override
  void initState() {
    super.initState();
  }

  // 位置服务
  Future<bool> _determineLocationAvailability(BuildContext context) async {
    LocationPermission permission;
    bool locationEnabled;

    try {
      // 手机GPS服务是否已启用。
      // 只有第一次使用的时候可以激活这种弹窗式的权限检查
      permission = await AppPermission().checkLocationPermission();
      locationEnabled = await AppPermission().isLocationServiceEnabled();
      if (!locationEnabled) {
        // 当第一次访问设备位置的权限被拒绝，没次重新申请权限
        await permissionRequestDialog(context);

        //再次检查
        locationEnabled = await AppPermission().isLocationServiceEnabled();
        if (!locationEnabled) {
          Navigator.pop(context);
          return false;
        } else {
          return true;
        }
      } else {
        return true;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> permissionRequestDialog(BuildContext context) async {
    // 假如用户点not allow后，下次点击不会在出现系统权限的弹框（系统权限的弹框只会出现一次），
    // 这时候需要你自己写一个弹框，然后去打开app权限的页面
    return showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text('Please Allowing Location Usage For This Service'),
            content: const Text('Confirm RG-Link To Use The Location Service'),
            actions: <Widget>[
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () {
                  null;
                },
              ),
              CupertinoDialogAction(
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.pop(context);
                  // 打开手机上该app权限的页面
                  //openAppSettings();
                  Geolocator.openLocationSettings();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('location service'),
        ),
        body: Center(
            child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                // 首先判断是否有权限，没权限就不执行了
                bool permissionAllowed = await _determineLocationAvailability(context);
                permissionAllowed ? Navigator.of(context).pushNamed('/bluetooth') : null;
              },
              child: const Icon(Icons.add_location),
            ),
            Text('Please grant location service')
          ],
        )));
  }
}

//----------------bluetooth setting
class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  Map<String, ScanResult> avaliableDeviceMap = Map();
  ScanResult? connectedDevice;
  ListView? _previousListView;


  @override
  void initState() {
    AppPermission().isBTServiceEnabled().then((isBTServiceEnabled) {
      if (isBTServiceEnabled != true) {
        Permission.bluetooth.request();
      } 
    });
    BluetoothHelper().startBlueToothScan();
    super.initState();
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('蓝牙扫描')),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Expanded(
          child: StreamBuilder<ScanResult?>(
            stream: BluetoothHelper().bleScanStream,
            builder: (BuildContext context, AsyncSnapshot<ScanResult?> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return const Text('没有数据流');
                case ConnectionState.active:
                  if (snapshot.hasError) {
                    return Text('Active: 错误: ${snapshot.error}');
                  } else {
                    //优化: 如果当前的ScanResult 是无效数据，则直接返回上一个的Widget View
                    ScanResult? scanResult = snapshot.data;
                    if (scanResult!.device.platformName.isEmpty){
                      if(_previousListView !=null ) return _previousListView!;
                    }

                    avaliableDeviceMap[scanResult.device.remoteId.str] = scanResult;
                    List<ScanResult> deviceList = avaliableDeviceMap.values.toList();

                    // ListView _currentListView =  ListView.builder(
                    //   itemCount: avaliableDeviceMap.length,
                    //   itemBuilder: (BuildContext context, int index) {
                    //     return ListTile(
                    //       title: Text(deviceList[index].scanDevice.device.platformName),
                    //       //trailing: isStillConnecting(deviceList[index], context),
                    //        trailing: Expanded(
                    //         child: SpinKitCircle(color: Colors.blue, size: 20),
                    //       ),
                    //       selectedTileColor: Colors.blueGrey,
 
                    //     );
                    //   },
                    // );

                      ListView _currentListView =  ListView.builder(
                      itemCount: avaliableDeviceMap.length,
                      itemBuilder: (BuildContext context, int index) {
                        return 
                        Row(
                          children: [
                          Expanded(
                            child: ListTile(
                              title: Text(deviceList[index].device.platformName),
              
                              trailing: SizedBox(
                                width: 20,
                                child: SpinKitCircle(color: Colors.black)
                                ),
                          selectedTileColor: Colors.blueGrey,
 
                        )
                        
                        )],);

                      },
                    );

                    _previousListView = _currentListView;
                    return _currentListView;
                  }
                case ConnectionState.waiting:
                  return const Text('等待数据流');
                case ConnectionState.done:
                  return const Text('数据流已经关闭');
              }
            },
          ),
        ),

        Container(
          child: connectedDevice != null
              ? Text('Connected to: ${connectedDevice!.device.advName}')
              : Text('Not connected'),
          padding: EdgeInsets.all(30),
        )
      ])),
    );
  }

  Widget isStillConnecting(ScanResult btDevice, BuildContext context){
    return getButtonForBluetoothDevice(btDevice.device, context);
  }


  void _disconnectDevice() async {
    try {
      await connectedDevice!.device.disconnect();
      setState(() {
        connectedDevice = null;
      });
    } catch (e) {
      print('Disconnection Error: $e');
    }
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    BluetoothHelper().stopBleScan(); // 取消扫描结果的监听
   // timer.cancel();
    super.dispose();
  }
}


class Lock {
  Completer _completer = Completer();

  Future acquire() {
    if (_completer.isCompleted) {
      _completer = Completer();
    }
    return _completer.future;
  }

  void release() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}