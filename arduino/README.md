# 🐠 Aquarium Heater Control System - Arduino Setup Guide

## 📋 Daftar Komponen Yang Dibutuhkan

### Hardware:
1. **ESP32 DevKit** (atau varian lainnya)
2. **Sensor Suhu DS18B20** (waterproof)
3. **Sensor Turbidity Digital** (dengan output DO/Digital Out)
4. **Relay Module 5V** (1 channel)
5. **Heater Aquarium** (sesuai ukuran akuarium)
6. **Resistor 4.7kΩ** (untuk pull-up DS18B20)
7. **Kabel jumper**
8. **Power Supply 5V** untuk ESP32

### Software:
1. **Arduino IDE** (versi 1.8.x atau 2.x)
2. **Library yang dibutuhkan** (dijelaskan di bawah)

---

## 🔧 Instalasi Arduino IDE

### 1. Download dan Install Arduino IDE
- Download dari: https://www.arduino.cc/en/software
- Install sesuai dengan sistem operasi Anda

### 2. Install ESP32 Board Manager
1. Buka Arduino IDE
2. File → Preferences
3. Tambahkan URL berikut ke **Additional Board Manager URLs**:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
4. Tools → Board → Boards Manager
5. Cari "esp32" dan install **esp32 by Espressif Systems**

---

## 📚 Instalasi Library Yang Dibutuhkan

### Melalui Library Manager:
1. Sketch → Include Library → Manage Libraries
2. Cari dan install library berikut:

| Library | Versi | Deskripsi |
|---------|-------|-----------|
| **PubSubClient** | Latest | MQTT Client |
| **OneWire** | Latest | Komunikasi sensor DS18B20 |
| **DallasTemperature** | Latest | Driver sensor DS18B20 |

### Library yang Sudah Built-in:
- WiFi (sudah termasuk dalam ESP32 board)
- Preferences (sudah termasuk dalam ESP32 board)
- esp_task_wdt (sudah termasuk dalam ESP32 board)

---

## 🔌 Skema Koneksi Hardware

