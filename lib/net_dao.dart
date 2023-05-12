import 'dart:io';

import 'package:flutter/material.dart';
import 'package:version_update/get_check_version.dart';
import 'package:xh_dio_utils/base_info.dart';
import 'package:xh_dio_utils/data_utils_constant.dart';
import 'package:xh_dio_utils/xh_dio_utils.dart';

typedef Success<T> = Function(T data);

NetUtils get netUtils => NetUtils();

class NetUtils extends DataUtilsBasic {
  static NetUtils? _instance;
  XHDioUtil _xhDioUtil;

  NetUtils._(this._xhDioUtil);

  static Map<String, Object> optHeader = <String, Object>{
    'Content-Type': 'application/json',
  };

  factory NetUtils({bool? isDebug}) {
    _instance ??= NetUtils._(XHDioUtil()
      ..setConnectMaxTime(const Duration(seconds: 10))
      ..setReceiveMaxTime(const Duration(seconds: 10))
      ..setCommonHeaders(optHeader)
      ..setLog(isDebug ?? false)
      ..build());
    return _instance!;
  }

  void setToken(String token) {
    _xhDioUtil.commonHeaders[DataUtilsBasic.X_TOKEN] = token;
  }

  String getToken() {
    Object tokenObject = _xhDioUtil.commonHeaders[DataUtilsBasic.X_TOKEN] ?? "";
    return tokenObject is String ? tokenObject : "";
  }

  void removeToken() {
    _xhDioUtil.commonHeaders.remove(DataUtilsBasic.X_TOKEN);
  }


  Future<GetCheckVersion?> getCheckVersion({required String url,required String packageName,required String buildNumber,bool isShowToast = true}) async {
    GetCheckVersion? getCheckVersion = await commonHandle<GetCheckVersion>(() {
      return _xhDioUtil.request(url, method: DioMethod.get,params: {
        "packageName": packageName,
        "systemName": Platform.isAndroid
            ? "Android"
            : Platform.isIOS
            ? "IOS"
            : "",
        "versionCode": buildNumber,
      }, beanFromJson: GetCheckVersion.fromJson);
    },isShowToast: isShowToast);
    return getCheckVersion;
  }

  ///统一处理方式
  Future<T?> commonHandle<T extends BaseInfo>(Function request, {bool isShowToast = true}) async {
    try {
      return await directHandle(request, isShowToast: isShowToast);
    } catch (e, ss) {
      Logger.error(e);
      Logger.error(ss);
      errorAction('commonHandle', e, isShowToast: isShowToast);
      return null;
    }
  }

  ///直接处理
  Future<T?> directHandle<T extends BaseInfo>(Function request, {bool isShowToast = true}) async {
    T baseInfo = await request();
    if (baseInfo.code == DataUtilsBasic.HTTP_SUCCESS_CODE) {
      return baseInfo;
    } else {
      failAction('doLogin', baseInfo, isShowToast: isShowToast);
      return null;
    }
  }
}

class Logger {
  static void log(Object? object){
    debugPrint(object?.toString());
  }

  static void error(Object? object){
    debugPrint(object?.toString());
  }
}
