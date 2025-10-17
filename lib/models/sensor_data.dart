class SensorData {
  final double temperature;
  final double turbidity;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.turbidity,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'turbidity': turbidity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: json['temperature'] as double,
      turbidity: json['turbidity'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

enum HeaterMode { auto, manual }

enum HeaterStatus { on, off }

class HeaterState {
  final HeaterStatus status;
  final HeaterMode mode;

  HeaterState({
    required this.status,
    required this.mode,
  });

  HeaterState copyWith({
    HeaterStatus? status,
    HeaterMode? mode,
  }) {
    return HeaterState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
    );
  }
}
