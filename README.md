
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





