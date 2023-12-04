// Functions related to rendering objests
// All units here should correspond to real-life millimeters

// Our maze is 24x24 on a 12' field, yielding 6" tiles
// This is about 152.4mm, rounded for ease to 152mm
// Black electrical tape - as a starting number - is sometimes 3/4"
// This is about 19.05mm, rounded for ease to 19mm

// box width and height, and draw points
// for a 24x24 maze spanning 12'x12', this is 6" in mm

// floro blacko
// wallos whitdos
// wallotoppo redo

final static int TILE_SIZE = 152;
// 3" in mm
final static float TILE_HEIGHT = 76;
final static float WALL_LENGTH = 0.9 * TILE_SIZE;
final static float WALL_WIDTH = 0.05 * TILE_SIZE;
final static float WALL_CENTER_DIST = (TILE_SIZE - WALL_WIDTH) / 2;
final static float PILLAR_SIZE = TILE_SIZE - WALL_LENGTH;
final static float PILLAR_CORNER = TILE_SIZE / 2;
final static float WALL_LIP = 1;

final static int LINE_WIDTH = 10;

volatile int k, l;

// draw wall (MUST be in another matrix where position has already been set!)
void wall(float pos_z, float angle) {
  pushMatrix();
  //fill(color(255, 255, 200));
  fill(color(255));
  rotate(angle + PI);
  translate(0, WALL_CENTER_DIST, pos_z);
  box(WALL_LENGTH, WALL_WIDTH, TILE_HEIGHT);
  fill(color(255,0,0));
  beginShape(QUADS);
  vertex(-WALL_LENGTH / 2, -WALL_WIDTH / 2, TILE_HEIGHT / 2 + 1);
  vertex(WALL_LENGTH / 2, -WALL_WIDTH / 2, TILE_HEIGHT / 2 + 1);
  vertex(WALL_LENGTH / 2, WALL_WIDTH / 2, TILE_HEIGHT / 2 + 1);
  vertex(-WALL_LENGTH / 2, WALL_WIDTH / 2, TILE_HEIGHT / 2 + 1);
  endShape();
  popMatrix();
}

// create and return floor line texture
PImage makeFloorTexture() {
  PImage tex = createImage(TILE_SIZE, TILE_SIZE, RGB);
  int texsize = TILE_SIZE * TILE_SIZE;
  //int halftile = TILE_SIZE / 2;
  //int halfline = LINE_WIDTH / 2;
  //int x, y;
  tex.loadPixels();
  for (k = 0; k < texsize; k++) {
    /*
    x = k % TILE_SIZE;
    y = floor(k / TILE_SIZE);
    if (!(((x > (halftile - halfline)) && (x < (halftile + halfline))) || ((y > (halftile - halfline)) && (y < (halftile + halfline)))) ){
      tex.pixels[k] = color(255, 255, 255);
    }
    */
    tex.pixels[k] = color(0);
  }
  tex.updatePixels();
  return tex;
}
