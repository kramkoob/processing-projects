/**
 * MicroPong
 *
 * Bunch of serial devices connect and send packets... and we must handle them!
 */
 
// important things to configure
final static byte _maxplayers = 3;
final static int _baud = 19200;
final static byte _num_walls = 2;

final static float _ball_size = 2;
final static float _bat_size = 10;
final static float _bat_width = 2;
final static float _wall_width = 3;
final static float _ball_initial_speed = 50;
final static int _bounces_per_speedup = 10;
final static float _speedup_factor = 1.2;

// less important things
final static int hintFadeDuration = 1000;

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
float[][] walls = new float[_maxplayers][_num_walls + 1];
int[] wall_pos = new int[_num_walls];
float[] wall_pos_draw = new float[_num_walls];
boolean walls_ready = false;
int ply = -1;
float[] ball_pos = new float[2];
float[] ball_vel = new float[2];
int ball_bounces = 0;
int[] scores = new int[_maxplayers];
    
// hint message
int hintFade = -1000;
String hintMsg = "";

// window variables
byte state = 0;
float wu;
int lf;
int startMillis = 0;

// maths
float wp;
float[] bps = new float[2];
float[] wps = new float[3];
float ball_vel_l;
float[] wv = new float[2];
float wv_l;

PFont liberation;

void setup() {
  //fullScreen(P2D);
  fullScreen(P2D, 2);
  //size(1100, 950, P2D);
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
    wall_pos[i] = 20 * (1+ i);
    wall_pos_draw[i] = lf + wu * wall_pos[i];
  }
  
  // set initial bat positions and wall parameters (-1 to hide until input is given)
  for(int i = 0; i < _maxplayers; i++){
    bat_pos[i] = 50;
    for(int j = 0; j < _num_walls; j++){
      walls[i][j] = -1;
    }
    walls[i][_num_walls] = 0;
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
          println(e.getClass().getName() + " in serial list handled");
        }
        if(!found){
          serial_blacklist[i] = "";
        }
      }
      break;
    case 1: // prompt walls
      draw_elements(false);
      textSize(3*wu);
      fill(255, 0, 255, 255);
      text("Provide " + str(_num_walls) + " wall heights each, using keypad", width/2, height/4);
      break;
    case 2: // play ball
      ball_physics();
      draw_elements(true);
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

void ball_physics(){
  if(millis() > startMillis + 1000){
    for(int i = 0; i < 2; i++){
      ball_pos[i] += ball_vel[i] / frameRate;
      bps[i] = ball_pos[i] + ((ball_vel[i] > 0) ? _ball_size : -_ball_size) / 2;
    }
    for(int ply = 0; ply < numplayers; ply++){
      for(int wall = 0; wall < _num_walls; wall++){
        for(int i = 0; i < 2; i++){
          wps[i] = (ply%2) == 0 ? wall_pos[wall] : 100 - wall_pos[wall];
          wps[i] += (i%2==0 ? -_wall_width : _wall_width) / 2;
        }
        wps[2] = (wall%2==0) ? walls[ply][wall] * 10 : 100 - walls[ply][wall] * 10;
        if(constrain(bps[0], wps[0], wps[1]) == bps[0]){
          if(constrain(bps[1], ball_vel[1] < 0 ? wps[2] - _wall_width : wps[2], ball_vel[1] < 0 ? wps[2] : wps[2] + _wall_width) == bps[1]
            && (ball_vel[1] > 0 ? ball_pos[1] < wps[2] : ball_pos[1] > wps[2])){
            ball_vel[1] = -ball_vel[1];
          }else if(wall % 2 ==0 ? bps[1] < wps[2] : bps[1] > wps[2]){
            ball_vel[0] = -ball_vel[0];
            ball_bounces++;
          }
        }
      }
      if(constrain(bps[1], bat_pos[ply] - _bat_size / 2, bat_pos[ply] + _bat_size / 2) == bps[1]
        && ((ply % 2 == 0) ? (bps[0] < _bat_width) : (bps[0] > (100 - _bat_width)))){
        ball_vel_l = sqrt(pow(ball_vel[0], 2) + pow(ball_vel[1], 2));
        wv[0] = ball_pos[0] < 50 ? ball_vel_l : -ball_vel_l;
        wv[1] = 120 * (ball_pos[1] - bat_pos[ply]) / _bat_size;
        wv_l = sqrt(pow(wv[0], 2) + pow(wv[1], 2));
        ball_vel[0] = wv[0] * (ball_vel_l / wv_l);
        ball_vel[1] = wv[1] * (ball_vel_l / wv_l);
      }
    }
    if(bps[1] < 0 || bps[1] > 100){
      ball_vel[1] = -ball_vel[1];
      ball_bounces++;
    }
    if(ball_pos[0] < 0){
      for(int i = 1; i < numplayers; i+=2){
        scores[i]+=1;
      }
      ball_init();
      startMillis = millis() + 2000;
    }
    if(ball_pos[0] > 100){
      for(int i = 0; i < numplayers; i+=2){
        scores[i]+=1;
      }
      ball_init();
      startMillis = millis() + 2000;
    }
    if(ball_bounces > _bounces_per_speedup - 1){
      for(int i = 0; i < 2; i++){
        ball_vel[i] *= _speedup_factor;
        ball_bounces = 0;
      }
    }
  }
}

