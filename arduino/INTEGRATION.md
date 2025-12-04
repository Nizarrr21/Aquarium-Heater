# 🔗 Sistem Integrasi - Arduino ESP32 & Flutter App

## 📡 Arsitektur Sistem

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│                 │         │                  │         │                 │
│   ESP32 + IoT   │ ◄─────► │   MQTT Broker    │ ◄─────► │   Flutter App   │
│   Hardware      │  WiFi   │  (HiveMQ.com)    │ Internet│   (Android)     │
│                 │         │                  │         │                 │
└─────────────────┘         └──────────────────┘         └─────────────────┘
        │                                                          │
        │                                                          │
    Sensor & Relay                                          User Interface
    ┌───────────┐                                          ┌───────────────┐
    │ DS18B20   │                                          │ Dashboard     │
    │ Turbidity │                                          │ Monitoring    │
    │ Relay     │                                          │ Control       │
    └───────────┘                                          │ Calibration   │
                                                           └───────────────┘
```

---

## 📨 MQTT Topics Structure

### Published by ESP32 (ke Broker):

| Topic | Type | Format | Contoh | Update Rate |
|-------|------|--------|--------|-------------|
| `heater/temperature` | Data | Float String | "28.50" | 2 detik |
| `heater/turbidity` | Status | String | "JERNIH" atau "KERUH" | 2 detik |
| `heater/status` | Status | String | "ON" atau "OFF" atau "AUTO" | On change |
| `heater/heartbeat` | Info | String | "uptime:1234,rssi:-45" | 30 detik |

### Subscribed by ESP32 (dari Broker):

| Topic | Type | Format | Contoh | Deskripsi |
|-------|------|--------|--------|-----------|
| `heater/control` | Command | String | "ON", "OFF", "AUTO" | Kontrol manual heater |
| `heater/calibrate` | Command | String | "CAL:28.5" atau "RESET" | Kalibrasi suhu |

### Response dari ESP32:

| Topic | Response | Format | Contoh |
|-------|----------|--------|--------|
| `heater/calibrate` | Status | String | "OK:Offset=0.50" |
| `heater/status` | Retained | String | "online" atau "offline" |

---

## 🔄 Flow Komunikasi

### 1. Startup Sequence

```
ESP32                          MQTT Broker                    Flutter App
  │                                 │                              │
  ├──[1] Connect WiFi               │                              │
  │                                 │                              │
  ├──[2] Connect MQTT───────────────►                              │
  │         (with will: offline)    │                              │
  │                                 │                              │
  ├──[3] Subscribe topics           │                              │
  │     - heater/control            │                              │
  │     - heater/calibrate          │                              │
  │                                 │                              │
  ├──[4] Publish "online"───────────►────────────[Subscribe]──────►│
  │                                 │                              │
  └──[5] Start publishing data──────►────────────[Receive]─────────►│
```

### 2. Normal Operation

```
ESP32                          MQTT Broker                    Flutter App
  │                                 │                              │
  ├──[Read Sensors]                 │                              │
  │   • Temperature: 28.5°C         │                              │
  │   • Turbidity: JERNIH           │                              │
  │                                 │                              │
  ├──[Auto Control Logic]           │                              │
  │   • If temp < 27°C → ON         │                              │
  │   • If temp > 30°C → OFF        │                              │
  │                                 │                              │
  ├──[Publish Data]─────────────────►────────────[Update UI]──────►│
  │   • heater/temperature          │                              │
  │   • heater/turbidity            │                              │
  │   • heater/status               │                              │
  │                                 │                              │
  │                                 │                              │
  │                           [User Tap Button]                    │
  │                                 │◄─────────[Publish]───────────┤
  │                                 │   "heater/control: ON"       │
  │                                 │                              │
  │◄──[Receive Command]─────────────┤                              │
  │   "ON"                          │                              │
  │                                 │                              │
  ├──[Execute: Turn ON Relay]       │                              │
  │                                 │                              │
  └──[Publish Status]───────────────►────────────[Confirm]─────────►│
      "heater/status: ON"           │                              │
