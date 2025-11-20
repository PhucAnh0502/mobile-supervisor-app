part of 'auth_bloc.dart';

@immutable
sealed class AuthState extends Equatable{
  const AuthState();

  @override
  List<Object> get props => [];
}

class RegistrationInitial extends AuthState {}

class RegistrationLoading extends AuthState {}

class RegistrationSuccess extends AuthState {}

class RegistrationFailure extends AuthState {
  final String error;

  const RegistrationFailure(this.error);

  @override
  List<Object> get props => [error];
}