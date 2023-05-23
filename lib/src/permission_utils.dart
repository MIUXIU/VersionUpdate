import 'package:permission_handler/permission_handler.dart';
import 'package:toast_utils/toast_utils.dart';


/// 申请相机权限
/// 授予相机权限返回true， 否则返回false
Future<bool> requestCameraPermission() async {
  return requestPermission(Permission.camera);
}
/// 申请定位权限
/// 授予定位权限返回true， 否则返回false
Future<bool> requestLocationPermission() async {
  return requestPermission(Permission.location);
}
/// ios申请定位权限
/// 授予定位权限返回true， 否则返回false
Future<bool> requestLocationWhenInUsePermission({bool showTips =true}) async {
  return requestPermission(Permission.locationWhenInUse,showTips: showTips);
}

/// ios申请总是定位权限
/// 授予定位权限返回true， 否则返回false
Future<bool> requestLocationAlwaysPermission({bool showTips =true}) async {
  return requestPermission(Permission.locationAlways,showTips: showTips);
}
/// 申请存储权限
/// 授予存储权限返回true， 否则返回false
Future<bool> requestStoragePermission() async {
 return requestPermission(Permission.storage);
}

/// 申请电话权限
/// 授予电话权限返回true， 否则返回false
Future<bool> requestPhonePermission() async {
  return requestPermission(Permission.phone);
}

/// 申请安装apk权限
/// 申请安装apk权限true， 否则返回false
Future<bool> requestInstallPackagesPermission() async {
  return requestPermission(Permission.requestInstallPackages);
}

/// 获取权限
Future<bool> requestPermission<T extends Permission>(T t,{bool showTips = true}) async {
  //获取当前的权限
  var status = await t.status;
  if (status == PermissionStatus.granted) {
    //已经授权
    return true;
  } else {
    //未授权则发起一次申请
    status = await t.request();
    if (status == PermissionStatus.granted) {
      return true;
    } else {
      if(showTips) {
        ToastUtil.show("请赋予相关权限！！");
      }
      return false;
    }
  }
}

