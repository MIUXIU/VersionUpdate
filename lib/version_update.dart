library version_update;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/state_manager.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version_update/get_check_version.dart';
import 'package:version_update/net_dao.dart';
import 'package:xh_dio_utils/toast_util.dart';

import 'permission_utils.dart';
export 'package:ota_update/ota_update.dart';

typedef VersionUpdateCallBack = Function(OtaEvent event);

enum VersionUpdateStatus {
  init,
  getInfo,
  netRequest,
  downloading,
}

class VersionUpdate {
  static VersionUpdate? _instance;
  String getVersionUrl;
  VersionUpdateCallBack? versionUpdateCallBack;
  VersionUpdateStatus versionUpdateStatus = VersionUpdateStatus.init;
  Rx<Widget> dialogContent = const AlertDialog().obs;
  RxDouble downValue = 0.0.obs;
  CheckVersion _checkVersion = CheckVersion();
  bool isDialogShowing = false;

  VersionUpdate._(this.getVersionUrl);

  factory VersionUpdate({required String getVersionUrl, required String token, bool isDebug = false}) {
    _instance ??= VersionUpdate._(
      getVersionUrl,
    );

    NetUtils(isDebug: isDebug).setToken(token);
    return _instance!;
  }

  void setVersionUpdateCallBack(VersionUpdateCallBack versionUpdateCallBack) {
    this.versionUpdateCallBack = versionUpdateCallBack;
  }

  VersionUpdateStatus getVersionUpdateStatus() {
    return versionUpdateStatus;
  }

  Future<void> check(
      {bool showTips = true, bool download = true, VoidCallback? voidCallback, required BuildContext context}) async {
    if (versionUpdateStatus != VersionUpdateStatus.init) {
      showUpdateDialog(context, _checkVersion);
      return;
    }

    versionUpdateStatus = VersionUpdateStatus.getInfo;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String packageName = packageInfo.packageName;
    String buildNumber = packageInfo.buildNumber;
    if (voidCallback != null) {
      netUtils.setTokenExpiredCallBack(voidCallback);
    }

    versionUpdateStatus = VersionUpdateStatus.netRequest;
    GetCheckVersion? getCheckVersion = await netUtils.getCheckVersion(
        packageName: packageName, buildNumber: buildNumber, isShowToast: showTips, url: getVersionUrl);

    if (getCheckVersion == null) {
      versionUpdateStatus = VersionUpdateStatus.init;
      return;
    }
    if (getCheckVersion.checkVersion == null) {
      if (showTips) {
        ToastUtil.show("当前已是最新版本");
      }
      versionUpdateStatus = VersionUpdateStatus.init;
      return;
    }
    _checkVersion = getCheckVersion.checkVersion ?? CheckVersion();

    int code = 0;

    try {
      code = int.parse(buildNumber);
    } catch (e) {
      Logger.error("buildNumber error: $e");
    }

    if (code >= (_checkVersion.versionCode ?? 0)) {
      if (showTips) {
        ToastUtil.show("当前已是最新版本");
      }
      versionUpdateStatus = VersionUpdateStatus.init;
      return;
    }


    if (Platform.isIOS) {
      bool isForce = _checkVersion.isForce == 1;
      if (isForce) {
        dialogContent.value = AlertDialog(
          title: const Text("需更新应用版本后使用"),
          content: Text(_checkVersion.description ?? "当前应用有新的版本"),
          actions: [
            TextButton(
                child: const Text("确定"),
                onPressed: () async {
                  Uri uri = Uri.parse(_checkVersion.fileUrl ?? "");
                  bool result = await launchUrl(uri);
                  if(!result){
                    Logger.error("launchUrl error");
                    if(context.mounted) {
                      Navigator.pop(context, false);
                    }
                  }
                  versionUpdateStatus = VersionUpdateStatus.init;
                  return;
                }),
          ],
        );
        if(context.mounted) {
          showUpdateDialog(context, _checkVersion);
        }
      } else {
        ToastUtil.show("请通过应用市场进行更新！");
        Uri uri = Uri.parse(_checkVersion.fileUrl ?? "");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }

      versionUpdateStatus = VersionUpdateStatus.init;
      return;
    }

    if (download) {
      if (_checkVersion.fileUrl == null || _checkVersion.fileUrl!.isEmpty) {
        if (showTips) {
          ToastUtil.show("未获取到下载链接，无法更新应用");
        }
        versionUpdateStatus = VersionUpdateStatus.init;
        return;
      }
    }

    if(context.mounted) {
      _dialogContentShowUpdateTips(_checkVersion, context);
    }

    if (context.mounted) {
      showUpdateDialog(context, _checkVersion);
    } else {
      Logger.error("context not mounted go to install");
      _startDownLoad(_checkVersion, context);
    }

    return;
  }

