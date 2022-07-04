// Automatic generation, render, and evnetually hardware-setting
// of a dynamic micromouse-inspired maze

// 24x24

float camDist, camYaw, camPitch;
int lastmouseX, lastmouseY;
float lastcamDist, lastcamYaw, lastcamPitch;
boolean lastmouseGood, ctrl, lastmouseCtrl;

final static int MAZE_WIDTH = 4;
final static int MAZE_HEIGHT = 4;
final static int MAZE_TILES = MAZE_WIDTH * MAZE_HEIGHT;
ArrayList<Tile> tiles = new ArrayList<Tile>();

void setup(){
  size(1200, 1200, P3D);
  frameRate(1);
  camPitch = radians(30);
  camDist = 300;
  
  for(int k = 0; k < MAZE_TILES; k++){
    int[] pos = {k % MAZE_WIDTH, int(k / MAZE_WIDTH)};
    tiles.add(new Tile(pos));
    println("New tile at " + pos[0] + ", " + pos[1]);
  }
}

// if ctrl is pressed
void keyPressed() {
  if (!ctrl & keyCode == CONTROL){
    ctrl = true;
  }
}
// reset the "if ctrl is pressed" variable if a key is released
void keyReleased(){
  ctrl = false;
}

int lastKey;

void draw(){
  background(220);
  
  // drag mouse to adjust camera, hold ctrl to zoom
  if(mousePressed) {
    if(!lastmouseGood){
      lastmouseX = mouseX;
      lastmouseY = mouseY;
      lastmouseGood = true;
      lastmouseCtrl = ctrl;
      lastcamDist = camDist;
      lastcamPitch = camPitch;
      lastcamYaw = camYaw;
    }else{
      if(lastmouseCtrl){
        camDist = lastcamDist + (float(mouseY) - lastmouseY);
      }else{
        camPitch = lastcamPitch + (float(mouseY) - lastmouseY) / 250;
      }
      camYaw = lastcamYaw + (float(mouseX) - lastmouseX) / 250;
    }
  }else{
    lastmouseGood = false;
  }
  
  // orbiting camera
  camera(camDist * cos(camPitch) * sin(camYaw), camDist * cos(camPitch) * -cos(camYaw), camDist * sin(camPitch), 0, 0, 0, 0, 0, -1);
  
  /*
  // random box as a plane to show camera's rotation
  fill(100);
  // move into position
  translate(0, 0, -TRAP_DEPTH / 1.8);
  box(300, 300, TRAP_DEPTH);
  // move out of position (not sure how this function works 100%)
  translate(0, 0, TRAP_DEPTH / 1.8);
  */
  
  // for(int k = 0; k < numtiles; k++){
  //   tiles.get(k).render();
  // }
  
  
  if(key != lastKey){
    tiles.get(0).set(byte(key));
    lastKey = key;
  }
  
  for(Tile v : tiles){
    v.render();
  }
}
