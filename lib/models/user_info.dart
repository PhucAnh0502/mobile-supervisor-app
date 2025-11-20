import 'device_info.dart';

class UserInfo {
  final String fullName;
  final String address;
  final String email;
  final String citizenId;
  final String phoneNumber;
  final DeviceInfo device;

  UserInfo({
    required this.fullName,
    required this.address,
    required this.email,
    required this.citizenId,
    required this.phoneNumber,
    required this.device,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'address': address,
      'email': email,
      'citizenId': citizenId,
      'phoneNumber': phoneNumber,
      'device': device.toJson(),
    };
  }
}