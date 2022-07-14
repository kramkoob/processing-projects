// Functions related to rendering objests

// box width and height, and draw points
final static float TRAP_WIDTH = 200;
final static float TRAP_HEIGHT = TRAP_WIDTH / 16;
final static float TRAP_DEPTH = 50;

final static float TRAP_SHORT = TRAP_WIDTH - TRAP_HEIGHT * 2;
final static float TRAP_MIDDLE = (TRAP_WIDTH + TRAP_SHORT) / 2;

// random optimization tricks ?
static volatile float vx, vy;
static volatile float[] result = new float[2];                                                                                                               
static volatile int k;

// rotate point coordinates by angle
static float[] rotate(float vx, float vy, float angle) {
  result[0] = cos(angle) * vx - sin(angle) * vy;
  result[1] = sin(angle) * vx + cos(angle) * vy;
  return result;
}
// alternate that takes a 2-tuple list of coordinates
static float[] rotate(float[] v, float angle) {
  vx = v[0];
  vy = v[1];
  return rotate(vx, vy, angle);
}
static float[] add(float[] a, float[] b) {
  int len = a.length;
  result = new float[len];
  for (k = 0; k < len; k++) {
    result[k] = a[k] + b[k];
  }
  return result;
}

// draw a box
void rendTrap(float pos_x, float pos_y, float pos_z, float angle) {
  pushMatrix();
  fill(color(255, 255, 200));
  translate(pos_x, pos_y, pos_z);
  rotate(angle);
  box(TRAP_WIDTH, TRAP_HEIGHT, TRAP_DEPTH);
  popMatrix();
}
// alternate that takes a 2-tuple list of coordinates
void rendTrap(float[] posxy, float pos_z, float angle) {
  rendTrap(posxy[0], posxy[1], pos_z, angle);
}
