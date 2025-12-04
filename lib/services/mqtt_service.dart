import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  // MQTT Configuration - sesuai dengan ESP32
  static const String broker = 'broker.hivemq.com';
  static const int port = 1883;
  
  // Generate unique client ID untuk menghindari konflik dengan ESP32
  late final String clientId;

  // Topics - sesuai dengan ESP32
  static const String topicTemp = 'heater/temperature';
  static const String topicTurbidity = 'heater/turbidity';
  static const String topicStatus = 'heater/status';
  static const String topicControl = 'heater/control';
  static const String topicCalibrate = 'heater/calibrate';
  static const String topicCalTurbidity = 'heater/calibrate/turbidity';

  MqttServerClient? _client;
  Timer? _reconnectTimer;
  Timer? _connectionCheckTimer;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  
  // Stream controllers untuk data sensor
  final _temperatureController = StreamController<double>.broadcast();
  final _turbidityStatusController = StreamController<String>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _calibrationResponseController = StreamController<String>.broadcast();
  final _logController = StreamController<String>.broadcast();

  // Getters untuk streams
  Stream<double> get temperatureStream => _temperatureController.stream;
  Stream<String> get turbidityStatusStream => _turbidityStatusController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<String> get calibrationResponseStream => _calibrationResponseController.stream;
  Stream<String> get logStream => _logController.stream;

  // Data terakhir
  double _lastTemperature = 0.0;
  String _lastTurbidityStatus = 'UNKNOWN';
  String _lastStatus = 'OFF';
  bool _isConnected = false;

  double get lastTemperature => _lastTemperature;
  String get lastTurbidityStatus => _lastTurbidityStatus;
  String get lastStatus => _lastStatus;
  bool get isConnected => _isConnected;

  // Singleton pattern
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  
  MqttService._internal() {
    // Generate unique client ID with timestamp and random number
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000);
    clientId = 'FlutterApp_$random';
    _log('MQTT Client ID: $clientId');
  }

  void _log(String message) {
    print(message);
    _logController.add(message);
  }

  Future<bool> connect() async {
    try {
      // Disconnect jika sudah ada koneksi
      if (_client != null) {
        try {
          _client!.disconnect();
        } catch (e) {
          _log('Error disconnecting previous client: $e');
        }
      }

      _client = MqttServerClient.withPort(broker, clientId, port);
      _client!.logging(on: false);  // Disable logging untuk production
      _client!.keepAlivePeriod = 20;  // Keep alive period untuk Android
      _client!.autoReconnect = true;  // Enable auto reconnect
      _client!.resubscribeOnAutoReconnect = true;  // Resubscribe on reconnect
      _client!.onDisconnected = _onDisconnected;
      _client!.onConnected = _onConnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.onAutoReconnect = _onAutoReconnect;
      _client!.onAutoReconnected = _onAutoReconnected;
      _client!.pongCallback = _pong;
      
      // Set connection timeout untuk mobile
      _client!.connectTimeoutPeriod = 5000;  // 5 seconds timeout

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()  // Clean session
          .keepAliveFor(20)  // Keep alive 20 seconds untuk Android
          .withWillTopic('heater/status')
          .withWillMessage('offline')
          .withWillQos(MqttQos.atLeastOnce);
      
      _client!.connectionMessage = connMessage;

      _log('🔌 Connecting to MQTT broker: $broker:$port');
      _log('📱 Client ID: $clientId');
      
      await _client!.connect();

      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        _log('✅ MQTT client connected successfully!');
        
        // Subscribe ke topics dengan delay
        await Future.delayed(const Duration(milliseconds: 500));
        _subscribeToTopics();

        // Listen untuk messages
        _client!.updates!.listen(
          _onMessage,
          onError: (dynamic error) {
            _log('❌ Stream error: $error');
          },
          cancelOnError: false,
        );

        _isConnected = true;
        _connectionController.add(true);
        _reconnectAttempts = 0; // Reset on successful connection
        
        // Start periodic connection check
        _startConnectionCheck();
        
        return true;
      } else {
        _log('❌ MQTT connection failed - Status: ${_client!.connectionStatus}');
        _isConnected = false;
        _connectionController.add(false);
        return false;
      }
    } catch (e, stackTrace) {
      _log('❌ Exception during connect: $e');
      print('Stack trace: $stackTrace');
      _isConnected = false;
      _connectionController.add(false);
      
      // Retry connection after delay
      _scheduleReconnect();
      return false;
    }
  }

  void _subscribeToTopics() {
    _log('📡 Subscribing to topics...');
    _client!.subscribe(topicTemp, MqttQos.atMostOnce);
    _client!.subscribe(topicTurbidity, MqttQos.atMostOnce);
    _client!.subscribe(topicStatus, MqttQos.atMostOnce);
    _client!.subscribe(topicCalibrate, MqttQos.atMostOnce);
    _client!.subscribe(topicCalTurbidity, MqttQos.atMostOnce);
  }

  void _scheduleReconnect() {
    if (_isReconnecting) return;
    
    // Check if max attempts reached
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('⚠️ Max reconnect attempts reached. Resetting counter...');
      _reconnectAttempts = 0;
      // Wait longer before trying again
      Future.delayed(const Duration(seconds: 10), () {
        _scheduleReconnect();
      });
      return;
    }
    
    _isReconnecting = true;
    _reconnectAttempts++;
    _log('⏳ Scheduling reconnect (attempt $_reconnectAttempts/$_maxReconnectAttempts) in 3 seconds...');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () async {
      _isReconnecting = false;
      _log('🔄 Attempting to reconnect...');
      try {
        final success = await connect();
        if (success) {
          _reconnectAttempts = 0; // Reset counter on success
        }
      } catch (e) {
        _log('❌ Reconnect failed: $e');
      }
    });
  }
  
  void _startConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_client == null || _client!.connectionStatus?.state != MqttConnectionState.connected) {
        _log('⚠️ Connection check: Not connected. Attempting reconnect...');
        if (!_isReconnecting) {
          _scheduleReconnect();
        }
      } else {
        _log('✅ Connection check: Connected');
      }
    });
  }

  void _onAutoReconnect() {
    _log('🔄 Auto reconnecting...');
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onAutoReconnected() {
    _log('✅ Auto reconnected!');
    _isConnected = true;
    _connectionController.add(true);
    _subscribeToTopics();
  }

  void _onConnected() {
    _log('✅ MQTT Connected callback triggered');
    _isConnected = true;
    _connectionController.add(true);
  }

  void _onDisconnected() {
    _log('⚠️ MQTT Disconnected callback triggered');
    _isConnected = false;
    _connectionController.add(false);
    
    // Schedule reconnect if not manually disconnected
    if (_client != null) {
      _scheduleReconnect();
    }
  }

  void _onSubscribed(String topic) {
    _log('✅ Subscribed to topic: $topic');
  }

  void _pong() {
    // Ping response - connection is alive
    // print('🏓 Ping response received');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    try {
      final recMess = messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      _log('📩 ${messages[0].topic} = $payload');

      switch (messages[0].topic) {
        case topicTemp:
          final temp = double.tryParse(payload) ?? 0.0;
          _lastTemperature = temp;
          _temperatureController.add(temp);
          break;

        case topicTurbidity:
          _lastTurbidityStatus = payload;
          _turbidityStatusController.add(payload);
          break;

        case topicStatus:
          _lastStatus = payload;
          _statusController.add(payload);
          break;

        case topicCalibrate:
        case topicCalTurbidity:
          _calibrationResponseController.add(payload);
          break;
      }
    } catch (e) {
      _log('❌ Error processing message: $e');
    }
  }

  // Kontrol heater
  void turnOnHeater() {
    _publishMessage(topicControl, 'ON');
  }

  void turnOffHeater() {
    _publishMessage(topicControl, 'OFF');
  }

  void setAutoMode() {
    _publishMessage(topicControl, 'AUTO');
  }

  // Kalibrasi suhu
  void calibrateTemperature(double referenceTemp) {
    _publishMessage(topicCalibrate, 'CAL:$referenceTemp');
  }

  void resetTemperatureCalibration() {
    _publishMessage(topicCalibrate, 'RESET');
  }

  // Kalibrasi turbidity
  void calibrateTurbidityClear() {
    _publishMessage(topicCalTurbidity, 'CLEAR');
  }

  void calibrateTurbidityTurbid() {
    _publishMessage(topicCalTurbidity, 'TURBID:3000');
  }

  void resetTurbidityCalibration() {
    _publishMessage(topicCalTurbidity, 'RESET');
  }

  void getTurbidityCalibrationStatus() {
    _publishMessage(topicCalTurbidity, 'STATUS');
  }

  void _publishMessage(String topic, String message) {
    try {
      if (_client != null && _client!.connectionStatus!.state == MqttConnectionState.connected) {
        final builder = MqttClientPayloadBuilder();
        builder.addString(message);
        _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
        _log('📤 $topic = $message');
      } else {
        _log('❌ Cannot publish, MQTT not connected');
      }
    } catch (e) {
      _log('❌ Error publishing: $e');
    }
  }

  void disconnect() {
    _log('🔌 Manually disconnecting MQTT...');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
    _client?.disconnect();
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    _log('🗑️ Disposing MQTT service...');
    _reconnectTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _temperatureController.close();
    _turbidityStatusController.close();
    _statusController.close();
    _connectionController.close();
    _calibrationResponseController.close();
    _logController.close();
    _client?.disconnect();
  }
}
