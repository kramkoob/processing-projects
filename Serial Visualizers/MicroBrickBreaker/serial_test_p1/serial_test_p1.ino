/*
 * Test program for MicroBrickBreaker. Waits, sends a numpad sequence, then simulates analog input.
 */
 
#define PACKET_STX 0x80
#define PACKET_ETX 0x81
/*
#define PACKET_CMD_BUTTON 0x00
#define PACKET_CMD_ANALOG 0x01
#define PACKET_CMD_NUMPAD 0x02
*/

uint8_t buf[10];

 /*
void send_packet(uint8_t cmd, uint8_t single_data){
  int n = -1;
  buf[++n] = PACKET_STX;
  buf[++n] = 1;
  buf[++n] = cmd;
  buf[++n] = single_data;
  buf[++n] = PACKET_ETX;
  Serial.write(buf, n + 1);
}

void send_packet(uint8_t cmd, String data){
  int n = -1;
  buf[++n] = PACKET_STX;
  buf[++n] = byte(data.length());
  buf[++n] = cmd;
  for(int i = 0; i < data.length(); i++){
    buf[++n] = byte(data[i]);
  }
  buf[++n] = PACKET_ETX;
  Serial.write(buf, n + 1);
}
*/

void send_packet(uint8_t buttons, uint8_t keypad, uint8_t analog){
  int n = -1;
  buf[++n] = PACKET_STX;
  buf[++n] = buttons;
  buf[++n] = keypad;
  buf[++n] = analog;
  buf[++n] = PACKET_ETX;
  Serial.write(buf, n + 1);
}

void blink_countdown(){
  for(int i = 1; i < 9; i++){
    digitalWrite(13, i % 2);
    delay((i > 4) ? 250 : 500);
  }
}

void trap(float s, uint8_t b, uint8_t k, uint8_t a){
  int cm = millis();
  while(millis() < (cm + s * 1000.0)){
    send_packet(b, k, a);
    delay(50);
  }
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(13, OUTPUT);

  /*
  blink_countdown();
  send_packet(PACKET_CMD_BUTTON, LOW);
  blink_sending(2);
  send_packet(PACKET_CMD_BUTTON, HIGH);
  blink_sending(0);
  send_packet(PACKET_CMD_BUTTON, LOW);
  blink_sending(4);
  send_packet(PACKET_CMD_NUMPAD, 2);
  */

  blink_countdown();
  trap(2, 0, 17, 0);
  trap(0.25, 0, 5, 0);
  trap(0.25, 0, 17, 0);
  trap(0.25, 0, 0, 0);
  trap(0.25, 0, 17, 0);
  trap(0.25, 0, 1, 0);
  
}

void loop() {
  // put your main code here, to run repeatedly:

}