  Future<void> showUpdateDialog(BuildContext context, CheckVersion checkVersion) async {
    bool isForce = checkVersion.isForce == 1;
    isDialogShowing = true;
    showDialog(
        context: context,
        barrierDismissible: !isForce,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async {
              return !isForce;
            },
            child: Obx(() {
              return dialogContent.value;
            }),
          );
        }).then((value) => isDialogShowing = false);
  }

  _dialogContentShowUpdateTips(CheckVersion checkVersion, BuildContext context) {
    bool isForce = checkVersion.isForce == 1;
    dialogContent.value = AlertDialog(
      title: Text(isForce ? "需更新应用版本后使用" : "有可更新的应用版本"),
      content: Text(checkVersion.description ?? "当前应用有新的版本"),
      actions: [
        isForce
            ? const SizedBox()
            : TextButton(
                child: const Text("取消"),
                onPressed: () {
                  versionUpdateStatus = VersionUpdateStatus.init;
                  Navigator.pop(context, false);
                }),
        TextButton(
            child: const Text("确定"),
            onPressed: () async {
              if (!await requestInstallPackagesPermission()) {
                ToastUtil.show("请赋予安装权限后，继续尝试更新！");
                versionUpdateStatus = VersionUpdateStatus.init;
                return;
              }
              // ignore: use_build_context_synchronously
              _startDownLoad(checkVersion, context);
            }),
      ],
    );
  }

  void _startDownLoad(CheckVersion checkVersion, BuildContext context) {
    bool isForce = checkVersion.isForce == 1;
    try {
      ToastUtil.show("后台下载更新中……", toastLength: Toast.LENGTH_LONG);
      versionUpdateStatus = VersionUpdateStatus.downloading;
      dialogContent.value = AlertDialog(
        title: const Text("下载中"),
        content: Obx(() {
          return LinearProgressIndicator(
            value: downValue.value,
          );
        }),
        actions: [
          isForce
              ? const SizedBox()
              : TextButton(
                  child: const Text("后台下载更新"),
                  onPressed: () {
                    Navigator.pop(context, false);
                  }),
        ],
      );

      OtaUpdate()
          .execute(
        checkVersion.fileUrl ?? "",
        destinationFilename: 'water_new.apk',
      )
          .listen(
        (OtaEvent event) {
          versionUpdateCallBack?.call(event);
          Logger.log('OTA status: ${event.status} : ${event.value} \n');
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              int value = 0;
              try {
                value = int.parse(event.value ?? "0");
              } catch (e) {
                Logger.error("DOWNLOADING int.parse error: $e");
              }
              downValue.value = value / 100;
              break;
            case OtaStatus.INSTALLING:
              versionUpdateStatus = VersionUpdateStatus.init;
              dialogContent.value = const AlertDialog(
                title: Text("安装中"),
                content: Center(widthFactor: 1, heightFactor: 1, child: CircularProgressIndicator()),
              );

              Future.delayed(const Duration(seconds: 1)).then((value) {
                if (isForce) {
                  _dialogContentShowUpdateTips(checkVersion, context);
                } else {
                  if (isDialogShowing) {
                    Navigator.pop(context);
                  }
                }
              });

              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
              versionUpdateStatus = VersionUpdateStatus.init;
              if (isForce) {
                _dialogContentShowUpdateTips(checkVersion, context);
              }

              break;
          }

          // updateMsg.value = '下载中…${event.value}';
          if (event.status == OtaStatus.INSTALLING) {
            // updateMsg.value = "点击安装";
          }
        },
      );
    } catch (e) {
      Logger.log('Failed to make OTA update. Details: $e');
    }
  }
}
