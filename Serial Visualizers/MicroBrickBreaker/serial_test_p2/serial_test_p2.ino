uint8_t buf[10];

void setup() {
  // put your setup code here, to run once:
  Serial.begin(19200);
}

void loop() {
  // put your main code here, to run repeatedly:
  for(int i = 0; i < 100; i++){
    buf[0] = 0x80;
    buf[1] = 0x82;
    buf[2] = 0x05;
    buf[3] = 0x00;
    buf[4] = 0x01;
    buf[5] = 0x81;
    Serial.write(buf,6);
  }
  delay(100);
  while(1){
    buf[1] = 0x83;
    // buf[4] = int(float(sin(float(millis()) / 600.0) * 63.5 + 63.5));
    buf[4] = analogRead(A0) >> 3;
    Serial.write(buf, 6);
  }
}
