// Functions related to rendering objests

// trapezoid width and height, and draw points
final static float TRAP_WIDTH = 200;
final static float TRAP_HEIGHT = TRAP_WIDTH / 16;
final static float TRAP_DEPTH = 50;

final static float TRAP_SHORT = TRAP_WIDTH - TRAP_HEIGHT * 2;
final static float TRAP_MIDDLE = (TRAP_WIDTH + TRAP_SHORT) / 2;
final static float[] TRAP_POINTS = {-TRAP_WIDTH / 2, TRAP_HEIGHT / 2,
                             -TRAP_SHORT / 2, -TRAP_HEIGHT / 2,
                             TRAP_SHORT / 2, -TRAP_HEIGHT / 2,
                             TRAP_WIDTH / 2, TRAP_HEIGHT / 2,
                             -TRAP_WIDTH / 2, TRAP_HEIGHT / 2};

// attempt optimization
// volatile float[] v = new float[2];
static volatile float vx, vy;
static volatile float[] result = new float[2];
static volatile float[] v = new float[2];
static volatile int k;
static volatile PShape sh;

// rotate point coordinates by angle
static float[] rotate(float vx, float vy, float angle){
  result[0] = cos(angle) * vx - sin(angle) * vy;
  result[1] = sin(angle) * vx + cos(angle) * vy;
  return result;
}
// alternate that takes a 2-tuple list of coordinates
static float[] rotate(float[] v, float angle){
  vx = v[0];
  vy = v[1];
  return rotate(vx, vy, angle);
}
static float[] add(float[] a, float[] b){
  result = new float[a.length];
  for(k = 0; k < result.length; k++){
    result[k] = a[k] + b[k];
  }
  return result;
}

// draw a trapezoid
void rendTrap(float pos_x, float pos_y, float pos_z, float angle){
  sh = createShape();
  sh.beginShape(QUADS);
  // color
  sh.fill(color(255, 255, 200));
  
  // top
  for(k = 0; k <= 3; k++){
    vx = TRAP_POINTS[k * 2];
    vy = TRAP_POINTS[k * 2 + 1];
    v[0] = vx;
    v[1] = vy;
    v = rotate(v, angle);
    vx = v[0];
    vy = v[1];
    sh.vertex(vx, vy, 0);
  }
  
  // sides
  for(k = 0; k <= 3; k++){
    vx = TRAP_POINTS[k * 2];
    vy = TRAP_POINTS[k * 2 + 1];
    v[0] = vx;
    v[1] = vy;
    v = rotate(v, angle);
    vx = v[0];
    vy = v[1];
    sh.vertex(vx, vy, -TRAP_DEPTH);
    sh.vertex(vx, vy, 0);
    
    vx = TRAP_POINTS[k * 2 + 2];
    vy = TRAP_POINTS[k * 2 + 3];
    v[0] = vx;
    v[1] = vy;
    v = rotate(v, angle);
    vx = v[0];
    vy = v[1];
    sh.vertex(vx, vy, 0);
    sh.vertex(vx, vy, -TRAP_DEPTH);
  }
  
  // move
  sh.translate(pos_x, pos_y, pos_z);
  sh.endShape(CLOSE);
  
  // draw
  shape(sh, 0, 0);
}
// alternate that takes a 2-tuple list of coordinates (direct use of rotation function for instance) 
void rendTrap(float[] posxy, float pos_z, float angle){
  rendTrap(posxy[0], posxy[1], pos_z, angle);
}
