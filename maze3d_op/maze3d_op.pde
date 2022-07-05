// Automatic generation, render, and evnetually hardware-setting
// of a dynamic micromouse-inspired maze

// 24x24

float camDist, camYaw, camPitch;
int lastmouseX, lastmouseY;
float lastcamDist, lastcamYaw, lastcamPitch;
boolean lastmouseGood, ctrl, lastmouseCtrl;

float camX, camY, camZ;
float camCenterX, camCenterY;

final static int MAZE_WIDTH = 4;
final static int MAZE_HEIGHT = 4;

final static int ANTIALIAS = 4;

Maze maze;

// attempted optimization

void camUpdate() {
  camX = camCenterX + camDist * cos(camPitch) * sin(camYaw);
  camY = camCenterY + camDist * cos(camPitch) * -cos(camYaw);
  camZ = camDist * sin(camPitch);
}

void setup() {
  size(800, 800, P3D);
  frameRate(30);
  smooth(ANTIALIAS);

  camPitch = radians(30);
  camDist = TRAP_WIDTH * MAZE_WIDTH * 1.5;
  camCenterX = MAZE_WIDTH * TRAP_WIDTH / 2 - TRAP_WIDTH / 2;
  camCenterY = MAZE_HEIGHT * TRAP_WIDTH / 2 - TRAP_WIDTH / 2;
  camUpdate();

  maze = new Maze(MAZE_WIDTH, MAZE_HEIGHT);
}

// if ctrl is pressed
void keyPressed() {
  if (!ctrl & keyCode == CONTROL) {
    ctrl = true;
  }
}
// reset the "if ctrl is pressed" variable if a key is released
void keyReleased() {
  ctrl = false;
}

int lastKey;

void draw() {
  background(220);
  lights();

  // drag mouse to adjust camera, hold ctrl to zoom
  if (mousePressed) {
    if (!lastmouseGood) {
      lastmouseX = mouseX;
      lastmouseY = mouseY;
      lastmouseGood = true;
      lastmouseCtrl = ctrl;
      lastcamDist = camDist;
      lastcamPitch = camPitch;
      lastcamYaw = camYaw;
    } else {
      if (lastmouseCtrl) {
        camDist = lastcamDist + (float(mouseY) - lastmouseY);
      } else {
        camPitch = lastcamPitch + (float(mouseY) - lastmouseY) / 250;
      }
      camYaw = lastcamYaw + (float(mouseX) - lastmouseX) / 250;
      camUpdate();
    }
  } else {
    lastmouseGood = false;
  }

  // orbiting camera
  camera(camX, camY, camZ, camCenterX, camCenterY, 0, 0, 0, -1);

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


  if (key != lastKey) {
    maze.tiles.get(0).set(byte(key));
    lastKey = key;
  }

  maze.render();
  System.gc();
}
