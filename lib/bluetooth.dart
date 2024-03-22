import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'utiles/constants.dart';
import 'utiles/dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';


class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  BluetoothPageState createState() => BluetoothPageState();
}

class BluetoothPageState extends State<BluetoothPage> {
  Map<String, ScanResult> avaliableDeviceMap = Map();
  ScanResult? connectedDevice;
  ListView? previousListView = ListView();
  bool initialState = true;

  StreamController<ScanResult> bleScanController = StreamController<ScanResult>();
  Stream<ScanResult> get bleScanStream => bleScanController.stream;

  @override
  void initState() {
    super.initState();
    startScanning();
  }

  int countLOOP = 0;

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BACKGROUND_GREY, // 设置背景颜色
      appBar: AppBar(
        title: const Text(BLUETOOTH),
        backgroundColor: BACKGROUND_GREY,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), // 设置圆角半径
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), // 设置倒角矩形的圆角半径
                  clipBehavior: Clip.hardEdge, // 设置为hardEdge可以使矩形边界清晰
                  child: StreamBuilder<List<ScanResult?>>(
                    stream: FlutterBluePlus.scanResults,
                    builder: (BuildContext context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.none:
                          return const Text(BT_SEARCHING_STATE_NONE);
                        case ConnectionState.active:
                          if (snapshot.hasError) {
                            return Text('$BT_SEARCHING_STATE_ACTIVE_ERROR: ${snapshot.error}');
                          } else {
                            //warning: initially it should keep calling startScanning func to trigger bluetooth scanning
                            while (startScanning() && initialState) {
                              const SpinKitFadingCircle(color: Colors.black, size: 30);
                            }

                            initialState = false;
                            // 如果当前的ScanResult 是无效数据，则直接返回上一个的Widget View
                            List<ScanResult?> listResult = snapshot.data!;

                            for (ScanResult? element in listResult) {
                              if ((element!.device.platformName.isEmpty)) continue;
                              avaliableDeviceMap[element.device.remoteId.str] = element;
                            }

                            List<ScanResult> deviceList = avaliableDeviceMap.values.toList();

                            return Scrollbar(
                                child: ListView.builder(
                              itemCount: avaliableDeviceMap.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Column(
                                  children: <Widget>[
                                    ListTile(
                                      title: Text(deviceList[index].device.platformName),
                                      trailing:
                                          BluetoothToggleButton(device: deviceList[index].device, context: context),
                                      contentPadding:
                                          const EdgeInsets.only(right: 5, left: 10), // 设置trailing与列表项末尾的距离为16.0
                                    ),
                                    //set cutoff line
                                    Container(
                                      height: 2,
                                      color: BACKGROUND_GREY,
                                    )
                                  ],
                                );
                              },
                            ));
                          }
                        case ConnectionState.waiting:
                          return const SpinKitFadingCircle(color: Colors.black, size: 30);
                        case ConnectionState.done:
                          return const Text(BT_SEARCHING_STATE_CLOSE);
                      }
                    },
                  ),
                ),
              ),
            )),
            Container(
              padding: const EdgeInsets.all(30),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitFadingCircle(color: Colors.black, size: 30),
                  SizedBox(width: 10), // 这里设置间距为10
                  Text(BT_SEARCHING_STATE_WAITING),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  bool startScanning() {
    bool Scanning = false;
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 60))
        .then((value) => Scanning = FlutterBluePlus.isScanningNow);
    return Scanning;
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}






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
      await widget.device.connect(timeout: const Duration(seconds: 20));
    } catch (e) {
      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoCustomDialog(BT_CONNECTION_UNSUCCESS_TITLE
                        ,"Please make sure [${widget.device.platformName}] has turned on and within range");
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
      await widget.device.disconnect();
    } catch (e) {
      if (!mounted) return;

      print('Disconnection Error: $e');
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoCustomDialog(
               BT_DISCONNECTION_UNSUCCESS_TITLE
               ,"The [${widget.device.platformName}] may already been disconnected");
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




