/**
 * MicroPong
 *
 * Bunch of serial devices connect and send packets... and we must handle them!
 */
 
// important things to configure
final static byte _maxplayers = 3;
final static int _baud = 19200;
final static byte _num_walls = 2;

final static float _ball_size = 0.2;
final static float _bat_size = 20;
final static float _bat_speed = 1.5;

// less important things
final static int hintFadeDuration = 1000;
final static float _bat_width = 2;
final static float _wall_width = 2;

import processing.serial.*;

// serial things
Serial[] ser = new Serial[_maxplayers];
char[] keypad_last = new char[_maxplayers];
String[] serial_blacklist = new String[10];
String serial_text = "";
char[] buf = new char[10];
byte bufl = 0;
int[] sel = new int[_maxplayers];

// game things
byte numplayers = 0;
float[] bat_pos = new float[_maxplayers];
float[][] walls = new float[_maxplayers][_num_walls];
int[] wall_pos = new int[_num_walls];
int ply = -1;
    
// hint message
int hintFade = -1500;
String hintMsg = "";

// window variables
byte state = 0;
float wu;
int lf;

PFont liberation;

void setup() {
  //fullScreen(P2D);
  size(1100, 950, P2D);
  frameRate(60);
  rectMode(CENTER);
  textAlign(CENTER, CENTER);
  colorMode(HSB, 255);
  
  // specific known font to work with
  liberation = createFont("LiberationSans-Regular.ttf", height/4, true);
  textFont(liberation);
  
  // width unit: the playing dimensions are 1x1, and widescreens being wider than height... reference everything to height 
  wu = 0.01 * float(height);
  // left of frame: distance between left/right of screen and playing field
  lf = (width - height) / 2;
  
  // set up wall positions
  for(int i = 0; i < _num_walls; i++){
    wall_pos[i] = int(lf + wu * 20 * (1+ i));
  }
  
  // set initial bat positions
  for(int i = 0; i < _maxplayers; i++){
    bat_pos[i] = 50;
  }
  
  // initial configuration of serial blacklist
  for(int i = 0; i < Serial.list().length; i++){
    try {
      serial_blacklist[i] = Serial.list()[i];
    } catch(Exception e){
      serial_blacklist[i] = "";
    }
  }
  
  setHint("Press enter when all ports are connected", 5);
}

void draw() {
  background(0);
  switch(state){
    case 0: // port connection
      textSize(3*wu);
      fill(255);
      textAlign(CENTER, CENTER);
      text("Reconnect port receivers (up to " + str(_maxplayers) + ")", width/2, height/4);
      numplayers = 0;
      
      // check all currently connected devices if they're on the blacklist
      try{
        for(int cpos = 1; cpos <= Serial.list().length; cpos++){
          // skip anything else if we're already at player limit
          if(numplayers == _maxplayers){
            break;
          }
          serial_text = Serial.list()[cpos - 1];
          boolean bl = false;
          for(int i = 0; i < 10; i++){
            if(serial_text.equals(serial_blacklist[i])){
              bl = true;
              break;
            }
          }
          // darken and hint that it's blacklisted
          textAlign(RIGHT, CENTER);
          if(bl){
            fill(100);
            text("Blacklisted", width / 2 + 20*wu, height/4 + 4*wu*cpos);
          }else{
            fill(255);
            numplayers++;
            text("Player " + str(numplayers), width / 2 + 20*wu, height/4 + 4*wu*cpos);
          }
          textAlign(LEFT, CENTER);
          text(serial_text, width / 2 - 20*wu, height/4 + 4*wu*cpos);
        }
      }catch(Exception e){
        println(e.getClass().getName() + " on serial list ignored");
      }
      
      // if a device has been removed, remove it from the blacklist for reconnection
      for(int i = 0; i < 10; i++){
        boolean found = false;
        try{ // sometimes nullpointerexception occurs if the device is removed during this loop
          for(int j = 0; j < Serial.list().length; j++){
            if(Serial.list()[j].equals(serial_blacklist[i])){
              found = true;
              break;
            }
          }
        }catch(Exception e){
          found = true;
          println(e.getClass().getName() + " on serial list handled");
        }
        if(!found){
          serial_blacklist[i] = "";
        }
      }
      break;
    case 1: // prompt walls
      fill(40);
      rect(lf/2, height/2, lf, height);
      rect(width - lf/2, height/2, lf, height);
      textAlign(CENTER, CENTER);
      textSize(3*wu);
      for(int i = 0; i < numplayers; i++){
        fill(255.0 * i / numplayers, 255, 255);
        rect(invertw(lf + wu * _bat_width / 2.0, (i%2)==1), wu * bat_pos[i], wu * _bat_width, wu * _bat_size);
        for(int j = 0; j < _num_walls; j++){
          rect(invertw(wall_pos[j], (i%2)==1), inverth(walls[i][j] * wu * 5, (j%2)==1), _wall_width * wu, walls[i][j] * wu * 10);
          textSize(5*wu);
          text(str(walls[i][j]), invertw(wall_pos[j], (i%2)==1), inverth((0.25 + walls[i][j]) * wu * 10, (j%2)==1));
        }
      }
      fill(255, 0, 255, 255);
      text("Provide " + str(_num_walls) + " wall heights each, using keypad", width/2, height/4);
      break;
    case 2:
      fill(40);
      rect(lf/2, height/2, lf, height);
      rect(width - lf/2, height/2, lf, height);
      for(int i = 0; i < numplayers; i++){
        fill(255.0 * i / numplayers, 255, 255);
        rect(invertw(lf + wu * _bat_width / 2.0, (i%2)==1), wu * bat_pos[i], wu * _bat_width, wu * _bat_size);
        for(int j = 0; j < _num_walls; j++){
          rect(invertw(wall_pos[j], (i%2)==1), inverth(walls[i][j] * wu * 5, (j%2)==1), _wall_width * wu, walls[i][j] * wu * 10);
          textSize(5*wu);
          text(str(int(walls[i][j])), invertw(wall_pos[j], (i%2)==1), inverth((0.25 + walls[i][j]) * wu * 10, (j%2)==1));
        }
      }
      break;
    default:
      break;
  }
  // hint message
  if(millis() < (hintFade + hintFadeDuration)){
    textAlign(CENTER, CENTER);
    textSize(3*wu);
    fill(255, 0, 255, 255 * max(0.0, min(1.0, float(hintFade - millis() + hintFadeDuration) / hintFadeDuration)));
    text(hintMsg, width/2, height*7/8);
  }
}

