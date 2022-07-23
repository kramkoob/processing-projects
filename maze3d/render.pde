// Functions related to rendering objests

// box width and height, and draw points
final static float TILE_SIZE = 200;
final static float TILE_HEIGHT = 50;
final static float WALL_LENGTH = 0.8 * TILE_SIZE;
final static float WALL_WIDTH = 0.1 * TILE_SIZE;
final static float WALL_CENTER_DIST = (TILE_SIZE - WALL_WIDTH) / 2;
final static float PILLAR_SIZE = TILE_SIZE - WALL_LENGTH;
final static float PILLAR_CORNER = TILE_SIZE / 2;

// draw wall
void wall(float pos_x, float pos_y, float pos_z, float angle) {
  pushMatrix();
  fill(color(255, 255, 200));
  translate(pos_x, pos_y, pos_z);
  rotate(angle);
  translate(0, WALL_CENTER_DIST, 0);
  box(WALL_LENGTH, WALL_WIDTH, TILE_HEIGHT);
  popMatrix();
}

// alternate draw wall that takes a 2-tuple list of coordinates
void wall(float[] posxy, float pos_z, float angle) {
  wall(posxy[0], posxy[1], pos_z, angle);
}
