final static byte game_width = 16;
final static byte game_height = 16;
final static int millis_per_tick = 170;

int len;
int[] pre_x, pre_y;
int dir_x, dir_y;
int apple_x, apple_y;
int lastMove;
boolean gameOn;

boolean testInSnake(int test_x, int test_y){
  boolean result = false;
  for(int k = 1; k < len; k++){
    int exist_x = pre_x[k];
    int exist_y = pre_y[k];
    if((test_x == exist_x) & (test_y == exist_y)){
      result = true;
      break;
    }
  }
  return result;
}
void newApple(){
  byte try_x, try_y;
  do{
    try_x = byte(random(0, game_width));
    try_y = byte(random(0, game_height));
  }while(testInSnake(try_x, try_y));
  apple_x = try_x;
  apple_y = try_y;
}

void newGame(){
  // put a 3-long snake in the middle of the screen
  pre_x = new int[game_width * game_height];
  pre_y = new int[game_width * game_height];
  pre_x[0] = byte(game_width / 2);
  pre_y[0] = byte(game_height / 2);
  pre_x[1] = byte(pre_x[0] - 1);
  pre_y[1] = byte(pre_y[0]);
  pre_x[2] = byte(pre_x[1] - 1);
  pre_y[2] = byte(pre_y[1]);
  len = 3;
  dir_x = 1;
  dir_y = 0;
  newApple();
  lastMove = millis();
  gameOn = true;
}

void setup(){
  size(600, 600, P2D);
  frameRate(60);

  newGame();
}

void draw(){
  // Input
  switch(key){
    case 'w':
      if(pre_y[1] >= pre_y[0]){
        dir_x = 0;
        dir_y = -1;
      }
      break;
    case 'a':
      if(pre_x[1] >= pre_x[0]){
        dir_x = -1;
        dir_y = 0;
      }
      break;
    case 's':
      if(pre_y[1] <= pre_y[0]){
        dir_x = 0;
        dir_y = 1;
      }
      break;
    case 'd':
      if(pre_x[1] <= pre_x[0]){
        dir_x = 1;
        dir_y = 0;
      }
      break;
  }
  
  // Snake
  if((millis() - lastMove) > millis_per_tick & gameOn){
    lastMove = millis();
    int first_x = pre_x[0];
    int first_y = pre_y[0];
    int last_x = pre_x[len - 1];
    int last_y = pre_y[len - 1];
    // Run into self
    if(testInSnake(pre_x[0], pre_y[0])){
      gameOn = false;
    }else{
      // Advance snake forward
      for(int k = len; k > 0; k--){
        pre_x[k] = pre_x[k - 1];
        pre_y[k] = pre_y[k - 1];
      }
      pre_x[0] = first_x + int(dir_x);
      pre_y[0] = first_y + int(dir_y);
    }
    // Apple nom
    if((pre_x[0] == apple_x) & (pre_y[0] == apple_y)){
      pre_x[++len] = last_x;
      pre_y[len] = last_y;
      newApple();
    };
    // Hit wall
    if(pre_x[0] < 0 | pre_x[0] > game_width - 1 | pre_y[0] < 0 | pre_y[0] > game_height - 1){
      gameOn = false;
    }
  }
  
  // Render
  background(0, 170, 0);
  noStroke();
  fill(0, 255, 0);
  for(int k = 0; k < len; k++){
    rect(pre_x[k] * width / game_width, pre_y[k] * height / game_height, width / game_width, height / game_height);
  }
  fill(255, 70, 30);
  rect(apple_x * width / game_width, apple_y * height / game_height, width / game_width, height / game_height);
  
  fill(200, 0, 0);
  rect((pre_x[0] + float(dir_x) / 2 + 0.25) * width / game_width, (pre_y[0] + float(dir_y) / 2 + 0.25) * height / game_height, width / game_width / 2, height / game_height / 2);
  
  fill(0);
  if(!gameOn){
    text("Space to restart", 20, 20);
    if(key == ' '){
      newGame();
    }
  }
  text("Score: " + (len - 3), width - 60, 20);
}