```
ESP32 PIN          →  KOMPONEN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GPIO 21            →  DS18B20 Data Pin
                      (+ 4.7kΩ pull-up ke 3.3V)

GPIO 34            →  Turbidity Sensor DO Pin

GPIO 4             →  Relay Module IN Pin

GPIO 2 (Built-in)  →  LED Indicator (optional)

GND                →  Ground (semua komponen)

3.3V/5V            →  Power supply untuk sensor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Detail Koneksi DS18B20:
```
DS18B20                ESP32
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Red (VDD)      →      3.3V
Yellow (Data)  →      GPIO 21 (+ resistor 4.7kΩ ke 3.3V)
Black (GND)    →      GND
```

### Detail Koneksi Turbidity Sensor Digital:
```
Turbidity Sensor       ESP32
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VCC            →      5V
GND            →      GND
DO (Digital)   →      GPIO 34
```

### Detail Koneksi Relay:
```
Relay Module           ESP32        Heater
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VCC            →      5V
GND            →      GND
IN             →      GPIO 4
COM            →                     AC Live (from plug)
NO (Normal Open)→                    Heater Input
```

⚠️ **PERINGATAN KESELAMATAN:**
- Relay bekerja dengan listrik AC 220V
- Pastikan instalasi listrik dilakukan dengan benar
- Gunakan box/casing waterproof untuk komponen elektronik
- Jangan sentuh komponen saat terhubung ke listrik

---

## ⚙️ Konfigurasi Program

### 1. Buka File Arduino
Buka file `aquarium_heater_full.ino` di Arduino IDE

### 2. Konfigurasi WiFi
Ubah kredensial WiFi Anda:
```cpp
const char* ssid = "NAMA_WIFI_ANDA";          // ← Ganti dengan nama WiFi
const char* password = "PASSWORD_WIFI_ANDA";   // ← Ganti dengan password WiFi
```

### 3. Konfigurasi MQTT (Opsional)
Jika menggunakan MQTT broker sendiri:
```cpp
const char* mqtt_server = "broker.hivemq.com";  // ← Ganti dengan broker Anda
const int mqtt_port = 1883;
const char* mqtt_user = "";                      // Jika ada username
const char* mqtt_password = "";                  // Jika ada password
```

### 4. Konfigurasi Pin (Opsional)
Jika menggunakan pin yang berbeda:
```cpp
#define ONE_WIRE_BUS 21        // Pin DS18B20
#define TURBIDITY_PIN 34       // Pin Turbidity Sensor
#define RELAY_PIN 4            // Pin Relay
```

### 5. Konfigurasi Threshold Suhu
Sesuaikan dengan jenis ikan Anda:
```cpp
const float TEMP_HIGH = 30.0;  // Suhu maksimal (°C)
const float TEMP_LOW = 27.0;   // Suhu minimal (°C)
```

#### Referensi Suhu Ikan Tropis:
| Jenis Ikan | Suhu Ideal | TEMP_LOW | TEMP_HIGH |
|------------|------------|----------|-----------|
| Guppy | 24-28°C | 24.0 | 28.0 |
| Molly | 25-28°C | 25.0 | 28.0 |
| Neon Tetra | 20-26°C | 20.0 | 26.0 |
| Betta | 24-30°C | 24.0 | 30.0 |
| Goldfish | 18-22°C | 18.0 | 22.0 |

---

## 📤 Upload Program ke ESP32

### 1. Hubungkan ESP32 ke Komputer
- Gunakan kabel USB
- Pastikan driver CH340/CP2102 sudah terinstall

### 2. Pilih Board dan Port
- Tools → Board → ESP32 Arduino → **ESP32 Dev Module**
- Tools → Port → Pilih port COM ESP32 Anda
- Tools → Upload Speed → **115200**

### 3. Upload Program
- Klik tombol **Upload** (→) atau Ctrl+U
- Tunggu sampai selesai
- Jika error "Failed to connect", tekan dan tahan tombol **BOOT** saat upload

### 4. Monitor Serial
- Tools → Serial Monitor
- Set Baud Rate ke **115200**
- Lihat output koneksi dan status sistem

---

## 🧪 Testing Program

### 1. Test Koneksi WiFi
Setelah upload, buka Serial Monitor dan lihat:
```
╔════════════════════════════════════════════════╗
║ ✅ WiFi CONNECTED!                            ║
╠════════════════════════════════════════════════╣
║ IP Address: 192.168.x.x
║ Signal Strength: -45 dBm
╚════════════════════════════════════════════════╝
```

### 2. Test Koneksi MQTT
```
🔌 Attempting MQTT connection... ✅ CONNECTED!
📡 Subscribed to control & calibrate topics
```

### 3. Test Sensor Suhu
Celupkan sensor DS18B20 ke dalam air:
```
║ 🌡️  Suhu Air    : 28.50 °C
```

### 4. Test Sensor Turbidity
Output akan menampilkan:
```
║ 💧 Turbidity   : JERNIH ✓ (Pin: HIGH)
```
atau
```
║ 💧 Turbidity   : KERUH  ✗ (Pin: LOW)
```

### 5. Test Relay Heater
- Mode Auto: Heater akan ON/OFF otomatis berdasarkan suhu
- Mode Manual: Kontrol via aplikasi Flutter

---

## 🐛 Troubleshooting

### Problem: ESP32 tidak terdeteksi
**Solusi:**
- Install driver CH340 atau CP2102
- Coba port USB lain
- Restart Arduino IDE

### Problem: WiFi tidak connect
**Solusi:**
- Cek SSID dan password
- Pastikan WiFi 2.4GHz (bukan 5GHz)
- Dekatkan ESP32 ke router

### Problem: MQTT tidak connect
**Solusi:**
- Cek koneksi internet
- Coba broker lain (test.mosquitto.org)
- Periksa firewall

### Problem: Sensor DS18B20 tidak terbaca
**Solusi:**
- Cek koneksi kabel
- Pastikan resistor pull-up 4.7kΩ terpasang
- Test dengan contoh program OneWire

### Problem: Relay tidak switching
**Solusi:**
- Cek koneksi pin
- Test dengan digitalWrite(RELAY_PIN, HIGH/LOW)
- Pastikan relay mendapat power 5V yang cukup

### Problem: Heater tidak menyala
**Solusi:**
- Cek koneksi relay ke heater
- Pastikan heater berfungsi (test langsung ke listrik)
- Cek status relay di Serial Monitor

---

## 📊 Monitor Data Real-time

### Via Serial Monitor:
```
╔════════════════════════════════════════════════╗
║         📊 STATUS SISTEM HEATER               ║
╠════════════════════════════════════════════════╣
║ 🌡️  Suhu Air    : 28.50 °C
║    Suhu Raw    : 28.45 °C
║    Offset      : 0.05 °C
╠════════════════════════════════════════════════╣
║ 💧 Turbidity   : JERNIH ✓ (Pin: HIGH)
╠════════════════════════════════════════════════╣
║ 🔥 Heater      : ON  🔴
║ 🎮 Mode        : AUTO
╠════════════════════════════════════════════════╣
║ 📶 WiFi        : Connected (-45 dBm)
║ 🔌 MQTT        : Connected ✅
╚════════════════════════════════════════════════╝
```

### Via MQTT Explorer:
Download MQTT Explorer: http://mqtt-explorer.com/
1. Connect ke broker.hivemq.com
2. Subscribe ke topic: `heater/#`
3. Monitor semua data real-time

---

## 🔐 Fitur Keamanan

### 1. Watchdog Timer
- Otomatis restart jika ESP32 hang
- Timeout: 60 detik

### 2. Auto Reconnect
- WiFi auto-reconnect setiap 10 detik
- MQTT auto-reconnect setiap 5 detik

### 3. Will Message
- MQTT akan publish "offline" jika ESP32 terputus mendadak

### 4. Data Validation
- Validasi pembacaan sensor suhu
- Range check: -50°C sampai 100°C

---

## 📞 Support

Jika ada masalah atau pertanyaan:
1. Buka Serial Monitor dan screenshot error
2. Cek wiring/koneksi hardware
3. Test komponen satu per satu
4. Pastikan library sudah terinstall dengan benar

---

## 📝 Changelog

### Version 2.0 (Current)
- ✅ Digital turbidity sensor support
- ✅ Watchdog timer
- ✅ Auto reconnect WiFi & MQTT
- ✅ Heartbeat monitoring
- ✅ Will message for offline detection
- ✅ Improved stability
- ✅ Better error handling

### Version 1.0
- Initial release
- Basic temperature control
- Analog turbidity sensor

---

## ⚖️ License

MIT License - Free to use and modify

---

## 🙏 Credits

- ESP32 Arduino Core by Espressif
- PubSubClient by Nick O'Leary
- OneWire & DallasTemperature by Miles Burton

---

**Happy Coding! 🚀**
