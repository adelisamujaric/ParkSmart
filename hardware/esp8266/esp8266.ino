#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>

U8G2_SH1106_128X64_NONAME_F_SW_I2C u8g2(U8G2_R0, 14, 13, U8X8_PIN_NONE);

const char* ssid = "FRITZ!Box 7520 GB";
const char* password = "01386042308753323779";
const char* serverUrl = "http://192.168.178.29:8000/latest_entry";

String trenutnaTablica = "";

void prikaziNaDispleju(String tablica) {
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_ncenB10_tr);
  
  if (tablica == "") {
    u8g2.drawStr(0, 20, "CEKAM VOZILO");
  } else {
    u8g2.drawStr(0, 20, "TABLICA");
    u8g2.drawStr(0, 45, tablica.c_str());
  }
  
  u8g2.sendBuffer();
}

void setup() {
  Serial.begin(115200);
  u8g2.begin();
  
  prikaziNaDispleju("");
  
  WiFi.begin(ssid, password);
  Serial.print("Spajam na WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi spojen!");
  Serial.println(WiFi.localIP());
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClient client;
    HTTPClient http;
    
    http.begin(client, serverUrl);
    int httpCode = http.GET();
    
    if (httpCode == 200) {
      String payload = http.getString();
      
      StaticJsonDocument<512> doc;
      DeserializationError error = deserializeJson(doc, payload);
      
      if (!error) {
        bool available = doc["available"];
        if (available) {
          String tablica = doc["tablica"].as<String>();
          if (tablica != trenutnaTablica) {
            trenutnaTablica = tablica;
            prikaziNaDispleju(tablica);
            Serial.println("Nova tablica: " + tablica);
          }
        } else {
          if (trenutnaTablica != "") {
            trenutnaTablica = "";
            prikaziNaDispleju("");
          }
        }
      }
    } else {
      Serial.println("HTTP greška: " + String(httpCode));
    }
    
    http.end();
  }
  
  delay(3000);
}