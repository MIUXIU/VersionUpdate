
A Dio Utils
## Usage



```dart

  toast_utils:
    git:
      url: https://github.com/MIUXIU/ToastUtils
      ref: v1.1.0
      
  xh_dio_utils:
    git:
      url: https://github.com/MIUXIU/XHDioUtils
      ref: v1.1.0
  version_update:
    git:
      url: https://github.com/MIUXIU/VersionUpdate
      ref: v1.1.0

  dio: ^5.1.2
  get: ^4.6.5
  ota_update: ^4.0.3
  package_info_plus: ^4.0.0
  permission_handler: ^10.2.0
  url_launcher: ^6.1.11
  fluttertoast: ^8.2.1
  flutter_smart_dialog: ^4.9.0+6
  ///检查更新版本


```

### Flutter main文件中添加
```dart
  return GetMaterialApp(
  navigatorObservers: [FlutterSmartDialog.observer],
  builder: FlutterSmartDialog.init(),  ///可嵌套 builder: FlutterSmartDialog.init(builder: EasyLoading.init()),
  );
```

### 简单使用
```dart
  VersionUpdate versionUpdate = VersionUpdate(getVersionUrl: HttpConfig.checkVersion, token: "", isDebug: Global.isDebug);
  versionUpdate.check(context: context,showTips: false);
```

### 更换Bean类及参数的使用方法 其中，自行实现GetCheckVersionBean的fromJson解析方法
```dart
  VersionUpdate versionUpdate = VersionUpdate(getVersionUrl: HttpConfig.checkVersion, token: "", isDebug: Global.isDebug);
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String packageName = packageInfo.packageName;
  String buildNumber = packageInfo.buildNumber;
  Map<String, dynamic>? params = {
    "packageName": packageName,
    "versionCode": buildNumber,
    "deviceType": Platform.isAndroid ? "Android" : (Platform.isIOS ? "IOS" : ""),
  };
  versionUpdate.setCustomParams(params);
  versionUpdate.setFormJson(GetCheckVersionBean.fromJson);
  MyLogger.log("checkVersion Update");
  versionUpdate.check(context: Get.context!,showTips: false);
```


AndroidManifest.xml  application结点下添加
```

       <provider
           android:name="sk.fourq.otaupdate.OtaUpdateFileProvider"
           android:authorities="${applicationId}.ota_update_provider"
           android:exported="false"
           android:grantUriPermissions="true">
           <meta-data
               android:name="android.support.FILE_PROVIDER_PATHS"
               android:resource="@xml/filepaths" />
       </provider>
```





