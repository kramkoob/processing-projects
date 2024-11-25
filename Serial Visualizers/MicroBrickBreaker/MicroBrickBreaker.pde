/**
 * MicroBrickBreaker
 *
 * Bunch of serial devices connect and send packets... and we must handle them!
 */
 
// important things to configure
final static byte _ball_size = 4;
final static byte _maxplayers = 4;
final static int baud = 115200;

// less important things
final static int hintFadeDuration = 1000;

import processing.serial.*;
 
// player-specific things
Serial[] ser = new Serial[_maxplayers];
float[] bat_pos = new float[_maxplayers];
float[] bat_vel = new float[_maxplayers];
boolean[] bat_mode = new boolean[_maxplayers];
char[] keypad_last = new char[_maxplayers];

// gamewide things
byte state = 0;
byte numplayers = 0;
String[] serial_blacklist = new String[10];
String serial_text = "";
char[] buf = new char[10];
byte bufl = 0;
String level = "";

// hint message
int hintFade = -1500;
String hintMsg = "";

// animation
int movetime = 0;
int fadetime = 0;
int randspeed = 0;
int sel = -1;

// window variables
float wu;
int lf;

PFont liberation;

void setup() {
  fullScreen(P2D);
  frameRate(60);
  //size(800, 600, P2D);
  rectMode(CENTER);
  textAlign(CENTER, CENTER);
  
  // specific known font to work with
  liberation = createFont("LiberationSans-Regular.ttf", height/4, true);
  textFont(liberation);
  
  // width unit: the playing dimensions are 1x1, and widescreens being wider than height... reference everything to height 
  wu = 0.01 * float(height);
  // left of frame: distance between left/right of screen and playing field
  lf = (width - height) / 2;
  
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
          numplayers++;
          text("Player " + str(numplayers), width / 2 + 20*wu, height/4 + 4*wu*cpos);
        }
        textAlign(LEFT, CENTER);
        text(serial_text, width / 2 - 20*wu, height/4 + 4*wu*cpos);
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
          println("NullPointerException on serial list handled");
        }
        if(!found){
          serial_blacklist[i] = "";
        }
      }
      break;
    case 1: // select which player will map the board, and then let them input
      textAlign(CENTER, CENTER);
      textSize(3*wu);
      // homemade animations
      if(millis() - movetime - 2000 < 0){ // cycle through all available players at random speed for 2 seconds
        fill(255, 255, 255, 255);
        text("Board generation", width/2, height/4); 
        for(int i = 0; i < numplayers; i++){
          if(int((millis() + movetime) / randspeed) % numplayers == i){
            text(">> Player " + str(i + 1) + " <<", width/2, height/4 + 4*wu*(1+i));
          }else{
            text("Player " + str(i + 1), width/2, height/4 + 4*wu*(1+i));
          }
        }
      }else if(millis() - movetime - 2750 < 0){ // highlight the chosen player for about a second
        fill(255 - map(millis() - movetime - 2750, 0, 500, 0, 255));
        text("Board generation", width/2, height/4); 
        if(randspeed != 0){
          sel = int((millis() + movetime) / randspeed) % numplayers;
          randspeed = 0;
        }
        for(int i = 0; i < numplayers; i++){
          if(sel == i){
            fill(255, 255, 255, 255 * (int((millis()) / 125) % 2));
            text(">> Player " + str(i + 1) + " <<", width/2, height/4 + 4*wu*(1+i));
          }else{
            fill(255, 255, 255, 255 - map(millis() - movetime - 2750, 0, 500, 0, 255));
            text("Player " + str(i + 1), width/2, height/4 + 4*wu*(1+i));
          }
        }
        fadetime = millis();
      }else if(millis() - fadetime - 2000 < 0){ // prompt player for layout input until fades out
        if(level.length() != 3){ // if all input is there, fade out
          fadetime = millis();
        }
        fill(255, 255, 255, min(255, map(millis() - fadetime, 0, 2000, 255, 0)) * (int((millis()) / 250) % 2));
        text(">> Player " + str(sel + 1) + " <<", width/2, height/4 + (4*wu*(1+sel) * pow(max(0, map(millis() - movetime - 2750, 0, 500, 1, 0)), 2)));
        fill(255, 255, 255, min(min(255, map(millis() - movetime - 3000, 0, 500, 0, 255)), map(millis() - fadetime, 0, 2000, 255, 0)));
        text("Use your keypad to provide board layout:", width/2, height/4 + 4*wu);
        textSize(int(10*wu));
        fill(255, 255, 255, min(255, map(millis() - fadetime, 0, 2000, 255, 0)));
        text("*".repeat(level.length()), width/2, height/2);
      }else{ // proceed to next game state
        nextState();
      }
      break;
    default:
      break;
  }
  // hint message
  if(millis() < (hintFade + hintFadeDuration)){
    textAlign(CENTER, CENTER);
    textSize(3*wu);
    fill(255, 255, 255, 255 * max(0.0, min(1.0, float(hintFade - millis() + hintFadeDuration) / hintFadeDuration)));
    text(hintMsg, width/2, height*7/8);
  }
}

