/**
 * BrickBreaker
 *
 * Communicates with a serial device that sends packets relating to bat position.
 */
 
// important things to configure
// maximum number of hits to break blocks. > 1 will color blocks accordingly. = 1 will be grey.
final static int _brick_health = 3;
final static int _max_lives = 3;
final static int _game_width = 8;
final static int _game_height = 10;
final static float _ball_initial_speed = 30;

final static int _baud = 19200;

// less important things
final static int hintFadeDuration = 1000;
final static float _ball_size = 2;
final static float _bat_width = 15;
final static float _bat_size = 2;
final static int _bounces_per_speedup = 4;
final static float _ball_speedup_factor = 1.05;

// EXPERIMENTAL
// Setting to false may improve performance but introduce visual artifacts
final static boolean _constant_redraw = true;

import processing.serial.*;
import java.util.Arrays;

// game things
boolean setup = true;
float bat_pos = 50;
float ball_pos[] = new float[2];
float ball_vel[] = new float[2];
float ball_prev_pos[] = new float[2];
int ball_brick[] = new int[2];
int ball_remain = _max_lives;
int ball_bounces = 0;
int score = 0;
int[][] bricks = new int[_game_width][_game_height];
int bricks_remain;
//int check[][] = {{-1, 0}, {0, 0}, {1, 0}, {0, -1}, {0, 1}};
    
// hint message
int hintFade = -1000;
String hintMsg = "";

// window variables
float wu;
int lf;
int startMillis = 0;

// maths
float[] bps = new float[2];
float ball_vel_l;
float[] wv = new float[2];
float wv_l;

// serial things
Serial ser;
String[] serial_blacklist = new String[10];
String serial_text = "";
char[] buf = new char[10];
byte bufl = 0;

PFont liberation;
PImage bricktexture;

// custom functions
void setHint(String msg, int time){ // set hint message and fadeout time
  hintFade = millis() + time * 1000;
  hintMsg = msg;
  println(msg);
}

void ball_init(){ // reset ball velocity and bounces
  ball_prev_pos[0] = 0;
  ball_prev_pos[1] = 0;
  ball_vel[0] = 0;
  ball_vel[1] = -abs(_ball_initial_speed);
  ball_bounces = 0;
}

void game_init(){ // reset game variables
  init_bricks();
  ball_init();
  ball_remain = _max_lives;
  startMillis = millis() + 3000;
}

void game_life(){ // remove a life. if lives == 0, game over
  if(--ball_remain == 0){
    game_over(false);
  }else{
    setHint(str(ball_remain) + (ball_remain == 1 ? " ball left" : " balls left"), 3);
    ball_init();
    startMillis = millis() + 3000;
  }
}

void game_over(boolean win){ // reset game
  background(0); // clear screen of all elements
  if(win){
    setHint("Congratulations!", 3);
  }else{
    setHint("Game over!", 3);
  }
  game_init(); // reset game
  startMillis = millis() + 6000;
}

void ball_speedup(){
  ball_bounces = 0;
  for(int i = 0; i < 2; i++) ball_vel[i] *= _ball_speedup_factor;
}

