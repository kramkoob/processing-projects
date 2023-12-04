// Classes related to mazes and their tiles and walls

// how many milliseconds for walls to move up and down
final static int MOVE_MILLIS = 100;

// constants for ease of reading code
final static byte NORTH = 0b0001;
final static byte EAST = 0b0010;
final static byte SOUTH = 0b0100;
final static byte WEST = 0b1000;

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
  void render() {
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
      wall(movement / MOVE_MILLIS * TILE_HEIGHT, angle);
    } else {
      // if wall isn't animating then just draw it at its extreme high or low, no in-between
      wall(float(int(state)) * TILE_HEIGHT, angle);
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
    if ((side & NORTH) != 0) {
      return N;
    } else if  ((side & EAST) != 0) {
      return E;
    } else if  ((side & SOUTH) != 0) {
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

  // draw this tile
  public void render() {
    pushMatrix();
    // floor of tile
    translate(renderPos[0], renderPos[1], -WALL_LIP);
    pushMatrix();
    translate(-TILE_SIZE / 2, -TILE_SIZE / 2, TILE_HEIGHT / 2 + WALL_LIP);
    beginShape();
    fill(255);
    texture(FLOOR_TEXTURE);
    vertex(0, 0, 1, 0, 0);
    vertex(TILE_SIZE, 0, 1, 1, 0);
    vertex(TILE_SIZE, TILE_SIZE, 1, 1, 1);
    vertex(0, TILE_SIZE, 1, 0, 1);
    endShape();
    popMatrix();

    // the four walls
    for (k = 0; k <= 3; k++) {
      walls[k].render();
    }
    popMatrix();
  }
}

public class Maze {
  public int width, height;
  public final int numtiles;
  private int k, l;
  private byte[] file;
  public ArrayList<Tile> tiles = new ArrayList<Tile>();

  // Create an empty maze
  Maze(int width, int height) {
    this.width = width;
    this.height = height;
    numtiles = this.width * this.height;
    makeTiles();
  }

  // Load a maze from a file
  Maze(String filename) {
    file = loadBytes(filename);
    this.width = file[0] & 0xff;
    this.height = file[1] & 0xff;
    numtiles = this.width * this.height;
    makeTiles();
  }

  // create maze tiles
  private void makeTiles() {
    int[] pos = new int[2];
    for (k = 0; k < numtiles + 1; k++) {
      pos[0] = k % this.width;
      pos[1] = int(k / this.height);
      tiles.add(new Tile(pos));
    }
  }
  
  public void setTiles(boolean tilesSet) {
    for (k = 0; k < numtiles; k += 2) {
      if(tilesSet) {
        tiles.get(k).set(lbyte(floor(float(k / 2))));
        tiles.get(k + 1).set(rbyte(floor(float(k / 2))));
      }else{
        tiles.get(k).set(byte(0x00));
        tiles.get(k + 1).set(byte(0x00));
      }
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
    // tiles
    for (k = 0; k < numtiles; k++) {
      tiles.get(k).render();
    }

    // pillars
    for (k = 0; k < this.width + 1; k++) {
      for (l = 0; l < this.height + 1; l++) {
        pushMatrix();
        //fill(255, 220, 180);
        fill(255, 255, 255);
        translate(k * TILE_SIZE - PILLAR_CORNER, l * TILE_SIZE - PILLAR_CORNER, TILE_HEIGHT);
        box(PILLAR_SIZE, PILLAR_SIZE, TILE_HEIGHT);
        fill(255, 0, 0);
        beginShape(QUADS);
        vertex(-PILLAR_SIZE / 2, -PILLAR_SIZE / 2, TILE_HEIGHT / 2 + 1);
        vertex(PILLAR_SIZE / 2, -PILLAR_SIZE / 2, TILE_HEIGHT / 2 + 1);
        vertex(PILLAR_SIZE / 2, PILLAR_SIZE / 2, TILE_HEIGHT / 2 + 1);
        vertex(-PILLAR_SIZE / 2, PILLAR_SIZE / 2, TILE_HEIGHT / 2 + 1);
        endShape();
        popMatrix();
      }
    }
  }
}
