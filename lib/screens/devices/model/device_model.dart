class DeviceData {
  int id;
  int userId;
  String deviceId;
  String deviceName;
  String platform;
  String createdAt;
  String updatedAt;

  DeviceData({
    this.id = -1,
    this.userId = -1,
    this.deviceId = "",
    this.deviceName = "",
    this.platform = "",
    this.createdAt = "",
    this.updatedAt = "",
  });

  factory DeviceData.fromJson(Map<String, dynamic> json) {
    return DeviceData(
      id: json['id'] is int ? json['id'] : -1,
      userId: json['user_id'] is int ? json['user_id'] : -1,
      deviceId: json['device_id'] is String ? json['device_id'] : "",
      deviceName: json['device_name'] is String ? json['device_name'] : "",
      platform: json['platform'] is String ? json['platform'] : "",
      createdAt: json['created_at'] is String ? json['created_at'] : "",
      updatedAt: json['updated_at'] is String ? json['updated_at'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}