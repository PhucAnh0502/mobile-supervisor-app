part of 'device_info_bloc.dart';

@immutable
sealed class DeviceInfoState extends Equatable {
  const DeviceInfoState();

  @override
  List<Object> get props => [];
}

class DeviceInfoInitial extends DeviceInfoState {}

class DeviceInfoLoading extends DeviceInfoState {}

class DeviceInfoLoaded extends DeviceInfoState {
  final String deviceName;
  final String phoneNumber;
  final String location;
  final Map<String, double?>? locationMap;
  final String cellInfo;

  const DeviceInfoLoaded({
    required this.deviceName,
    required this.phoneNumber,
    required this.location,
    required this.locationMap,
    required this.cellInfo,
  });

  @override
  List<Object> get props => [
    deviceName,
    phoneNumber,
    location,
    locationMap?.toString() ?? '{}',
    cellInfo,
  ];
}

class DeviceInfoError extends DeviceInfoState {
  final String message;

  const DeviceInfoError({required this.message});

  @override
  List<Object> get props => [message];
}