void setHint(String msg, int time){
  hintFade = millis() + time * 1000;
  hintMsg = msg;
  println(msg);
}

void nextState(){ // switch state if conditions are met
  switch(state){
    case 0:
      if(numplayers > 0){ // check if ports were found
        numplayers = -1;
        for(int i = 0; i < Serial.list().length; i++){
          if(numplayers == _maxplayers){
            break;
          }
          serial_text = Serial.list()[i];
          boolean bl = false;
          for(int j = 0; j < 10; j++){
            if(serial_text.equals(serial_blacklist[j])){
              bl = true;
              break;
            }
          }
          if(!bl){ // running through our ports, if this one wasn't on the blacklist, register it
            print("Registering port " + serial_text + " as player " + str(i + 1) + "... ");
            ser[++numplayers] = new Serial(this, serial_text, baud);
            ser[numplayers].bufferUntil(0x81); // wait for ETX byte
            ser[numplayers].clear();
            println("Done");
          }
        }
        numplayers++;
        if(numplayers == 1){ // if only one player, skip selection animation
          movetime = millis() - 4750;
          sel = 0;
          randspeed = 0;
          fadetime = millis();
        }else{ // if more than one player, set random parameters and begin animation
          movetime = millis();
          sel = int(random(1, numplayers + 1));
          randspeed = int(random(60, 250));
        }
        state = 1;
      }else{ // if no ports connected,
        setHint("No ports configurable!", 1);
      }
      break;
    case 1:
      
      break;
    default:
      break;
  }
}

void keyPressed(){ // press enter when ports are configured
  if(key == char(10) & state == 0){
    nextState();
  }
}

void serialEvent(Serial port) {
  if(state > 0){ // ignore traffic unless in a state to receive traffic (the ports have been configured)
    int ply = -1;
    for(int i = 0; i < numplayers; i++){ // identify which port the traffic is coming from
      if(port == ser[i]){
        ply = i;
        break;
      }
    }
    if(ply == -1){ // this should never happen... like, it's impossible
      println("What the heck! Unknown registered port is sending packets???");
    }else{
      bufl = byte(port.available());
      buf = char(port.readBytes());
      port.clear();
      if(buf[0] == 0x80){ // check first byte for STX
        // handle button input
        // press to change between absolute or velocity analog control
        
        // handle numpad input
        // if in selection and player is right and keypad is valid and it's a new value and we're in the right part of the sequence and we're not 3 chars long yet
        if(state == 1 && ply == sel && buf[2] != 17 && keypad_last[ply] != buf[2] && millis() - movetime - 2750 > 0 && level.length() != 3){
          // add valid keypad entry to level string
          level += str(byte(buf[2]));
        }
        keypad_last[ply] = buf[2];
        
        // handle analog input
        // based on desired control scheme, either set position or set velocity
        
        
      }else{ // if STX isn't there, drop and inform
        println("Player " + str(ply + 1) + " malformed packet");
      }
    }
  }
}
