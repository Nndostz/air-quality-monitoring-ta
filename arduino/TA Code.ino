/*****************************************************
 * Industrial Air Quality Monitor (Conference Version)
 * ESP32 + MQ-135 + MQ-7 + DHT22
 * Firebase Realtime Database (JSON format)
 *****************************************************/

// =================== LIBRARY =======================
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// =================== WiFi CONFIG ===================
#define WIFI_SSID "Zohtnasus"
#define WIFI_PASSWORD "SusanthozWifi772!"

// =================== FIREBASE CONFIG ===============
#define API_KEY "AIzaSyCV08jOjFXpF7vaR2uXsttC1T_jE8Py-nI"
#define DATABASE_URL "https://airqualitymonitoring-29268-default-rtdb.firebaseio.com/"
#define USER_EMAIL "fernandosusanthoz@gmail.com"
#define USER_PASSWORD "@Nandostz09"

// =================== PIN SETUP =====================
#define DHTPIN 13
#define DHTTYPE DHT22

#define MQ135_PIN 32
#define MQ7_PIN   33

// =================== OBJECT ========================
DHT dht(DHTPIN, DHTTYPE);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// =================== VARIABLES =====================
float temperature, humidity;
float mq135_raw, mq7_raw;
float mq135_voltage, mq7_voltage;
float mq135_ppm, mq7_ppm;

unsigned long lastSend = 0;
const long sendInterval = 5000;

// MQ Calibration (use your calibrated values)
float MQ135_Ro = 19.39;
float MQ7_Ro = 5.03;

#define RL_MQ135 10.0
#define RL_MQ7   10.0

// Industrial Thresholds
#define CO2_GOOD      600
#define CO2_MODERATE 1000
#define CO_GOOD       4.4
#define CO_MODERATE   9.0

String airQuality = "BAIK";

// ===================================================
//                CONNECT WiFi
// ===================================================
void connectWiFi() {
  Serial.print("📡 Connecting to WiFi");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 20) {
    delay(500);
    Serial.print(".");
    retry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected!");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ WiFi Failed. Restarting...");
    ESP.restart();
  }
}

// ===================================================
//              MQ SENSOR FUNCTIONS
// ===================================================
float getMQ135_PPM(float voltage) {
  if (voltage <= 0.1) return 0;

  float rs = (3.3 * RL_MQ135 / voltage) - RL_MQ135;
  float ratio = rs / MQ135_Ro;

  float ppm = 116.6020682 * pow(ratio, -2.769034857);
  ppm *= 35.0;  // humidity + temp correction
  if (ppm < 0) ppm = 0;

  return ppm;
}

float getMQ7_PPM(float voltage) {
  if (voltage <= 0.1) return 0;

  float rs = (3.3 * RL_MQ7 / voltage) - RL_MQ7;
  float ratio = rs / MQ7_Ro;

  float ppm = 99.042 * pow(ratio, -1.518);
  if (ppm < 0) ppm = 0;

  return ppm;
}

// ===================================================
//              DETERMINE AIR QUALITY
// ===================================================
void determineAirQuality() {
  if (mq135_ppm < CO2_GOOD && mq7_ppm < CO_GOOD)
    airQuality = "BAIK";
  else if (mq135_ppm < CO2_MODERATE && mq7_ppm < CO_MODERATE)
    airQuality = "SEDANG";
  else
    airQuality = "BURUK";
}

// ===================================================
//	          SEND DATA TO FIREBASE
// ===================================================
void sendToFirebase() {
  if (!Firebase.ready()) {
    Serial.println("⚠️ Firebase not ready"); 
    return;
  }

  Serial.println("📤 Sending to Firebase...");

  FirebaseJson json;
  json.set("temperature", temperature);
  json.set("humidity", humidity);
  json.set("co2", mq135_ppm);
  json.set("co", mq7_ppm);
  json.set("air_quality", airQuality);
  json.set("timestamp", millis() / 1000);

  if (Firebase.RTDB.setJSON(&fbdo, "/sensors/current", &json)) {
    Serial.println("✅ Firebase updated!");
  } else {
    Serial.println("❌ Firebase error: " + fbdo.errorReason());
  }

  // Optional History Logging
  String historyPath = "/sensors/history/" + String(millis() / 1000);
  Firebase.RTDB.setJSON(&fbdo, historyPath.c_str(), &json);
}

// ===================================================
//                      SETUP
// ===================================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  dht.begin();
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  connectWiFi();

  // Firebase Initialization
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.max_token_generation_retry = 5;

  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("🔥 Firebase Ready");
}

// ===================================================
//                        LOOP
// ===================================================
void loop() {
  // Read DHT22
  temperature = dht.readTemperature();
  humidity = dht.readHumidity();

  if (isnan(temperature)) temperature = 25;
  if (isnan(humidity)) humidity = 60;

  // Read MQ Sensors
  mq135_raw = analogRead(MQ135_PIN);
  mq7_raw   = analogRead(MQ7_PIN);

  mq135_voltage = (mq135_raw / 4095.0) * 3.3;
  mq7_voltage   = (mq7_raw / 4095.0) * 3.3;

  mq135_ppm = getMQ135_PPM(mq135_voltage);
  mq7_ppm   = getMQ7_PPM(mq7_voltage);

  determineAirQuality();

  // Print to Serial
  Serial.println("===================================");
  Serial.printf("Temp: %.1f°C | Hum: %.1f%%\n", temperature, humidity);
  Serial.printf("CO₂ : %.2f ppm | CO : %.2f ppm\n", mq135_ppm, mq7_ppm);
  Serial.printf("Quality: %s\n", airQuality.c_str());

  // Send to Firebase every X seconds
  if (millis() - lastSend > sendInterval) {
    lastSend = millis();
    sendToFirebase();
  }

  delay(1000);
}
