/*
 * ═══════════════════════════════════════════════════════════════════════
 *   AQUARIUM HEATER CONTROL SYSTEM WITH TURBIDITY SENSOR
 *   ESP32 Based IoT System
 * ═══════════════════════════════════════════════════════════════════════
 *   Features:
 *   - Temperature monitoring (DS18B20)
 *   - Digital turbidity sensor monitoring
 *   - Automatic heater control
 *   - Manual control via MQTT
 *   - Temperature calibration
 *   - WiFi auto-reconnect
 *   - MQTT auto-reconnect
 * ═══════════════════════════════════════════════════════════════════════
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <Preferences.h>
#include <esp_task_wdt.h>

// ═══════════════════════════════════════════════════════════════════════
// WiFi Configuration
// ═══════════════════════════════════════════════════════════════════════
const char* ssid = "udin2";
const char* password = "12345678910";

// ═══════════════════════════════════════════════════════════════════════
// MQTT Configuration
// ═══════════════════════════════════════════════════════════════════════
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;
const char* mqtt_user = "";
const char* mqtt_password = "";
const char* mqtt_client_id = "ESP32_Heater_V2";

// ═══════════════════════════════════════════════════════════════════════
// MQTT Topics
// ═══════════════════════════════════════════════════════════════════════
const char* topic_temp = "heater/temperature";
const char* topic_turbidity = "heater/turbidity";
const char* topic_status = "heater/status";
const char* topic_control = "heater/control";
const char* topic_calibrate = "heater/calibrate";
const char* topic_heartbeat = "heater/heartbeat";

// ═══════════════════════════════════════════════════════════════════════
// Pin Configuration
// ═══════════════════════════════════════════════════════════════════════
#define ONE_WIRE_BUS 21        // Pin untuk DS18B20
#define TURBIDITY_PIN 34       // Pin DIGITAL untuk sensor turbidity (DO)
#define RELAY_PIN 4            // Pin untuk relay heater
#define LED_WIFI 2             // Pin LED indicator WiFi (Built-in LED)

// ═══════════════════════════════════════════════════════════════════════
// Setup sensor DS18B20
// ═══════════════════════════════════════════════════════════════════════
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

// ═══════════════════════════════════════════════════════════════════════
// Setup WiFi dan MQTT Client
// ═══════════════════════════════════════════════════════════════════════
WiFiClient espClient;
PubSubClient client(espClient);

// ═══════════════════════════════════════════════════════════════════════
// Preferences untuk menyimpan kalibrasi
// ═══════════════════════════════════════════════════════════════════════
Preferences preferences;

// ═══════════════════════════════════════════════════════════════════════
// Threshold suhu (Temperature Thresholds)
// ═══════════════════════════════════════════════════════════════════════
const float TEMP_HIGH = 30.0;  // Suhu maksimal (matikan heater)
const float TEMP_LOW = 27.0;   // Suhu minimal (nyalakan heater)

// ═══════════════════════════════════════════════════════════════════════
// Kalibrasi suhu
// ═══════════════════════════════════════════════════════════════════════
float tempOffset = 0.0;

// ═══════════════════════════════════════════════════════════════════════
// Status heater
// ═══════════════════════════════════════════════════════════════════════
bool heaterStatus = false;
bool manualControl = false;

// ═══════════════════════════════════════════════════════════════════════
// Status turbidity digital
// ═══════════════════════════════════════════════════════════════════════
bool isWaterClear = true;  // true = jernih (HIGH), false = keruh (LOW)

// ═══════════════════════════════════════════════════════════════════════
// Timing variables
// ═══════════════════════════════════════════════════════════════════════
unsigned long lastPublish = 0;
unsigned long lastReconnectAttempt = 0;
unsigned long lastWiFiCheck = 0;
unsigned long lastHeartbeat = 0;
const long publishInterval = 2000;      // Publish setiap 2 detik
const long reconnectInterval = 5000;    // Reconnect setiap 5 detik
const long wifiCheckInterval = 10000;   // Check WiFi setiap 10 detik
const long heartbeatInterval = 30000;   // Heartbeat setiap 30 detik

// ═══════════════════════════════════════════════════════════════════════
// Watchdog timer
// ═══════════════════════════════════════════════════════════════════════
#define WDT_TIMEOUT 60  // 60 seconds watchdog timeout

// ═══════════════════════════════════════════════════════════════════════
// SETUP FUNCTION
// ═══════════════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  // Configure watchdog timer (ESP32 Arduino Core 3.x)
  esp_task_wdt_config_t wdt_config = {
    .timeout_ms = WDT_TIMEOUT * 1000,  // Convert to milliseconds
    .idle_core_mask = 0,
    .trigger_panic = true
  };
  esp_task_wdt_init(&wdt_config);
  esp_task_wdt_add(NULL);
  
  // Inisialisasi pin
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(LED_WIFI, OUTPUT);
  pinMode(TURBIDITY_PIN, INPUT);
  
  digitalWrite(RELAY_PIN, LOW);   // Heater OFF saat startup
  digitalWrite(LED_WIFI, LOW);    // LED OFF
  
  // Inisialisasi sensor DS18B20
  sensors.begin();
  
  // Load kalibrasi dari memory
  preferences.begin("heater", false);
  tempOffset = preferences.getFloat("tempOffset", 0.0);
  preferences.end();
  
  printWelcomeBanner();
  
  // Koneksi WiFi
  setup_wifi();
  
  // Setup MQTT
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  client.setKeepAlive(60);
  client.setSocketTimeout(10);
  
  delay(1000);
  
  // Reset watchdog
  esp_task_wdt_reset();
}

// ═══════════════════════════════════════════════════════════════════════
// PRINT WELCOME BANNER
// ═══════════════════════════════════════════════════════════════════════
void printWelcomeBanner() {
  Serial.println();
  Serial.println("╔════════════════════════════════════════════════╗");
  Serial.println("║   ESP32 AQUARIUM HEATER CONTROL SYSTEM V2.0   ║");
  Serial.println("║        with Digital Turbidity Sensor          ║");
  Serial.println("╠════════════════════════════════════════════════╣");
  Serial.print("║ Temperature Offset: ");
  Serial.print(tempOffset);
  Serial.println(" °C");
  Serial.println("║ Turbidity Sensor: DIGITAL MODE                ║");
  Serial.println("║   - HIGH = Air JERNIH                         ║");
  Serial.println("║   - LOW  = Air KERUH                          ║");
  Serial.println("╠════════════════════════════════════════════════╣");
  Serial.print("║ Temp High Threshold: ");
  Serial.print(TEMP_HIGH);
  Serial.println(" °C");
  Serial.print("║ Temp Low Threshold:  ");
  Serial.print(TEMP_LOW);
  Serial.println(" °C");
  Serial.println("╚════════════════════════════════════════════════╝");
  Serial.println();
}

// ═══════════════════════════════════════════════════════════════════════
// WiFi SETUP
// ═══════════════════════════════════════════════════════════════════════
void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.println("╔════════════════════════════════════════════════╗");
  Serial.print("║ Connecting to WiFi: ");
  Serial.println(ssid);
  Serial.println("╚════════════════════════════════════════════════╝");
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    digitalWrite(LED_WIFI, !digitalRead(LED_WIFI));
    attempts++;
  }
  
  Serial.println();
  
  if (WiFi.status() == WL_CONNECTED) {
    digitalWrite(LED_WIFI, HIGH);
    Serial.println("╔════════════════════════════════════════════════╗");
    Serial.println("║ ✅ WiFi CONNECTED!                            ║");
    Serial.println("╠════════════════════════════════════════════════╣");
    Serial.print("║ IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("║ Signal Strength: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
    Serial.println("╚════════════════════════════════════════════════╝");
  } else {
    digitalWrite(LED_WIFI, LOW);
    Serial.println("╔════════════════════════════════════════════════╗");
    Serial.println("║ ❌ WiFi CONNECTION FAILED!                    ║");
    Serial.println("╚════════════════════════════════════════════════╝");
  }
  Serial.println();
}

// ═══════════════════════════════════════════════════════════════════════
// CHECK WiFi CONNECTION
// ═══════════════════════════════════════════════════════════════════════
void checkWiFi() {
  if (WiFi.status() != WL_CONNECTED) {
    digitalWrite(LED_WIFI, LOW);
    Serial.println("⚠️  WiFi disconnected! Reconnecting...");
    setup_wifi();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MQTT CALLBACK
// ═══════════════════════════════════════════════════════════════════════
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("📨 Message arrived [");
  Serial.print(topic);
  Serial.print("]: ");
  
  String message = "";
  for (unsigned int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.println(message);
  
  // Kontrol manual dari MQTT
  if (String(topic) == topic_control) {
    if (message == "ON") {
      digitalWrite(RELAY_PIN, HIGH);
      heaterStatus = true;
      manualControl = true;
      Serial.println("🔥 >>> HEATER ON (Manual Control)");
      client.publish(topic_status, "ON", true);
    } 
    else if (message == "OFF") {
      digitalWrite(RELAY_PIN, LOW);
      heaterStatus = false;
      manualControl = true;
      Serial.println("❄️  >>> HEATER OFF (Manual Control)");
      client.publish(topic_status, "OFF", true);
    }
    else if (message == "AUTO") {
      manualControl = false;
      Serial.println("🤖 >>> Mode AUTO Activated");
      client.publish(topic_status, "AUTO", true);
    }
  }
  
  // Kalibrasi suhu dari MQTT
  if (String(topic) == topic_calibrate) {
    if (message.startsWith("CAL:")) {
      float referenceTemp = message.substring(4).toFloat();
      
      // Baca suhu sensor saat ini (tanpa offset)
      sensors.requestTemperatures();
      float rawTemp = sensors.getTempCByIndex(0);
      
      // Hitung offset baru
      tempOffset = referenceTemp - rawTemp;
      
      // Simpan ke memory
      preferences.begin("heater", false);
      preferences.putFloat("tempOffset", tempOffset);
      preferences.end();
      
      Serial.println("╔════════════════════════════════════════════════╗");
      Serial.println("║           🔧 KALIBRASI SUHU                   ║");
      Serial.println("╠════════════════════════════════════════════════╣");
      Serial.print("║ Suhu Raw:       ");
      Serial.print(rawTemp);
      Serial.println(" °C");
      Serial.print("║ Suhu Referensi: ");
      Serial.print(referenceTemp);
      Serial.println(" °C");
      Serial.print("║ Offset Baru:    ");
      Serial.print(tempOffset);
      Serial.println(" °C");
      Serial.println("╚════════════════════════════════════════════════╝");
      
      String response = "OK:Offset=" + String(tempOffset, 2);
      client.publish(topic_calibrate, response.c_str(), true);
    }
    else if (message == "RESET") {
      tempOffset = 0.0;
      preferences.begin("heater", false);
      preferences.putFloat("tempOffset", 0.0);
      preferences.end();
      Serial.println("🔄 >>> Kalibrasi suhu direset ke 0");
      client.publish(topic_calibrate, "OK:Reset", true);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MQTT RECONNECT
// ═══════════════════════════════════════════════════════════════════════
boolean reconnect() {
  if (WiFi.status() != WL_CONNECTED) {
    return false;
  }
  
  Serial.print("🔌 Attempting MQTT connection... ");
  
  // Create a unique client ID
  String clientId = mqtt_client_id;
  clientId += String(random(0xffff), HEX);
  
  // Attempt to connect with will message
  if (client.connect(clientId.c_str(), mqtt_user, mqtt_password, 
                     topic_status, 1, true, "offline")) {
    Serial.println("✅ CONNECTED!");
    
    // Subscribe ke topics
    client.subscribe(topic_control);
    client.subscribe(topic_calibrate);
    Serial.println("📡 Subscribed to control & calibrate topics");
    
    // Publish status online
    client.publish(topic_status, "online", true);
    
    return true;
  } else {
    Serial.print("❌ FAILED, rc=");
    Serial.print(client.state());
    Serial.println();
    return false;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MAIN LOOP
// ═══════════════════════════════════════════════════════════════════════
void loop() {
  // Reset watchdog timer
  esp_task_wdt_reset();
  
  unsigned long now = millis();
  
  // Check WiFi connection periodically
  if (now - lastWiFiCheck > wifiCheckInterval) {
    lastWiFiCheck = now;
    checkWiFi();
  }
  
  // Handle MQTT connection
  if (!client.connected()) {
    if (now - lastReconnectAttempt > reconnectInterval) {
      lastReconnectAttempt = now;
      if (reconnect()) {
        lastReconnectAttempt = 0;
      }
    }
  } else {
    client.loop();
  }
  
  // Baca suhu dari DS18B20
  sensors.requestTemperatures();
  float rawTemp = sensors.getTempCByIndex(0);
  float temperature = rawTemp + tempOffset;
  
  // Validasi pembacaan suhu
  if (rawTemp == DEVICE_DISCONNECTED_C || rawTemp < -50 || rawTemp > 100) {
    Serial.println("⚠️  WARNING: Invalid temperature reading!");
    temperature = 0.0;
  }
  
  // Baca nilai turbidity DIGITAL
  // Sensor Turbidity Digital Output:
  //   HIGH (1) = Air JERNIH (sensor tidak mendeteksi partikel)
  //   LOW (0)  = Air KERUH (sensor mendeteksi partikel)
  int turbidityValue = digitalRead(TURBIDITY_PIN);
  
  // Update status air berdasarkan pembacaan digital
  if (turbidityValue == HIGH) {
    isWaterClear = true;   // Air JERNIH
  } else {
    isWaterClear = false;  // Air KERUH
  }
  
  // Logika kontrol heater otomatis (jika tidak dalam mode manual)
  if (!manualControl && temperature > 0) {
    if (temperature >= TEMP_HIGH && heaterStatus) {
      digitalWrite(RELAY_PIN, LOW);
      heaterStatus = false;
      Serial.println("🌡️  >>> HEATER OFF - Suhu terlalu tinggi");
      if (client.connected()) {
        client.publish(topic_status, "OFF", true);
      }
    } 
    else if (temperature <= TEMP_LOW && !heaterStatus) {
      digitalWrite(RELAY_PIN, HIGH);
      heaterStatus = true;
      Serial.println("🌡️  >>> HEATER ON - Suhu terlalu rendah");
      if (client.connected()) {
        client.publish(topic_status, "ON", true);
      }
    }
  }
  
  // Publish data ke MQTT setiap interval
  if (now - lastPublish > publishInterval) {
    lastPublish = now;
    
    if (client.connected()) {
      // Publish temperature
      char tempStr[10];
      dtostrf(temperature, 4, 2, tempStr);
      client.publish(topic_temp, tempStr);
      
      // Publish turbidity status
      if (isWaterClear) {
        client.publish(topic_turbidity, "JERNIH");
      } else {
        client.publish(topic_turbidity, "KERUH");
      }
      
      // Publish heater status
      client.publish(topic_status, heaterStatus ? "ON" : "OFF");
    }
    
    // Tampilkan data di Serial Monitor
    printStatusBox(temperature, rawTemp, turbidityValue);
  }
  
  // Send heartbeat
  if (now - lastHeartbeat > heartbeatInterval) {
    lastHeartbeat = now;
    if (client.connected()) {
      char heartbeat[50];
      snprintf(heartbeat, sizeof(heartbeat), "uptime:%lu,rssi:%d", 
               millis()/1000, WiFi.RSSI());
      client.publish(topic_heartbeat, heartbeat);
    }
  }
  
  delay(100);
}

// ═══════════════════════════════════════════════════════════════════════
// PRINT STATUS BOX
// ═══════════════════════════════════════════════════════════════════════
void printStatusBox(float temperature, float rawTemp, int turbidityValue) {
  Serial.println();
  Serial.println("╔════════════════════════════════════════════════╗");
  Serial.println("║         📊 STATUS SISTEM HEATER               ║");
  Serial.println("╠════════════════════════════════════════════════╣");
  
  // Suhu Air
  Serial.print("║ 🌡️  Suhu Air    : ");
  Serial.print(temperature, 2);
  Serial.println(" °C");
  
  // Suhu Raw
  Serial.print("║    Suhu Raw    : ");
  Serial.print(rawTemp, 2);
  Serial.println(" °C");
  
  // Offset
  Serial.print("║    Offset      : ");
  Serial.print(tempOffset, 2);
  Serial.println(" °C");
  
  Serial.println("╠════════════════════════════════════════════════╣");
  
  // Turbidity
  Serial.print("║ 💧 Turbidity   : ");
  if (isWaterClear) {
    Serial.print("JERNIH ✓");
  } else {
    Serial.print("KERUH  ✗");
  }
  Serial.print(" (Pin: ");
  Serial.print(turbidityValue == HIGH ? "HIGH" : "LOW");
  Serial.println(")");
  
  Serial.println("╠════════════════════════════════════════════════╣");
  
  // Heater Status
  Serial.print("║ 🔥 Heater      : ");
  if (heaterStatus) {
    Serial.println("ON  🔴");
  } else {
    Serial.println("OFF ⚫");
  }
  
  // Mode
  Serial.print("║ 🎮 Mode        : ");
  Serial.println(manualControl ? "MANUAL" : "AUTO");
  
  Serial.println("╠════════════════════════════════════════════════╣");
  
  // WiFi Status
  Serial.print("║ 📶 WiFi        : ");
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Connected (");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm)");
  } else {
    Serial.println("Disconnected ❌");
  }
  
  // MQTT Status
  Serial.print("║ 🔌 MQTT        : ");
  if (client.connected()) {
    Serial.println("Connected ✅");
  } else {
    Serial.println("Disconnected ❌");
  }
  
  Serial.println("╚════════════════════════════════════════════════╝");
  Serial.println();
}