```

### 3. Calibration Flow

```
Flutter App                    MQTT Broker                    ESP32
     │                              │                            │
     ├──[User Input: 28.5°C]        │                            │
     │                              │                            │
     ├──[Publish]───────────────────►───────────[Receive]────────►│
     │  "heater/calibrate:          │                            │
     │   CAL:28.5"                  │                            │
     │                              │                            │
     │                              │         [Calculate Offset] │
     │                              │         • Raw: 28.45°C     │
     │                              │         • Ref: 28.5°C      │
     │                              │         • Offset: 0.05°C   │
     │                              │                            │
     │                              │         [Save to Memory]   │
     │                              │                            │
     │                              │◄──────[Publish Response]───┤
     │                              │   "OK:Offset=0.05"         │
     │                              │                            │
     │◄─────[Receive Confirm]───────┤                            │
     │  "OK:Offset=0.05"            │                            │
     │                              │                            │
     └──[Show Success Message]      │                            │
```

### 4. Reconnection Flow

```
ESP32                          MQTT Broker                    Flutter App
  │                                 │                              │
  │                                 │                              │
  ├──[Detect Disconnect]            │                              │
  │   • WiFi lost                   │                              │
  │   • MQTT timeout                │                              │
  │                                 │                              │
  ├──[Auto Reconnect WiFi]          │                              │
  │   • Every 10 seconds            │                              │
  │                                 │                              │
  ├──[WiFi Connected]               │                              │
  │                                 │                              │
  ├──[Auto Reconnect MQTT]──────────►                              │
  │   • Every 5 seconds             │                              │
  │                                 │                              │
  ├──[MQTT Connected]               │                              │
  │                                 │                              │
  ├──[Resubscribe Topics]           │                              │
  │                                 │                              │
  ├──[Publish "online"]─────────────►────────────[Detect]─────────►│
  │                                 │         Connection Restored  │
  │                                 │                              │
  └──[Resume Normal Operation]──────►────────────[Update UI]──────►│
```

---

## 🔧 Troubleshooting Integration

### Problem: Flutter App tidak menerima data

**Diagnosis:**
1. Cek koneksi internet di smartphone
2. Cek status MQTT di app (harus "Online")
3. Buka Serial Monitor ESP32, lihat apakah data di-publish

**Solusi:**
```dart
// Di Flutter, pastikan menggunakan broker yang sama
static const String broker = 'broker.hivemq.com';
static const int port = 1883;
```

```cpp
// Di Arduino, pastikan sama
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;
```

### Problem: ESP32 publish data tapi Flutter tidak update

**Diagnosis:**
1. Cek topik MQTT (harus sama persis)
2. Test dengan MQTT Explorer untuk melihat data real-time

**Solusi:**
- Pastikan tidak ada typo di topic names
- Flutter harus subscribe ke semua topic yang di-publish ESP32

### Problem: Command dari Flutter tidak sampai ke ESP32

**Diagnosis:**
1. Buka Serial Monitor ESP32
2. Cek apakah ESP32 menerima callback
3. Periksa subscribe topics di ESP32

**Solusi:**
```cpp
// ESP32 harus subscribe ke:
client.subscribe(topic_control);
client.subscribe(topic_calibrate);
```

```dart
// Flutter harus publish ke:
_publishMessage(topicControl, 'ON');
_publishMessage(topicCalibrate, 'CAL:28.5');
```

### Problem: Connection tidak stabil

**Diagnosis:**
1. Cek kualitas WiFi (RSSI di Serial Monitor)
2. Cek jarak ESP32 ke router
3. Monitor Serial untuk disconnect events

**Solusi:**
- Increase keepAlive period (sudah diset 60 detik)
- Pastikan power supply ESP32 stabil (min 500mA)
- Gunakan WiFi 2.4GHz (bukan 5GHz)
- Hindari obstacle antara ESP32 dan router

---

## 📊 Testing dengan MQTT Explorer

### Install MQTT Explorer
Download: http://mqtt-explorer.com/

### Setup Connection
```
Connection Name: Aquarium Heater
Protocol: mqtt://
Host: broker.hivemq.com
Port: 1883
Username: (kosongkan)
Password: (kosongkan)
```

### Monitor Topics
Subscribe ke: `heater/#`