void ball_physics(){
  if(millis() > startMillis){ // play game
    bat_pos = constrain(ball_prev_pos[0] + 1 - 2 * (ball_bounces % 2), _bat_width / 2, 100-_bat_width / 2); // DEBUG
    for(int i = 0; i < 2; i++){ // update ball pos and find future pos
      ball_prev_pos[i] = ball_pos[i];
      ball_pos[i] += ball_vel[i] / frameRate;
      bps[i] = ball_pos[i] + ((ball_vel[i] > 0) ? _ball_size : -_ball_size) / 2;
    }
    
    // compare future pos with obstacles for collisions
    // side walls
    if(bps[0] < 0 || bps[0] > 100) ball_vel[0] = -ball_vel[0];
    // top wall
    if(bps[1] < 0) ball_vel[1] = -ball_vel[1];
    
    // bat
    if(constrain(bps[0], bat_pos - _bat_width / 2, bat_pos + _bat_width / 2) == bps[0]
    && constrain(bps[1], 95 - _bat_size / 2, 95 + _bat_size / 2) == bps[1]){
      ball_vel_l = sqrt(pow(ball_vel[0], 2) + pow(ball_vel[1], 2));
      wv[1] = -ball_vel_l;
      wv[0] = 3 * ball_vel_l * (ball_pos[0] - bat_pos) / _bat_width;
      wv_l = sqrt(pow(wv[0], 2) + pow(wv[1], 2));
      ball_vel[0] = wv[0] * (ball_vel_l / wv_l);
      ball_vel[1] = wv[1] * (ball_vel_l / wv_l);
      ball_bounces++;
    }
    
    // bricks
    // check if ball is in brick area
    if(bps[0] < 90 && bps[0] > 10 && bps[1] < 70 && bps[1] > 10){
      // find which brick is near the ball
      ball_brick[0] = int((bps[0] - 10) / 80 * _game_width);
      ball_brick[1] = int((bps[1] - 10) / 60 * _game_height);
      
      // check if that brick exists
      if(bricks[ball_brick[0]][ball_brick[1]] > 0){
        // decrease its health brick
        bricks[ball_brick[0]][ball_brick[1]]--;
        
        // draw black over brick
        pushMatrix();
        beginShape();
        if(bricks[ball_brick[0]][ball_brick[1]] == 0){
          fill(0);
        }else{
          texture(bricktexture);
          if(_brick_health > 1) tint(bricks[ball_brick[0]][ball_brick[1]] * 255 / _brick_health, 255, 255);
        }
        translate(lf + wu * (10 + ball_brick[0] * 80 / _game_width), wu * (10 + ball_brick[1] * 60 / _game_height));
        vertex(0, 0, 0, 0);
        vertex(wu * 80 / _game_width, 0, 1, 0);
        vertex(wu * 80 / _game_width, wu * 60 / _game_height, 1, 1);
        vertex(0, wu * 60 / _game_height, 0, 1);
        endShape();
        popMatrix();

        // bounce
        if(ball_pos[0] < 10 + ball_brick[0] * 80 / _game_width
        || ball_pos[0] > 10 + (1+ball_brick[0]) * 80 / _game_width) ball_vel[0] = -ball_vel[0];
        else ball_vel[1] = -ball_vel[1];
        //else if(ball_pos[1] < 10 + ball_brick[1] * 60 / _game_height
        //|| ball_pos[1] > 10 + (1+ball_brick[1]) * 60 / _game_height) 
        
        // if vertical difference is greater than horzontal distance, bounce horizontal
        //if(abs(constrain(ball_pos[0], 10 + ball_brick[0] / 80 * _game_width, 20 + ball_brick[0] / 80 * _game_width) - ball_pos[0])
        //> abs(constrain(ball_pos[1], 10 + ball_brick[1] / 60 * _game_height, 20 + ball_brick[1] / 60 * _game_height) - ball_pos[1])){
//          ball_vel[0] = -ball_vel[0];
        //}else{
//          ball_vel[1] = -ball_vel[1];
        //}
        
        // if we have cleared all bricks, win
        if(--bricks_remain == 0) game_over(true);
      }
    }
    // if ball falls off bottom of screen, take a life
    if(ball_pos[1] > 100) game_life();
    
    // if ball has bounced enough times, 
    if(ball_bounces == _bounces_per_speedup) ball_speedup();
  }else if(millis() > startMillis - 1000){ // pre game
    draw_bricks();
    
    ball_pos[0] = bat_pos - 1; // DEBUG
    //ball_pos[0] = bat_pos;
    ball_pos[1] = 95 - (_ball_size + _bat_size) / 2;
  }
}

void init_bricks(){
  bricks_remain = 0;
  for(int x = 0; x < _game_width; x++){
    for(int y = 0; y < _game_height; y++){
      bricks_remain += _brick_health - int(float(_brick_health) * float(y) / float(_game_height));
      bricks[x][y] = _brick_health - int(float(_brick_health) * float(y) / float(_game_height));
    }
  }
}

