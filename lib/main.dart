import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'permission/AppPermission.dart';
import 'dart:core';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'utiles/constants.dart';
import 'bluetooth.dart';
import 'utiles/dialog.dart';


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
      // case '/remoteControl':
      //   return MaterialPageRoute(settings: settings, builder: (context) => LocationPermissionWidget());

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
  const LocationPermissionWidget({super.key});

  @override
  State<LocationPermissionWidget> createState() => _LocationPermissionScreen();
}

class _LocationPermissionScreen extends State<LocationPermissionWidget> {
  @override
  void initState() {
    super.initState();
  }

  // 位置服务
  Future<bool> isLocationAvailability(BuildContext context) async {
    bool locationEnabled;

    try {
      // 手机GPS服务是否已启用。
      // 只有第一次使用的时候可以激活这种弹窗式的权限检查
      locationEnabled = await AppPermission().isLocationServiceEnabled();
      if (!locationEnabled) {
        // 当第一次访问设备位置的权限被拒绝，每次重新申请权限
        await geoPermissionRequestDialog(context);

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
      return false;
    }
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
                bool permissionAllowed = await isLocationAvailability(context);
                permissionAllowed ? Navigator.of(context).pushNamed('/bluetooth') : null;
              },
              child: const Icon(Icons.add_location),
            ),
            
            Container()
          ],
        )));
  }
}

