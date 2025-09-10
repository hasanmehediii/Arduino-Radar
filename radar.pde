import processing.serial.*;

Serial myPort;
String data = "";
float angle = 0;
float displayAngle = 0; // For smooth interpolation
int distance = 0;
int maxDistance = 200; // Max distance in cm
float radarRadius = 400; // Display radius
ArrayList<PVector> history = new ArrayList<PVector>(); // Store past detections
int historyMax = 100; // Max points in history
boolean isPaused = false;
float minDistance = 5; // Minimum distance threshold in cm to filter noise

void setup() {
  size(1000, 800, P2D); // Use P2D for smoother graphics
  smooth(4);
  try {
    myPort = new Serial(this, Serial.list()[0], 9600);
    myPort.bufferUntil('\n');
  } catch (Exception e) {
    println("Error opening serial port: " + e.getMessage());
    exit();
  }
}

void draw() {
  background(10, 20, 30); // Dark blue background
  
  // Update display angle with smooth interpolation
  if (!isPaused) {
    displayAngle = lerp(displayAngle, angle, 0.1);
  }
  
  pushMatrix();
  translate(width/2, height-50);
  
  // Draw glowing radar grid
  noFill();
  for (int r = 100; r <= radarRadius; r += 100) {
    stroke(0, 255, 100, 100 - r/10);
    strokeWeight(2);
    ellipse(0, 0, r*2, r*2);
    fill(0, 255, 100, 150);
    textAlign(CENTER);
    textSize(14);
    text(r/2 + "cm", 0, -r-15);
  }
  
  // Draw angle markers
  stroke(0, 255, 100, 50);
  strokeWeight(1);
  for (int a = 0; a < 360; a += 30) {
    float x = cos(radians(a)) * radarRadius;
    float y = -sin(radians(a)) * radarRadius;
    line(0, 0, x, y);
    fill(0, 255, 100, 200);
    textAlign(CENTER, CENTER);
    textSize(12);
    text(a + "°", x*1.1, y*1.1);
  }
  
  // Draw sweep with trail effect
  for (float a = displayAngle - 30; a <= displayAngle; a += 1) {
    float alpha = map(a, displayAngle - 30, displayAngle, 0, 150);
    stroke(0, 255, 0, alpha);
    strokeWeight(3);
    float x = cos(radians(a)) * radarRadius;
    float y = -sin(radians(a)) * radarRadius;
    line(0, 0, x, y);
  }
  
  // Draw history with glowing, fading dots
  for (int i = history.size()-1; i >= 0; i--) {
    PVector p = history.get(i);
    float fade = map(i, 0, history.size()-1, 50, 255);
    noStroke();
    fill(255, 50, 50, fade);
    ellipse(p.x, p.y, 12, 12);
    fill(255, 50, 50, fade/2);
    ellipse(p.x, p.y, 20, 20);
  }
  
  // Draw current object with glow
  if (distance >= minDistance && distance < maxDistance) {
    float scaledDistance = map(distance, 0, maxDistance, 0, radarRadius);
    float objX = cos(radians(displayAngle)) * scaledDistance;
    float objY = -sin(radians(displayAngle)) * scaledDistance;
    noStroke();
    fill(255, 50, 50);
    ellipse(objX, objY, 15, 15);
    fill(255, 50, 50, 100);
    ellipse(objX, objY, 25, 25); // Glow effect
    if (!isPaused) {
      history.add(new PVector(objX, objY));
    }
    if (history.size() > historyMax) {
      history.remove(0);
    }
  }
  
  popMatrix();
  
  // Draw HUD
  drawHUD();
}

void drawHUD() {
  fill(0, 50, 100, 150);
  noStroke();
  rect(10, 10, 250, 140, 10); // Extended HUD for debug info
  
  fill(0, 255, 100);
  textSize(16);
  textAlign(LEFT);
  text("Radar Status: " + (isPaused ? "PAUSED" : "ACTIVE"), 20, 30);
  text("Angle: " + nf(displayAngle, 0, 1) + "°", 20, 50);
  text("Distance: " + (distance < maxDistance ? distance : ">200") + "cm", 20, 70);
  text("Objects Detected: " + history.size(), 20, 90);
  text("Raw Distance: " + distance + "cm", 20, 110); // Debug raw distance
  text("Press SPACE to pause/resume", 20, 130);
}

void serialEvent(Serial p) {
  try {
    data = p.readStringUntil('\n');
    if (data != null) {
      data = trim(data);
      println("Raw data: " + data); // Debug print
      String[] values = split(data, ',');
      if (values.length == 2) {
        float newAngle = float(values[0]);
        int newDistance = int(values[1]);
        // Optional: Convert mm to cm if sensor sends millimeters
        // newDistance = newDistance / 10; // Uncomment if sensor uses mm
        if (newAngle >= 0 && newAngle <= 360 && newDistance >= 0) {
          angle = newAngle;
          distance = min(newDistance, maxDistance);
        } else {
          println("Invalid data: Angle=" + newAngle + ", Distance=" + newDistance);
        }
      } else {
        println("Invalid data format: " + data);
      }
    }
  } catch (Exception e) {
    println("Error reading serial data: " + e.getMessage());
  }
}

void keyPressed() {
  if (key == ' ') {
    isPaused = !isPaused;
  }
}
