import 'package:xh_dio_utils/base_info.dart';

abstract class AbstractGetCheckVersion<T extends BaseInfo> extends BaseInfo{
  int? code;
  String? msg;
  CheckVersion? checkVersion;

   static fromJson(Map map){
     return null;
   }
}
/*
{
  "code": 20000,
  "msg": "成功",
  "data": {
    "id": 3,
    "status": 1,
    "updateTime": "2023-05-12 16:22:30",
    "createTime": "2023-05-11 11:15:11",
    "packageName": "com.sunvua.waterproject.xiaoshuolife",
    "systemType": 1,
    "versionName": "1.0.3",
    "versionCode": 3,
    "description": "新版本应用",
    "fileUrl": "https://obs-bj.cucloud.cn/public/apk/960907f678ce49b9b17b3ac64e337586_app-release(1).apk",
    "storeUrl": "",
    "sort": 0,
    "isForce": 0
  }
}
 */

class GetCheckVersion extends AbstractGetCheckVersion{
  @override
  int? code;
  @override
  String? msg;
  @override
  CheckVersion? checkVersion;

  GetCheckVersion({this.code, this.msg, this.checkVersion});

  GetCheckVersion.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    msg = json['msg'];
    checkVersion = json['data'] != null ? CheckVersion.fromJson(json['data']) : null;
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['msg'] = msg;
    if (this.checkVersion != null) {
      data['data'] = this.checkVersion!.toJson();
    }
    return data;
  }
}

class CheckVersion{

  num? versionCode;
  String? description;
  String? fileUrl;
  String? storeUrl;
  ///是否强制更新 1:是 0:否
  num? isForce;

  CheckVersion(
      {
      this.versionCode,
      this.description,
      this.fileUrl,
      this.isForce,});

  CheckVersion.fromJson(Map<String, dynamic> json) {
    versionCode = json['versionCode'];
    description = json['description'];
    fileUrl = json['fileUrl'];
    storeUrl = json['storeUrl'];
    isForce = json['isForce'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['versionCode'] = versionCode;
    data['description'] = description;
    data['fileUrl'] = fileUrl;
    data['storeUrl'] = storeUrl;
    data['isForce'] = isForce;
    return data;
  }
}