void setHint(String msg, int time){
  hintFade = millis() + time * 1000;
  hintMsg = msg;
  println(msg);
}

float invertw(float val, boolean invert){
  if(invert){
    return width - val;
  }
  return val;
}
float inverth(float val, boolean invert){
  if(invert){
    return height - val;
  }
  return val;
}

void nextState(){ // switch state if conditions are met
  switch(state){
    case 0:
      if(numplayers > 0){ // check if ports were found
        numplayers = -1;
        for(int i = 0; i < Serial.list().length; i++){
          serial_text = Serial.list()[i];
          boolean bl = false;
          for(int j = 0; j < 10; j++){
            if(serial_text.equals(serial_blacklist[j])){
              bl = true;
              break;
            }
          }
          if(!bl){ // running through our ports, if this one wasn't on the blacklist, register it
            print("Registering port " + serial_text + " as player " + str(numplayers + 2) + "... ");
            ser[++numplayers] = new Serial(this, serial_text, _baud);
            ser[numplayers].bufferUntil(0x81); // wait for ETX byte
            ser[numplayers].clear();
            println("Done");
          }
          if(numplayers == _maxplayers){
            break;
          }
        }
        numplayers++;
        state = 1;
      }else{ // if no ports connected,
        setHint("No ports configurable!", 1);
      }
      break;
    case 1:
      state = 2;
      break;
    default:
      break;
  }
}

void keyPressed(){ // press enter when ports are configured
  if(key == char(10)){
    nextState();
  }
}

void serialEvent(Serial port) {
  if(state > 0){ // ignore traffic unless in a state to receive traffic (the ports have been configured)
    for(int i = 0; i < numplayers; i++){ // identify which port the traffic is coming from
      if(port == ser[i]){
        ply = i;
        break;
      }
    }
    bufl = byte(port.available());
    buf = char(port.readBytes());
    port.clear();
    if(buf[0] == 0x80){ // check first byte for STX
      switch(buf[1]){
        case 0x82: // keypad input
          if(bufl != 6){ // if the packet isn't six bytes long
            println("Player " + str(ply + 1) + " malformed keypad packet: length " + str(bufl));
            break;
          }
          switch(state){
            case 1:
              walls[ply][0] = int(str(byte(buf[2])));
              walls[ply][1] = int(str(byte(buf[3])));
              break;
            default:
              break;
          }
          break;
        case 0x83: // byte potentiometer position
          if(bufl != 6){
            println("Player " + str(ply + 1) + " malformed position packet: length " + str(bufl));
            break;
          }
          bat_pos[ply] = map(float(buf[4]), 0.0, 127.0, _bat_size / 2, 100 - _bat_size / 2);
          break;
        default:
          println("Player " + str(ply + 1) + " unknown packet: " + str(byte(buf[1])));
          break;
      }
    }else{ // if STX isn't there, drop and inform
      println("Player " + str(ply + 1) + " malformed packet: no STX");
    }
  }
}
