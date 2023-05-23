import 'package:xh_dio_utils/base_info.dart';

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

class GetCheckVersion extends BaseInfo{
  @override
  int? code;
  @override
  String? msg;
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

class CheckVersion {
  int? id;
  int? status;
  String? updateTime;
  String? createTime;
  String? packageName;
  int? systemType;
  String? versionName;
  int? versionCode;
  String? description;
  String? fileUrl;
  String? storeUrl;
  int? sort;
  ///是否强制更新 1:是 0:否
  int? isForce;

  CheckVersion(
      {this.id,
      this.status,
      this.updateTime,
      this.createTime,
      this.packageName,
      this.systemType,
      this.versionName,
      this.versionCode,
      this.description,
      this.fileUrl,
      this.isForce,
      this.sort});

  CheckVersion.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    status = json['status'];
    updateTime = json['updateTime'];
    createTime = json['createTime'];
    packageName = json['packageName'];
    systemType = json['systemType'];
    versionName = json['versionName'];
    versionCode = json['versionCode'];
    description = json['description'];
    fileUrl = json['fileUrl'];
    storeUrl = json['storeUrl'];
    sort = json['sort'];
    isForce = json['isForce'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['status'] = status;
    data['updateTime'] = updateTime;
    data['createTime'] = createTime;
    data['packageName'] = packageName;
    data['systemType'] = systemType;
    data['versionName'] = versionName;
    data['versionCode'] = versionCode;
    data['description'] = description;
    data['fileUrl'] = fileUrl;
    data['storeUrl'] = storeUrl;
    data['sort'] = sort;
    data['isForce'] = isForce;
    return data;
  }
}
