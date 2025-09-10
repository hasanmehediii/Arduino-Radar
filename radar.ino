#include <Servo.h>

// Pin definitions
#define TRIG_PIN 9
#define ECHO_PIN 10
#define SERVO_PIN 11

Servo myServo;

long duration;
int distance;

void setup() {
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  myServo.attach(SERVO_PIN);

  Serial.begin(9600);  // Serial monitor / laptop communication
}

void loop() {
  // Sweep from 15° to 165°
  for (int angle = 15; angle <= 165; angle++) {
    myServo.write(angle);
    delay(30);  // Allow servo to move

    distance = getDistance();

    Serial.print(angle);
    Serial.print(",");
    Serial.println(distance);
  }

  // Sweep back from 165° to 15°
  for (int angle = 165; angle >= 15; angle--) {
    myServo.write(angle);
    delay(30);

    distance = getDistance();

    Serial.print(angle);
    Serial.print(",");
    Serial.println(distance);
  }
}

// Function to measure distance with HC-SR04
int getDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  duration = pulseIn(ECHO_PIN, HIGH);

  int cm = duration * 0.034 / 2;  // Convert time to distance
  return cm;
}
