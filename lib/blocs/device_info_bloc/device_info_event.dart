part of 'device_info_bloc.dart';

@immutable
sealed class DeviceInfoEvent extends Equatable {
    const DeviceInfoEvent();

    @override
    List<Object> get props => [];
}

class FetchDeviceInfo extends DeviceInfoEvent {}

class SubmitCollectedDataEvent extends DeviceInfoEvent {
    final bool useMqtt;

    const SubmitCollectedDataEvent({this.useMqtt = false});

    @override
    List<Object> get props => [useMqtt];
}
