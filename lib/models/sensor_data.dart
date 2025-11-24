// Enum untuk status turbidity digital
enum TurbidityStatus {
  jernih,  // Air JERNIH (sensor HIGH)
  keruh,   // Air KERUH (sensor LOW)
  unknown; // Status belum diketahui
  
  String get displayName {
    switch (this) {
      case TurbidityStatus.jernih:
        return 'JERNIH ✓';
      case TurbidityStatus.keruh:
        return 'KERUH ✗';
      case TurbidityStatus.unknown:
        return 'UNKNOWN';
    }
  }
  
  String get shortName {
    switch (this) {
      case TurbidityStatus.jernih:
        return 'JERNIH';
      case TurbidityStatus.keruh:
        return 'KERUH';
      case TurbidityStatus.unknown:
        return 'UNKNOWN';
    }
  }
  
  static TurbidityStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'JERNIH':
        return TurbidityStatus.jernih;
      case 'KERUH':
        return TurbidityStatus.keruh;
      default:
        return TurbidityStatus.unknown;
    }
  }
}

class SensorData {
  final double temperature;
  final TurbidityStatus turbidityStatus;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.turbidityStatus,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'turbidityStatus': turbidityStatus.shortName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: json['temperature'] as double,
      turbidityStatus: TurbidityStatus.fromString(json['turbidityStatus'] as String),
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
