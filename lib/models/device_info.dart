class DeviceInfo{
  final String model;
  final String type;
  final String os;

  DeviceInfo({
    required this.model,
    required this.type,
    required this.os,
  });

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'type': type,
      'os': os,
    };
  }

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      model: json['model'],
      type: json['type'],
      os: json['os'],
    );
  }
}