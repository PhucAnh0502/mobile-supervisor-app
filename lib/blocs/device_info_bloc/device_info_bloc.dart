import 'package:bloc/bloc.dart';
import 'package:gr2/services/device_info_service.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

part 'device_info_event.dart';
part 'device_info_state.dart';

class DeviceInfoBloc extends Bloc<DeviceInfoEvent, DeviceInfoState> {
  final DeviceInfoService _deviceInfoService;

  DeviceInfoBloc(this._deviceInfoService) : super(DeviceInfoInitial()) {
    on<FetchDeviceInfo>(_onFetchDeviceInfo);
    on<SubmitCollectedDataEvent>(_onSubmitCollectedData);
  }

  Future<void> _onFetchDeviceInfo(
    FetchDeviceInfo event,
    Emitter<DeviceInfoState> emit,
  ) async {
    try {
      emit(DeviceInfoLoading());
      
      await _deviceInfoService.requestPermission();
      
      final results = await Future.wait([
        _deviceInfoService.getDeviceInfo(),
        _deviceInfoService.getPhoneNumber(),
        _deviceInfoService.getLocation(),
        _deviceInfoService.getCellInfo(),
      ]);

      final device = results[0] as dynamic; 
      final deviceName = (device is String) ? device : device.model;
      final phoneNumber = results[1] as String;
      final Map<String, double?>? locationMap = results[2] as Map<String, double?>?;
      final String locationDisplay = locationMap == null
          ? 'N/A'
          : 'Lat: ${locationMap['lat']}, Lon: ${locationMap['lon']}';
      final cellInfo = results[3] as String;

      emit(DeviceInfoLoaded(
        deviceName: deviceName,
        phoneNumber: phoneNumber,
        location: locationDisplay,
        locationMap: locationMap,
        cellInfo: cellInfo,
      ));
    } catch (e) {
      emit(DeviceInfoError(message: 'Lỗi lấy thông tin: ${e.toString()}'));
    }
  }

  Future<void> _onSubmitCollectedData(
    SubmitCollectedDataEvent event,
    Emitter<DeviceInfoState> emit,
  ) async {
    final currentState = state;
    
    try {
      final ok = await _deviceInfoService.submitCollectedData(useMqtt: event.useMqtt);
      
      if (ok) {
        emit(DeviceInfoSubmitSuccess(
          event.useMqtt ? 'Đã gửi qua MQTT (HiveMQ)' : 'Gửi qua API thành công!',
        ));
      } else {
        emit(DeviceInfoError(
          message: event.useMqtt ? 'Gửi qua MQTT thất bại' : 'Gửi qua API thất bại',
        ));
      }

      if (currentState is DeviceInfoLoaded) {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(currentState); 
      
      }
      
    } catch (e) {
      emit(DeviceInfoError(
        message: event.useMqtt
            ? 'Lỗi gửi MQTT: ${e.toString()}'
            : 'Lỗi gửi dữ liệu: ${e.toString()}',
      ));
      if (currentState is DeviceInfoLoaded) {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(currentState);
      }
    }
  }
}