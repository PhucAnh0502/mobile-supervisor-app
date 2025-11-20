part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent extends Equatable{
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class RegistrationSubmitted extends AuthEvent {
  final String fullName;
  final String address;
  final String email;
  final String citizenId;
  final String phoneNumber;

  const RegistrationSubmitted({
    required this.fullName,
    required this.address,
    required this.email,
    required this.citizenId,
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [fullName, address, email, citizenId, phoneNumber];
}
