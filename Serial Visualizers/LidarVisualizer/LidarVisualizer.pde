/*

LidarVisualizer
by Thomas Dodds
11/4/2024

Displays LIDAR data sent over serial from an Arduino.

'a' to autoreset every rotation
'r' to clear screen
'w' to zoom in
's' to zoom out

note: stop running Processing sketch when uploading new Arduino code
*/

import processing.serial.*;

Serial myPort;
String buf;
char val;
int loc, points_available;
int[] points_dist, points_ang;
boolean ang, areset;
int x, y, amax;
float zoom;

void setup() {  
  // initialize display
  frameRate(60);
  
  // uncomment fullscreen for fullscreen, or set a manual window size
  fullScreen(2);
  size(600, 600);
  
  noStroke();
  
  // initialize arrays
  points_dist = new int[500];
  points_ang = new int[500];
  zoom = 1;
  
  // initialize variables
  buf = "";
  loc = -1;
  
  // wait for serial port
  print("Waiting for serial... ");
  String portName = "";
  while(portName == ""){
    for(int i = 0; i < Serial.list().length; i++){
      if(Serial.list()[i].indexOf("ACM") >= 0){
        portName = Serial.list()[i];
      }
    }
    delay(1000);
  }
  
  // initialize serial port
  myPort = new Serial(this, portName, 115200);
  println("using " + portName);
  
  // set point color and initial clear
  fill(0, 0, 255);
  background(255);
}

void draw(){
  // read serial data
  while (myPort.available() > 0){
    val = myPort.readChar();
    switch (val) {
      case '[':
        // beginning of data frame: next bytes are distance
        ang = false;
        buf = "";
        break;
      case ']':
        // end of data frame: save angle and increment data point counter
        points_ang[points_available] = parseInt(buf);
        points_available++;
        break;
      case ',':
        // comma: save distance and prepare to record angle
        ang = true;
        points_dist[points_available] = parseInt(buf);
        buf = "";
        break;
      case '\n': case ' ':
        // ignored characters
        break;
      default:
        // digits (stored) or other chars (ignored)
        if(Character.isDigit(val)) buf = buf + val;
        break;
    }
  }
  
  // if there is data to draw, draw it
  if(points_available > 0){
    // draw
    for(int i = 0; i < points_available; i++){
      // if autoreset, and next angle is 10 smaller than previous, clear screen:
      if(areset){
        if(points_ang[i] > amax) amax = points_ang[i];
        if((points_ang[i] + 300) < amax){
          fill(255, 127);
          rect(0, 0, width, height);
          fill(0, 0, 255);
          amax = 0;
        }
      }
      
      // println("dist: " + points_dist[i] + "\tang: " + points_ang[i]);
      
      // calculate polar to rectangular
      x = int(float(points_dist[i]) * cos(radians(points_ang[i])));
      y = int(float(points_dist[i]) * sin(radians(points_ang[i])));
      
      // draw
      circle(width / 2 + x * zoom, height / 2 + y * zoom, 10);
      
      // for safety, clear point data:
      points_ang[i] = 0;
      points_dist[i] = 0;
    }
    
    // reset number of available points
    points_available = 0;
  }
}

// handle keyboard inputs
void keyPressed(){
  switch(key){
    case 'r':
      // clear screen
      background(255);
      break;
    case 'w':
      // zoom in
      background(255);
      zoom += 0.1;
      println("zoom: " + zoom);
      break;
    case 's':
      // zoom out
      background(255);
      if(zoom > 0.15) zoom -= 0.1;
      println("zoom: " + zoom);
      break;
    case 'a':
      // toggle autoreset
      areset = !areset;
      background(255);
    default:
      break;
  }
}