void draw_bricks(){
  for(int x = 0; x < _game_width; x++){ // draw bricks
    for(int y = 0; y < _game_height; y++){
      if(bricks[x][y] > 0){
        pushMatrix();
        beginShape();
        texture(bricktexture);
        if(_brick_health > 1) tint(bricks[x][y] * 255 / _brick_health, 255, 255);
        translate(lf + wu * (10 + x * 80 / _game_width), wu * (10 + y * 60 / _game_height));
        vertex(0, 0, 0, 0);
        vertex(wu * 80 / _game_width, 0, 1, 0);
        vertex(wu * 80 / _game_width, wu * 60 / _game_height, 1, 1);
        vertex(0, wu * 60 / _game_height, 0, 1);
        endShape();
        popMatrix();
      }
    }
  }
}

void draw_elements(){
  // game borders
  fill(40);
  rect(lf/2, height/2, lf, height);
  rect(width - lf/2, height/2, lf, height);
  
  if(!_constant_redraw){
    // clean the entire space the bat could be
    fill(0);
    rect(width/2, height - wu * 5, height, _bat_size * wu);
    // clean where the ball used to be
    if(millis() > startMillis - 1000) circle(lf + ball_prev_pos[0] * wu, ball_prev_pos[1] * wu, _ball_size * wu * 1.1);
  }
  
  // bat
  fill(255);
  rect(lf + bat_pos * wu, height - wu * 5, _bat_width * wu, _bat_size * wu);
  // if playing or within one second of playing, draw ball
  if(millis() > startMillis - 1000) circle(lf + ball_pos[0] * wu, ball_pos[1] * wu, _ball_size * wu);
}

void serialEvent(Serial port) {
  bufl = byte(port.available());
  buf = char(port.readBytes());
  port.clear();
  if(buf[0] == 0x80){ // check for STX
    switch(buf[1]){ // check command
      case 0x83: // bat position
        if(bufl != 6){ // check length of packet
          println("Dropped a packet (bad len: " + str(bufl) + ")");
          break;
        }
        if(setup){
          setHint(str(_max_lives) + " lives. Good luck!", 3);
          setup = false;
        }
        bat_pos = map(float(buf[4]), 0.0, 127.0, _bat_width / 2, 100 - _bat_width / 2);
        break;
      default: // unknown command -> drop
        println("Dropped a packet (unknown: " + str(byte(buf[1])) + ")");
        break;
    }
  }else{ // no STX -> drop
    println("Dropped a packet (no STX)");
  }
}

void setup() {
  // fullscreen on default display
  fullScreen(P2D);
  
  // fullscreen on second display (defaults if no second screen available)
  //fullScreen(P2D, 2);
  
  // windowed at set size
  //size(1100, 950, P2D);
  
  // lower if not running at full speed
  frameRate(60);
  
  // width unit: reference everything to display area height 
  wu = 0.01 * float(height);
  
  // left of frame: distance between left/right of screen and playing field
  lf = (width - height) / 2;

  // specific known font to work with
  liberation = createFont("LiberationSans-Regular.ttf", 3*wu, true);
  textFont(liberation);
  
  bricktexture = loadImage("brick.png");
  
  rectMode(CENTER);
  colorMode(HSB, 255);
  textAlign(CENTER, CENTER);
  noStroke();
  strokeWeight(wu);
  
  // initialize serial blacklist
  serial_blacklist = Serial.list();
  
  background(0);
  fill(255);
  setHint("Reconnect port receiver...", 3);
  
  // DEBUG
  setup=false;
  game_init();
}

void draw() {
  if(_constant_redraw){
    background(0);
    if(millis() > startMillis - 3000) draw_bricks();
  }
  
  // hint message
  fill(255, 0, min(255, map(hintFade - millis(), 0, hintFadeDuration, 0, 255)), 255);
  text(hintMsg, width/2, height - wu * 2);
  
  if(setup){ // port configuration
    for(String i : Serial.list()){
      if(!Arrays.asList().contains(i)){
        // on Linux, shorten to just the port name
        setHint(i.substring(i.lastIndexOf('/') + 1) + " connected, waiting for first packet", 3);
        ser = new Serial(this, i, _baud);
        game_init();
      }
    }
  }else{ // play ball
    ball_physics();
    draw_elements();
  }
}
