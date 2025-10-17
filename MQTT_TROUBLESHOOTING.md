# MQTT Connection Troubleshooting Guide

## ✅ Checklist Koneksi MQTT

### 1. Periksa Koneksi Internet
```bash
# Test koneksi ke broker
ping broker.hivemq.com
```

Dari HP Android:
- Buka browser, akses https://www.google.com
- Pastikan bisa browsing normal
- Cek WiFi atau Data Cellular aktif

### 2. Client ID Conflict
**MASALAH UTAMA**: Jika ESP32 dan Flutter menggunakan Client ID yang sama, salah satu akan ter-disconnect terus.

**SOLUSI**: 
- ESP32 menggunakan: `ESP32_Heater`
- Flutter menggunakan: `FlutterApp_XXXX` (unique dengan timestamp)

Pastikan ESP32 running dengan Client ID berbeda!

### 3. Broker Accessibility
Test dari terminal/cmd:
```bash
# Test port 1883 (MQTT)
telnet broker.hivemq.com 1883
```

Jika tidak bisa connect:
- Firewall blocking port 1883
- ISP blocking MQTT port
- Gunakan alternatif broker atau port 8883 (MQTT over TLS)

### 4. Android Permissions
File: `android/app/src/main/AndroidManifest.xml`

Pastikan ada:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>

<application
    ...
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config">
```

### 5. Network Security Config
File: `android/app/src/main/res/xml/network_security_config.xml`

Pastikan file ini exists dan berisi:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

## 🔧 Troubleshooting Steps

### Problem: Connection terus terputus (Disconnect loop)

**Kemungkinan Penyebab:**

1. **Client ID sama dengan ESP32**
   - Check log: cari "MQTT Client ID"
   - Pastikan bukan "ESP32_Heater"
   - Seharusnya "FlutterApp_XXXX"

2. **Keep-Alive timeout**
   - Sudah diset ke 30 detik
   - Broker bisa disconnect jika tidak ada activity

3. **Network instability**
   - Switch antara WiFi dan Data
   - Sinyal lemah
   - Firewall/NAT issues

4. **Broker overload**
   - broker.hivemq.com public broker, kadang overload
   - Coba alternatif: `test.mosquitto.org`

**Solusi:**

```dart
// Di mqtt_service.dart sudah diset:
_client!.keepAlivePeriod = 30;
_client!.autoReconnect = true;
_client!.resubscribeOnAutoReconnect = true;
_client!.connectTimeoutPeriod = 5000;
```

### Problem: Tidak bisa publish/subscribe

**Check:**
1. Connection status CONNECTED
2. Log menunjukkan "Subscribed to topic"
3. ESP32 sudah publish data

**Debug Commands:**

Lihat connection log di app:
- Scroll ke bawah untuk lihat log terbaru
- Hijau = Connected
- Merah = Error
- Orange = Disconnected

### Problem: Data tidak muncul di UI

**Check:**
1. ESP32 running dan publish data (check Serial Monitor)
2. Topics sama: `heater/temperature`, `heater/turbidity`, dll
3. Data format benar (number untuk temp/turbidity)

## 📝 Log Monitoring

### What to look for:

**Good Connection:**
```
🔌 Connecting to MQTT broker: broker.hivemq.com:1883
📱 Client ID: FlutterApp_1234
✅ MQTT client connected successfully!
📡 Subscribing to topics...
✅ Subscribed to topic: heater/temperature
✅ Subscribed to topic: heater/turbidity
✅ Subscribed to topic: heater/status
📩 heater/temperature = 28.5
📩 heater/turbidity = 150.25
```

**Connection Problems:**
```
❌ MQTT connection failed - Status: ...
⚠️ MQTT Disconnected callback triggered
⏳ Scheduling reconnect in 5 seconds...
🔄 Attempting to reconnect...
```

**Publishing Issues:**
```
❌ Cannot publish, MQTT not connected
```

## 🛠️ Advanced Debugging

### Enable detailed MQTT logging:

Di `mqtt_service.dart`:
```dart
_client!.logging(on: true);  // Already enabled
```

Console akan menunjukkan semua MQTT packets.

### Test dengan MQTT Client Desktop

Install MQTT Explorer atau MQTT.fx:
1. Connect ke broker.hivemq.com:1883
2. Subscribe ke topics: `heater/#`
3. Lihat apakah ESP32 publish data
4. Publish manual ke `heater/control` dengan value `ON`

Jika desktop client bisa tapi Flutter tidak:
- Android permission issue
- Network security config issue

### Alternative Brokers

Jika broker.hivemq.com bermasalah, coba:

1. **test.mosquitto.org** (port 1883)
2. **mqtt.eclipse.org** (port 1883)
3. **broker.emqx.io** (port 1883)

Ubah di `mqtt_service.dart`:
```dart
static const String broker = 'test.mosquitto.org';
```

Dan di ESP32:
```cpp
const char* mqtt_server = "test.mosquitto.org";
```

## 🔍 Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `MqttConnectionState.disconnected` | Network issue | Check internet, retry |
| `Socket exception` | Firewall/NAT | Check network security config |
| `Connection refused` | Broker down | Try alternative broker |
| `Client identifier rejected` | Client ID conflict | Restart app for new ID |
| `Keep alive failure` | Timeout | Already handled with auto-reconnect |

## 📱 Testing Checklist

- [ ] HP terhubung ke internet (WiFi/Data)
- [ ] Bisa buka browser dan google.com
- [ ] ESP32 running dan connected ke MQTT
- [ ] ESP32 Serial Monitor menunjukkan publish data
- [ ] App menunjukkan Client ID unique (bukan ESP32_Heater)
- [ ] Connection log menunjukkan "✅ connected"
- [ ] Data suhu dan turbidity muncul di UI

## 🚀 Quick Fixes

### Fix 1: Restart Everything
```bash
1. Stop ESP32
2. Close Flutter app completely
3. flutter clean
4. flutter pub get
5. flutter run
6. Start ESP32
```

### Fix 2: Change Broker
Update di kedua ESP32 dan Flutter:
```
broker.hivemq.com → test.mosquitto.org
```

### Fix 3: Rebuild App
```bash
flutter clean
flutter pub get
flutter build apk --release
flutter install
```

### Fix 4: Check ESP32
```cpp
// Di Serial Monitor ESP32, should see:
WiFi connected!
IP address: 192.168.x.x
Attempting MQTT connection...connected!
Subscribed to control & calibrate topics
--- Data Sensor ---
Suhu Air: 28.5 °C
Turbidity: 150.25 NTU
Status Heater: OFF
```

## 💡 Tips

1. **Keep app open** untuk maintain connection
2. **Monitor log** di app untuk troubleshoot
3. **Test di WiFi** dulu sebelum coba di Data
4. **Pastikan ESP32 running** sebelum buka app
5. **Wait 10-15 seconds** setelah connect untuk data muncul

---

Jika masih ada masalah, check:
1. Connection log di app
2. Serial Monitor ESP32
3. Test dengan MQTT client desktop
