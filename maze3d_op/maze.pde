// Classes related to mazes and their tiles and walls

// how many milliseconds for walls to move up and down
final static int MOVE_MILLIS = 500;

// constants for ease of reading code
final static byte NORTH = 1;
final static byte EAST = 2;
final static byte SOUTH = 4;
final static byte WEST = 8;

// test optimization
volatile int sN, sE, sS, sW, count, returncount;
volatile boolean good;

public class Wall {
  boolean state = false;
  boolean moving = false;
  boolean lock = false;
  int lastSetTime;
  float angle;
  float movement;
  // default to unopened wall. angle always required
  Wall(float angle) {
    this(angle, false, false);
  }
  // make wall open or closed
  Wall(float angle, boolean state, boolean lock) {
    this.angle = angle;
    this.state = state;
    this.lock = lock;
  }
  void set(boolean set) {
    if (!lock && state != set) {
      state = set;
      lastSetTime = millis();
      moving = true;
    }
  }
  boolean get() {
    return state;
  }
  void lock() {
    lock = true;
  }
  void lock(boolean lock) {
    this.lock = lock;
  }
  // draw wall
  void render(float pos[]) {
    // if wall should animate due to a recent state change
    if (moving && !lock) {
      movement = millis() - lastSetTime;
      // if we have moved for our set time
      if (movement > MOVE_MILLIS) {
        moving = false;
        // set this to the maximum so it renders correctly this time around
        movement = MOVE_MILLIS;
      } else {
        if (state == false) {
          // if we've gone down, invert this so it moves/stays down
          movement = MOVE_MILLIS - movement;
        }
        // rendTrap(pos[0] + sin(angle) * TRAP_WIDTH, pos[1] + cos(angle) * TRAP_WIDTH, movement / MOVE_MILLIS * TRAP_DEPTH, angle);
        rendTrap(add(pos, rotate(0, TRAP_MIDDLE / 2, angle)), movement / MOVE_MILLIS * TRAP_DEPTH, angle);
      }
    } else {
      // if wall isn't animating then just draw it at its extreme high or low, no in-between
      // rendTrap(pos[0] + sin(angle) * TRAP_WIDTH, pos[1] + cos(angle) * TRAP_WIDTH, float(int(state)) * 50, angle);
      rendTrap(add(pos, rotate(0, TRAP_MIDDLE / 2, angle)), float(int(state)) * TRAP_DEPTH, angle);
    }
  }
}

// tile with four walls
public class Tile {
  int[] pos;
  float[] renderPos;
  Wall N, E, S, W;
  Wall[] walls = {N, E, S, W};
  int k;

  // create without declaring sides or locking
  Tile(int[] position) {
    this(position, byte(0), byte(0));
  }

  // create with locked sides (e.g. border walls)
  Tile(int[] position, byte side) {
    this(position, side, byte(0b1111));
  }

  // create declaring sides' states and lock status
  Tile(int[] position, byte side, byte lock) {
    newWalls(side, lock);
    pos = new int[2];
    pos = position;
    renderPos = new float[2];
    renderPos[0] = pos[0] * TRAP_WIDTH;
    renderPos[1] = pos[1] * TRAP_WIDTH;
  }

  // new walls
  protected void newWalls(byte sides, byte lock) {
    for (k = 0; k <= 3; k++) {
      walls[k] = new Wall(PI / 2 * k, ((sides >> k) & 1) == 1, ((lock >> k) & 1) == 1);
    }
  }

  // select walls from byte
  private Wall[] selmul(byte sides){
   sN = ((sides >> 0) & 1);
   sE = ((sides >> 1) & 1);
   sS = ((sides >> 2) & 1);
   sW = ((sides >> 3) & 1);
   count = sN + sE + sS + sW;
   Wall[] returns = new Wall[count];
   returncount = -1;
   if(sN == 1){returns[++returncount] = N;};
   if(sE == 1){returns[++returncount] = E;};
   if(sS == 1){returns[++returncount] = S;};
   if(sW == 1){returns[++returncount] = W;};
   return returns;
   }
   
  protected Wall sel(byte side) {
    if       ((side & 0b0001) != 0)  {return N;}
    else if  ((side & 0b0010) != 0)  {return E;}
    else if  ((side & 0b0100) != 0)  {return S;}
    else                             {return W;}
  }

  // public functions
  // is a wall up
  boolean up(byte side) {
    return sel(side).get();
  }
  //boolean upmul(byte side){
  //  return selmul(side)[0].get();
  //}

  // raise a wall
  public void raise(byte side) {
    sel(side).set(true);
  }
  //void raisemul(byte side){
  //  selmul(side)[0].set(true);
  //}

  // lower a wall
  //void lower(byte side){
  //  selmul(side)[0].set(false);
  //}

  // set states of all walls
  public void set(byte sides) {
    for (k = 0; k <= 3; k++) {
      walls[k].set(((sides >> k) & 1) == 1);
    }
  }

  public void render() {
    for (Wall v : walls) {
      v.render(renderPos);
    }
  }
}

public class Maze {
  public int size_x, size_y;
  public final int numtiles;
  private int k;
  private int[] pos = new int[2];
  public ArrayList<Tile> tiles = new ArrayList<Tile>();
  
  Maze(int size_x, int size_y) {
    numtiles = size_x * size_y;
    for(k = 0; k < numtiles; k++){
      this.pos[0] = k % MAZE_WIDTH;
      this.pos[1] = int(k / MAZE_WIDTH);
      tiles.add(new Tile(pos));
    }
  }
  
  public void render(){
    for(Tile v : tiles){
      v.render();
    }
  }
}
