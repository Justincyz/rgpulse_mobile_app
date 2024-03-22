import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermission {
  late LocationPermission GeoPermission;
  late Permission BTPermission = Permission.bluetooth;

  AppPermission._internal();
  static final AppPermission instance = AppPermission._internal();
  // 将该类声明为单例
  factory AppPermission() {

    return instance;
  }

  Future<LocationPermission> getLocationPermission() async {
    GeoPermission = await Geolocator.checkPermission();
    return GeoPermission;
  }

  Future<LocationPermission> checkLocationPermission() async {
    GeoPermission = await Geolocator.checkPermission();
    return GeoPermission;
  }

  Future<bool> isLocationServiceEnabled() async {
    LocationPermission locationPermission = await getLocationPermission();
    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<bool> isBTServiceEnabled() async{
    PermissionStatus BTStatus = await BTPermission.request();
    return BTStatus == PermissionStatus.granted;
  }

  Future<PermissionStatus> requestBluetoothPermission(){
    return Permission.bluetooth.request();
  }

  Future<bool> isBlueToothEnabled() async{
    bool isGranted = false;
    requestBluetoothPermission().then((value) => isGranted =(value == PermissionStatus.granted));
    return isGranted;
  }
}