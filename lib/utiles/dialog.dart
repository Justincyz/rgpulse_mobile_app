import 'package:flutter/cupertino.dart';
import 'constants.dart';
import 'package:geolocator/geolocator.dart';

// ignore: must_be_immutable
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

Future<void> geoPermissionRequestDialog(BuildContext context) async {
  return showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Please enable location services to access all features.'),
          content: const Text('Please confirm allowing RG-Link to use location service.'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.pop(context);
                // 打开手机上该app权限的页面
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
    });
}


Future<void> bluetoothPermissionRequestDialog(BuildContext context) async {
  return showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Please enable bluetooth services to access all features.'),
          content: const Text('Please confirm allowing RG-Link to use bluetooth service.'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            CupertinoDialogAction(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.pop(context);
                // 打开手机上该app权限的页面
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
    });
}