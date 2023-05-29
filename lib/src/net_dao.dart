import 'package:flutter/material.dart';
import 'package:version_update/src/get_check_version.dart';
import 'package:version_update/version_update.dart';
import 'package:xh_dio_utils/base_info.dart';
import 'package:xh_dio_utils/data_utils_constant.dart';
import 'package:xh_dio_utils/xh_dio_utils.dart';

typedef Success<T> = Function(T data);

NetUtils get netUtils => NetUtils();

class NetUtils extends DataUtilsBasic<BaseInfo> {
  static NetUtils? _instance;
  XHDioUtil _xhDioUtil;
  VoidCallback? tokenExpiredCallBack;

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

  void setTokenExpiredCallBack(VoidCallback voidCallback) {
    tokenExpiredCallBack = voidCallback;
  }

  @override
  void tokenExpired() {
    tokenExpiredCallBack?.call();
  }

  Future<AbstractGetCheckVersion?> getCheckVersion(
      {required String url,
      Map<String, dynamic>? params,
      FormJson? formJson,
      bool isShowToast = true}) async {
    AbstractGetCheckVersion? getCheckVersion = await commonHandle<AbstractGetCheckVersion>(() {
      return _xhDioUtil.request(url,
          method: DioMethod.get,
          params: params,
          beanFromJson: formJson ?? GetCheckVersion.fromJson);
    }, isShowToast: isShowToast);
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
  static void log(Object? object) {
    debugPrint("VersionUpdate $object");
  }

  static void error(Object? object) {
    debugPrint("VersionUpdate $object");
  }
}