void draw_elements(boolean game){
  textAlign(CENTER, CENTER);
  for(int i = 0; i < numplayers; i++){
    fill(255.0 * i / numplayers, 255, 255);
    textSize(5*wu);
    rect(invertw(lf, (i%2)==1), wu * bat_pos[i], wu * _bat_width * 2, wu * _bat_size, wu * _bat_width);
    for(int j = 0; j < _num_walls; j++){
      rect(invertw(wall_pos_draw[j], (i%2)==1), inverth(0, (j%2)==1), _wall_width * wu, walls[i][j] * wu * 20, wu * _wall_width / 2);
      if(!game){
        text(str(int(walls[i][j])), invertw(wall_pos_draw[j], (i%2)==1), inverth((0.25 + walls[i][j]) * wu * 10, (j%2)==1));
      }
    }
    if(game){
      text(str(scores[i]), invertw(lf + 10 * wu, (i%2)==1), wu * 10);
    }
  }
  if(game && millis() > startMillis){
    fill(255);
    circle(lf + ball_pos[0] * wu, ball_pos[1] * wu, _ball_size * wu);
  }
  fill(40);
  rect(lf/2, height/2, lf, height);
  rect(width - lf/2, height/2, lf, height);
}

void setHint(String msg, int time){
  hintFade = millis() + time * 1000;
  hintMsg = msg;
  println(msg);
}

void ball_init(){
  ball_pos[0] = 50;
  ball_pos[1] = 50;
  ball_vel[0] = (float(int(random(0.5, 1.5))) - 0.5) * _ball_initial_speed;
  ball_vel[1] = (float(int(random(0.5, 1.5))) - 0.5) * _ball_initial_speed;
  ball_bounces = 0;
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
      if(walls_ready){
        // initial ball parameters
        startMillis = millis() + 500;
        ball_init();
        state = 2;
      }else{
        setHint("Waiting for all players to set walls...", 1);
      }
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
            println("Player " + str(ply + 1) + " bad keypad packet: length " + str(bufl));
            break;
          }
          if(state == 1){
            // update walls
            for(int i = 0; i < _num_walls; i++){
              walls[ply][i] = int(str(byte(buf[i+2])));
            }
            // indicate this player's walls are set
            walls[ply][_num_walls] = 1;
            // check if all players' walls have been set
            if(!walls_ready){
              walls_ready = true;
              for(int i = 0; i < numplayers; i++){
                if(walls[i][_num_walls] == 0){
                  walls_ready = false;
                }
              }
              if(walls_ready){
                setHint("Press enter to start", 2);
              }
            }
          }
          break;
        case 0x83: // byte potentiometer position
          if(bufl != 6){
            println("Player " + str(ply + 1) + " bad position packet: length " + str(bufl));
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
