import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'BASE_API_URL', obfuscate: true)
  static final String baseApiUrl = _Env.baseApiUrl;
}