/*

SerialVisualizer
by Thomas Dodds
9/24/2024

Displays FLIR data sent over serial from an Arduino.
Normalizes incoming data.

'r' to reset normalization limits
't' to toggle normalization reset every frame
'c' to display color test pattern

*/

final static int FLIR_Width = 8;
final static int FLIR_Height = 8;

import processing.serial.*;

Serial myPort;
float[] img;
String buf;
char val;
int loc;
boolean render, areset, ctest;
double x, r, g, b;
float imin, imax;

// reset normalization values
void reset_minmax(){
  imin = Float.MAX_VALUE;
  imax = -Float.MAX_VALUE;
}

void setup() {  
  // initialize display
  frameRate(60);
  // fullScreen();
  size(300, 300);
  noStroke();
  
  // initialize variables
  buf = "";
  loc = -1;
  img = new float[FLIR_Height * FLIR_Width];
  reset_minmax();
  
  // wait for serial port
  print("Waiting for serial... ");
  String portName = "";
  while(portName == ""){
    for(int i = 0; i < Serial.list().length; i++){
      if(Serial.list()[i].indexOf("USB") >= 0){
        portName = Serial.list()[i];
      }
    }
    delay(1000);
  }
  
  // initialize serial port
  myPort = new Serial(this, portName, 115200);
  println("using " + portName);
}

void draw(){
  // clear serial buffer constantly if in test mode
  if(ctest) myPort.clear();
  
  // read serial data if not mid-render and not mid-color test
  while (myPort.available() > 0 & !render & !ctest){
    val = myPort.readChar();
    switch (val) {
      case '[':
        // beginning of data frame
        loc = -1;
        buf = "";
        break;
      case ']':
        // end of data frame
        render = true;
        break;
      case ',':
        // next data point
        loc++;
        if(buf != "") img[loc] = Float.parseFloat(buf);
        buf = "";
        break;
      case '\n': case ' ':
        // ignored characters
        break;
      case '.':
        // decimal point (stored)
        buf = buf + '.';
      default:
        // digits (stored) or other chars (ignored)
        if(Character.isDigit(val)) buf = buf + val;
        break;
    }
  }
  
  // if all data has been acquired, draw
  if(render){
    render = false;
    
    // if always resetting normalization limits, do it now
    if(areset) reset_minmax();
    
    // normalization
    for(int i = 0; i < FLIR_Height * FLIR_Width; i++){
      if(img[i] < imin){
        imin = img[i];
      }
      if(img[i] > imax){
        imax = img[i];
      }
    }
    
    // draw
    for(int i = 0; i < FLIR_Height * FLIR_Width; i++){
      // calculate color of temperature
      x = map(img[i], imin, imax, 0, 1);
      r = Math.round(255*Math.sqrt(x)); 
      g = Math.round(255*Math.pow(x,3)); 
      b = Math.round(255*(Math.sin(2 * Math.PI * x)>=0?
                   Math.sin(2 * Math.PI * x) : 0 ));
      fill((int)r, (int)g, (int)b);
      
      // draw
      rect(floor(i / FLIR_Width) * (width / FLIR_Width), 
             (i % FLIR_Width) * (height / FLIR_Height), 
             width / FLIR_Width,
             height / FLIR_Height);
    }
  }
}

// handle keyboard inputs
void keyPressed(){
  switch(key){
    case 'r':
      // reset normalization limits
      reset_minmax();
      break;
    case 't':
      // toggle always resetting normalization limits
      areset = !areset;
      break;
    case 'c':
      // toggle color test mode
      ctest = !ctest;
      if(ctest){
        imin = 0;
        imax = FLIR_Width * FLIR_Height - 1;
        loc = -1;
        buf = "";
        render = true;
        for(int i = 0; i < FLIR_Width * FLIR_Height; i++){
          img[i] = i;
        }
      }
      break;
    default:
      break;
  }
}
