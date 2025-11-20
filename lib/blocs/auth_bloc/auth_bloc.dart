import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gr2/models/device_info.dart';
import 'package:gr2/models/user_info.dart';
import 'package:gr2/services/api_service.dart';
import 'package:gr2/services/device_info_service.dart';
import 'package:gr2/services/storage_service.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;
  final DeviceInfoService deviceInfoService;
  final StorageService storageService;

  AuthBloc({
    required this.apiService,
    required this.deviceInfoService,
    required this.storageService,
  }) : super(RegistrationInitial()) {
    on<RegistrationSubmitted>(_onRegistrationSubmitted);
  }

  Future<void> _onRegistrationSubmitted(
    RegistrationSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(RegistrationLoading());
    try {
      final DeviceInfo deviceInfo = await deviceInfoService.getDeviceInfo();

      final userInfo = UserInfo(
        fullName: event.fullName,
        address: event.address,
        email: event.email,
        citizenId: event.citizenId,
        phoneNumber: event.phoneNumber,
        device: deviceInfo,
      );

      final bool success = await apiService.registerUser(userInfo);
      if (success) {
        await storageService.setHasRegistered();
        emit(RegistrationSuccess());
      } else {
        emit(const RegistrationFailure('Registration failed'));
      }
    } catch (e) {
      emit(RegistrationFailure(e.toString()));
    }
  }
}
