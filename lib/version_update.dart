library version_update;

import 'dart:io';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version_update/get_check_version.dart';
import 'package:version_update/net_dao.dart';
import 'package:xh_dio_utils/toast_util.dart';

import 'permission_utils.dart';

class VersionUpdate {
  static VersionUpdate? _instance;
  String getVersionUrl;

  VersionUpdate._(this.getVersionUrl);

  factory VersionUpdate({required String getVersionUrl, required String token, bool isDebug = false}) {
    _instance ??= VersionUpdate._(
      getVersionUrl,
    );

    netUtils.setToken(token);
    return _instance!;
  }

  Future check({bool showTips = true, bool download = true}) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String packageName = packageInfo.packageName;
    String buildNumber = packageInfo.buildNumber;
    GetCheckVersion? getCheckVersion =
        await netUtils.getCheckVersion(packageName: packageName, buildNumber: buildNumber, isShowToast: showTips, url: getVersionUrl);

    if (getCheckVersion == null) {
      return;
    }
    if (getCheckVersion.checkVersion == null) {
      if (showTips) {
        ToastUtil.show("当前已是最新版本");
      }
      return;
    }
    CheckVersion checkVersion = getCheckVersion.checkVersion ?? CheckVersion();

    int code = 0;

    try {
      code = int.parse(buildNumber);
    } catch (e) {
      Logger.error("buildNumber error: $e");
    }
    if (code >= (checkVersion.versionCode ?? 0)) {
      if (showTips) {
        ToastUtil.show("当前已是最新版本");
      }
      return;
    }

    if (Platform.isIOS) {
      ToastUtil.show("请通过应用市场进行更新！");
      return;
    }

    if (download) {
      if (checkVersion.fileUrl == null || checkVersion.fileUrl!.isEmpty) {
        if (showTips) {
          ToastUtil.show("未获取到下载链接，无法更新应用");
        }
        return;
      }

      if (!await requestInstallPackagesPermission()) {
        ToastUtil.show("请赋予安装权限后，继续尝试更新！");
        return;
      }
    }

    try {
      ToastUtil.show("后台下载更新中……", toastLength: Toast.LENGTH_LONG);

      OtaUpdate()
          .execute(
        checkVersion.fileUrl ?? "",
        destinationFilename: 'smart_mesh.apk',
      )
          .listen(
        (OtaEvent event) {
          Logger.log('OTA status: ${event.status} : ${event.value} \n');
          // updateMsg.value = '下载中…${event.value}';
          if (event.status == OtaStatus.INSTALLING) {
            // updateMsg.value = "点击安装";
          }
        },
      );
    } catch (e) {
      Logger.log('Failed to make OTA update. Details: $e');
    }

    return;
  }
}
