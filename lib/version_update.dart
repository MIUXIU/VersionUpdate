library version_update;

import 'dart:async';
import 'dart:io';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/state_manager.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version_update/src/get_check_version.dart';

import 'src/net_dao.dart';
import 'src/permission_utils.dart';
import 'package:toast_utils/toast_utils.dart';
export 'package:ota_update/ota_update.dart';
export 'package:version_update/src/get_check_version.dart';

typedef VersionUpdateCallBack = Function(OtaEvent event);
typedef FormJson = AbstractGetCheckVersion Function(Map<String, dynamic> map);

enum VersionUpdateStatus {
  init,
  getInfo,
  netRequest,
  downloading,
}

class VersionUpdate {
  static const String updateVersionDialogKey = "updateVersionDialogKey";
  static VersionUpdate? _instance;
  String getVersionUrl;
  VersionUpdateCallBack? versionUpdateCallBack;
  FormJson? formJson;
  VersionUpdateStatus versionUpdateStatus = VersionUpdateStatus.init;
  Rx<Widget> dialogContent = const AlertDialog().obs;
  RxString rxContent = "".obs;
  String content = "";
  RxDouble downValue = 0.0.obs;
  CheckVersion _checkVersion = CheckVersion();
  bool isDialogShowing = false;
  int? _autoDismissSeconds;

  Map<String, dynamic>? customParams;
  Timer? autoDismissTimer;

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

  void setFormJson(FormJson formJson) {
    this.formJson = formJson;
  }

  void setCustomParams(Map<String, dynamic>? params) {
    customParams = params;
  }

  VersionUpdateStatus getVersionUpdateStatus() {
    return versionUpdateStatus;
  }

  Future<void> check(
      {bool showTips = true, bool download = true, VoidCallback? voidCallback, required BuildContext context, int? autoDismissSeconds}) async {
    this._autoDismissSeconds = autoDismissSeconds;
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

    Map<String, dynamic>? params = {
      "packageName": packageName,
      "systemName": Platform.isAndroid ? "Android" : (Platform.isIOS ? "IOS" : ""),
      "versionCode": buildNumber,
    };

    AbstractGetCheckVersion? getCheckVersion = await netUtils.getCheckVersion(
        formJson: formJson, params: customParams ?? params, isShowToast: showTips, url: getVersionUrl);
    if (getCheckVersion == null) {
      versionUpdateStatus = VersionUpdateStatus.init;
      return;
    }
    if (getCheckVersion.checkVersion == null) {
      if (showTips) {
        Logger.log("ssss: ${getCheckVersion.toJson()}");
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
      Uri uri = Uri.parse(_checkVersion.storeUrl ?? "");
      if (isForce) {
        Logger.log("IOS force Update");
        dialogContent.value = AlertDialog(
          title: const Text("需更新应用版本后使用"),
          content: Text(_checkVersion.description ?? "当前应用有新的版本"),
          actions: [
            TextButton(
                child: const Text("确定"),
                onPressed: () async {
                  try {
                    launchUrl(uri);
                  } catch (e) {
                    Logger.error("launchUrl error: $e");
                  }

                  versionUpdateStatus = VersionUpdateStatus.init;
                  return;
                }),
          ],
        );
        if (context.mounted) {
          showUpdateDialog(context, _checkVersion);
        }
      } else {
        Logger.log("IOS Update");
        // if(showTips) {
        //   ToastUtil.show("应用有新版本，请通过应用市场进行更新");
        // }
        dialogContent.value = AlertDialog(
          title: const Text("有可更新的应用版本"),
          content: Text(_checkVersion.description ?? "当前应用有新的版本"),
          actions: [
            TextButton(
                child: const Text("确定"),
                onPressed: () async {
                  try {
                    launchUrl(uri);
                  } catch (e) {
                    Logger.error("launchUrl error: $e");
                  }

                  versionUpdateStatus = VersionUpdateStatus.init;
                  return;
                }),
          ],
        );
        if (context.mounted) {
          showUpdateDialog(context, _checkVersion);
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

    if (context.mounted) {
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
    autoDismissTimer?.cancel();
    autoDismissTimer = null;
    if (_autoDismissSeconds != null && (_autoDismissSeconds ?? 0) > 0) {
      int currentAutoDismissSeconds = _autoDismissSeconds ?? 0;
      autoDismissTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (currentAutoDismissSeconds == 0) {
          SmartDialog.dismiss(tag: updateVersionDialogKey);
          autoDismissTimer?.cancel();
          autoDismissTimer = null;
          return;
        }
        rxContent.value = "$content\n$currentAutoDismissSeconds秒后自动关闭";
        currentAutoDismissSeconds--;
      });
    }
    SmartDialog.show(
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            return !isForce;
          },
          child: Obx(() {
            return dialogContent.value;
          }),
        );
      },
      backDismiss: !isForce,
      clickMaskDismiss: !isForce,
      tag: updateVersionDialogKey,
    ).then((value){
      isDialogShowing = false;
      autoDismissTimer?.cancel();
      autoDismissTimer = null;
    });
  }

  _dialogContentShowUpdateTips(CheckVersion checkVersion, BuildContext context) {
    bool isForce = checkVersion.isForce == 1;
    content = checkVersion.description ?? "当前应用有新的版本";
    rxContent.value = content;
    dialogContent.value = AlertDialog(
      title: Text(isForce ? "需更新应用版本后使用" : "有可更新的应用版本"),
      content: Obx(() {
        return Text(rxContent.value);
      }),
      actions: [
        isForce
            ? const SizedBox()
            : TextButton(
            child: const Text("取消"),
            onPressed: () {
              versionUpdateStatus = VersionUpdateStatus.init;
              SmartDialog.dismiss(tag: updateVersionDialogKey);
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
    autoDismissTimer?.cancel();
    autoDismissTimer = null;
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
                SmartDialog.dismiss(tag: updateVersionDialogKey);
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
                  SmartDialog.dismiss(tag: updateVersionDialogKey);
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
