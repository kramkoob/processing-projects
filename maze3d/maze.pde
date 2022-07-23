// Classes related to mazes and their tiles and walls

// how many milliseconds for walls to move up and down
final static int MOVE_MILLIS = 1000;

// constants for ease of reading code
final static byte NORTH = 1;
final static byte EAST = 2;
final static byte SOUTH = 4;
final static byte WEST = 8;

public class Wall {
  boolean state = false;
  boolean moving = false;
  boolean lock = false;
  int lastSetTime;
  float angle, movement;
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
      }
      if (state == false) {
        // if we've gone down, invert this so it moves/stays down
        movement = MOVE_MILLIS - movement;
      }
      wall(pos, movement / MOVE_MILLIS * TILE_HEIGHT, angle);
    } else {
      // if wall isn't animating then just draw it at its extreme high or low, no in-between
      wall(pos, float(int(state)) * TILE_HEIGHT, angle);
    }
  }
}

// tile with four walls
public class Tile {
  int[] pos;
  Wall N, E, S, W;
  protected float[] renderPos;
  protected Wall[] walls = {N, E, S, W};
  private int k;

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
    renderPos[0] = pos[0] * TILE_SIZE;
    renderPos[1] = pos[1] * TILE_SIZE;
  }

  // new walls
  protected void newWalls(byte sides, byte lock) {
    for (k = 0; k <= 3; k++) {
      walls[k] = new Wall(PI / 2 * k, ((sides >> k) & 1) == 1, ((lock >> k) & 1) == 1);
    }
  }

  protected Wall sel(byte side) {
    if ((side & 0b0001) != 0) {
      return N;
    } else if  ((side & 0b0010) != 0) {
      return E;
    } else if  ((side & 0b0100) != 0) {
      return S;
    } else {
      return W;
    }
  }

  // public functions
  // is a wall up
  boolean up(byte side) {
    return sel(side).get();
  }

  // raise a wall
  public void raise(byte side) {
    sel(side).set(true);
  }

  // set states of all walls
  public void set(byte sides) {
    for (k = 0; k <= 3; k++) {
      walls[k].set(((sides >> k) & 1) == 1);
    }
  }

  public void render() {
    for (k = 0; k <= 3; k++) {
      walls[k].render(renderPos);
    }
  }
}

public class Maze {
  public int size_x, size_y;
  public final int numtiles, vis_width, vis_height;
  private int k, l;
  private byte[] file;
  public ArrayList<Tile> tiles = new ArrayList<Tile>();

  // Create an empty maze
  Maze(int size_x, int size_y) {
    numtiles = size_x * size_y;
    vis_width = int(TILE_SIZE * size_x);
    vis_height = int(TILE_SIZE * size_y);
    makeTiles();
  }

  // Load a maze from a file
  Maze(String filename) {
    file = loadBytes(filename);
    size_x = file[0] & 0xff;
    size_y = file[1] & 0xff;
    numtiles = size_x * size_y;
    vis_width = int(TILE_SIZE * size_x);
    vis_height = int(TILE_SIZE * size_y);
    makeTiles();
    for (k = 0; k < numtiles; k += 2) {
      tiles.get(k).set(lbyte(floor(float(k / 2))));
      tiles.get(k + 1).set(rbyte(floor(float(k / 2))));
    }
  }

  // create maze tiles
  private void makeTiles() {
    int[] pos = new int[2];
    for (k = 0; k < numtiles; k++) {
      pos[0] = k % size_x;
      pos[1] = int(k / size_y);
      tiles.add(new Tile(pos));
    }
  }

  // read the left four bits from an index in the file contents and shift over
  private byte lbyte(int index) {
    byte lbyte = byte((file[index + 2] & 0xf0) >> 4);
    return lbyte;
  }
  // read right four bits from an index in the file contents
  private byte rbyte(int index) {
    byte rbyte = byte(file[index + 2] & 0x0f);
    return rbyte;
  }

  // draw maze
  public void render() {
    // floor
    pushMatrix();
    fill(255);
    translate(camCenterX, camCenterY, -TILE_HEIGHT * 0.1);
    box(camCenterX * 3, camCenterY * 3, TILE_HEIGHT);
    popMatrix();

    // tiles
    for (k = 0; k < numtiles; k++) {
      //tiles
      tiles.get(k).render();
    }

    // pillars
    for (k = 0; k < size_x + 1; k++) {
      for (l = 0; l < size_y + 1; l++) {
        pushMatrix();
        fill(255, 220, 180);
        translate(k * TILE_SIZE - PILLAR_CORNER, l * TILE_SIZE - PILLAR_CORNER, TILE_HEIGHT);
        box(PILLAR_SIZE, PILLAR_SIZE, TILE_HEIGHT);
        popMatrix();
      }
    }
  }
}
