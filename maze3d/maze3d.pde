// Automatic generation/loading, render, and hardware-setting
// of a dynamic maze

// Thomas Dodds
// July 2022

// File format: first two bytes are width and height respectively
// Following bytes are two 4-bit pairs (each) defining tile sides
// Bit 0: north
// Bit 1: east
// Bit 2: south
// Bit 3: west

// to-do:
// pre-check maze file for errors
// menus
// textured floor and tops of walls

// Filename (in sketch folder) of maze to read
final static String FILENAME = "maze0.bin";

// Set antialiasing (1 = fast, jagged edges; 8 = slow, smooth edges)
final static int ANTIALIAS = 1;

// Set framerate (default 30)
final static int FRAMERATE = 30;

// Call system.gc after each frame? (test purposes. large perf hit, should always be off)
final static boolean COLLECT = false;


final static float FOV = PI / 3.0;
final float ASPECT = float(width) / float(height);
final float CAMERAZ = (height/2.0) / tan(FOV/2.0);

float camDist, camYaw, camPitch;
int lastmouseX, lastmouseY;
float lastcamDist, lastcamYaw, lastcamPitch;
boolean lastmouseGood, ctrl, lastmouseCtrl;

float camX, camY, camZ;
float camCenterX, camCenterY;

Maze maze;

// initialize a few variables for the camera
void camInit(Maze maze) {
  camYaw = PI;
  camPitch = PI / 4;
  camDist = TILE_SIZE * maze.size_x * 1.5;
  camCenterX = maze.size_x * TILE_SIZE / 2 - TILE_SIZE / 2;
  camCenterY = maze.size_y * TILE_SIZE / 2 - TILE_SIZE / 2;
  camUpdate();
}
// calculate where the camera should be and move it there
void camUpdate() {
  camX = camCenterX + camDist * cos(camPitch) * sin(camYaw);
  camY = camCenterY + camDist * cos(camPitch) * -cos(camYaw);
  camZ = camDist * sin(camPitch);
  camera(camX, camY, camZ, camCenterX, camCenterY, 0, 0, 0, -1);
}

void setup() {
  size(800, 800, P3D);
  frameRate(FRAMERATE);
  smooth(ANTIALIAS);
  perspective(FOV, ASPECT, CAMERAZ/10.0, CAMERAZ*250.0);

  maze = new Maze(FILENAME);

  camInit(maze);
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

  // render maze
  maze.render();

  if (COLLECT) {
    // force GC to reduce stutter
    System.gc();
  }
}