Anda akan melihat:
```
heater/
├── temperature     → "28.50"
├── turbidity       → "JERNIH"
├── status          → "ON"
├── heartbeat       → "uptime:1234,rssi:-45"
├── control         → (publish untuk test)
└── calibrate       → (publish untuk test)
```

### Test Manual Control
1. Klik topic `heater/control`
2. Publish message: `ON` atau `OFF` atau `AUTO`
3. Lihat perubahan di Serial Monitor ESP32

### Test Calibration
1. Klik topic `heater/calibrate`
2. Publish message: `CAL:28.5`
3. Lihat response di topic `heater/calibrate`

---

## 🎯 Best Practices

### 1. Gunakan QoS yang Tepat
```cpp
// Untuk status penting (retained)
client.publish(topic_status, "online", true);  // QoS 1, retained

// Untuk data sensor (tidak perlu retained)
client.publish(topic_temp, tempStr);  // QoS 0
```

### 2. Set Retained Flag untuk Status
```cpp
// Status heater harus retained agar app langsung dapat status terakhir
client.publish(topic_status, heaterStatus ? "ON" : "OFF", true);
```

### 3. Validate Data Sebelum Kirim
```cpp
// Validasi suhu
if (rawTemp == DEVICE_DISCONNECTED_C || rawTemp < -50 || rawTemp > 100) {
    Serial.println("⚠️  WARNING: Invalid temperature reading!");
    return;  // Jangan publish data invalid
}
```

### 4. Handle Reconnection Gracefully
```cpp
// Jangan spam reconnect
if (now - lastReconnectAttempt > reconnectInterval) {
    lastReconnectAttempt = now;
    if (reconnect()) {
        lastReconnectAttempt = 0;
    }
}
```

### 5. Use Watchdog Timer
```cpp
// Reset watchdog di loop
esp_task_wdt_reset();
```

---

## 📈 Performance Metrics

### Expected Values:

| Metric | Value | Notes |
|--------|-------|-------|
| Publish Rate | 2 detik | Data sensor |
| MQTT Latency | < 100ms | Dalam kondisi normal |
| WiFi Signal | > -70 dBm | RSSI |
| Reconnect Time | < 5 detik | WiFi + MQTT |
| Uptime | > 24 jam | Dengan watchdog |

### Monitor Performance:
```cpp
// Lihat di Serial Monitor
║ 📶 WiFi        : Connected (-45 dBm)  ← Signal strength
║ 🔌 MQTT        : Connected ✅          ← MQTT status
```

```cpp
// Heartbeat message
uptime:86400,rssi:-45  ← 24 jam uptime, -45 dBm signal
```

---

## 🔐 Security Recommendations

### 1. Untuk Production:
- Gunakan MQTT broker private (bukan public)
- Enable authentication (username/password)
- Gunakan TLS/SSL encryption
- Set topic permissions

### 2. Example dengan Authentication:
```cpp
const char* mqtt_user = "your_username";
const char* mqtt_password = "your_password";

client.connect(clientId.c_str(), mqtt_user, mqtt_password);
```

### 3. Private MQTT Broker:
- Mosquitto (self-hosted)
- CloudMQTT (cloud)
- AWS IoT Core
- Azure IoT Hub

---

## 📞 Support & Debugging

### Enable Debug Mode:
```cpp
// Di Arduino
_client!.logging(on: true);  // MQTT debug

// Di Serial Monitor
Set Baud Rate: 115200
```

### Common Error Messages:

| Error | Meaning | Solution |
|-------|---------|----------|
| `rc=-2` | Connection refused | Cek broker address |
| `rc=-4` | Connection timeout | Cek internet/WiFi |
| `DEVICE_DISCONNECTED_C` | DS18B20 error | Cek wiring sensor |
| `Failed to connect` | WiFi error | Cek SSID/password |

---

**System Status: ✅ Ready for Production!**
