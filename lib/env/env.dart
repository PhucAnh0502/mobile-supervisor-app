import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'BASE_API_URL', obfuscate: true)
  static final String baseApiUrl = _Env.baseApiUrl;
  @EnviedField(varName: 'MQTT_BROKER_URL', obfuscate: true)
  static final String mqttBrokerUrl = _Env.mqttBrokerUrl;
  @EnviedField(varName: 'MQTT_BROKER_PORT', obfuscate: true)
  static final int mqttBrokerPort = _Env.mqttBrokerPort;
}