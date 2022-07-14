// Automatic generation, render, and evnetually hardware-setting
// of a dynamic maze

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
// rename variables and methods relating to trapezoids
// more functions / a class related to the maze file / move file functions into maze class

// 24x24

// Filename (in sketch folder) of maze to read
final static String FILENAME = "maze0.bin";
// How many frames per tile raise (30 = one second, 15 = half a second, etc.)
final static int FRAMES_PER_TILE = 4;
// Set antialiasing (1 = fast, jagged edges; 8 = slow, smooth edges)
final static int ANTIALIAS = 1;
// Call system.gc after each frame? (significant perf hit. memory use has been put under control so this should be left off)
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

int MAZE_WIDTH, MAZE_HEIGHT;

float index = 0.5;

byte file[];

Maze maze;

// initialize a few variables for the camera
void camInit() {
  camYaw = PI;
  camPitch = PI / 4;
  camDist = TRAP_WIDTH * MAZE_WIDTH * 1.5;
  camCenterX = MAZE_WIDTH * TRAP_WIDTH / 2 - TRAP_WIDTH / 2;
  camCenterY = MAZE_HEIGHT * TRAP_WIDTH / 2 - TRAP_WIDTH / 2;
  camUpdate();
}
// calculate where the camera should be
void camUpdate() {
  camX = camCenterX + camDist * cos(camPitch) * sin(camYaw);
  camY = camCenterY + camDist * cos(camPitch) * -cos(camYaw);
  camZ = camDist * sin(camPitch);
}
// set maze size variables from first two bytes of the file
void setsize() {
  MAZE_WIDTH = file[0] & 0xff;
  MAZE_HEIGHT = file[1] & 0xff;
}
// read the left four bits from an index in the file and shift over
byte lbyte(int index) {
  byte lbyte = byte((file[index] & 0xf0) >> 4);
  return lbyte;
}
// read right four bits from an index in the file
byte rbyte(int index) {
  byte rbyte = byte(file[index] & 0x0f);
  return rbyte;
}

void setup() {
  size(800, 800, P3D);
  frameRate(30);
  smooth(ANTIALIAS);
  perspective(FOV, ASPECT, CAMERAZ/10.0, CAMERAZ*250.0);

  file = loadBytes(FILENAME);
  setsize();
  maze = new Maze(MAZE_WIDTH, MAZE_HEIGHT);

  camInit();
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

  camera(camX, camY, camZ, camCenterX, camCenterY, 0, 0, 0, -1);

  // every x frames, set a tile to the state it should be
  if (!boolean(frameCount % FRAMES_PER_TILE)) {
    index += float(int(index < ((maze.numtiles / 2 + 0.5)))) / 2.0;
    if ((index % 1) == 0) {
      maze.tiles.get(floor(index) * 2 - 2).set(lbyte(floor(index) + 1));
    } else {
      maze.tiles.get(floor(index) * 2 - 1).set(rbyte(floor(index) + 1));
    }
  }

  // floor box
  pushMatrix();
  fill(255);
  translate(camCenterX, camCenterY, -TRAP_DEPTH * 0.1);
  box(camCenterX * 3, camCenterY * 3, TRAP_DEPTH);
  popMatrix();

  // render maze
  maze.render();

  if (COLLECT) {
    // force GC to reduce stutter
    System.gc();
  }
}
