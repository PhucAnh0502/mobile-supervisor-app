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
      emit(DeviceInfoError(message: 'Error: ${e.toString()}'));
    }
  }
}
