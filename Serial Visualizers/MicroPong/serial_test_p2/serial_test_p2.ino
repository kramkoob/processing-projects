uint8_t buf[10];

void setup() {
  // put your setup code here, to run once:
  Serial.begin(38400);
  buf[0] = 0x80;
  buf[1] = 0x82;
  buf[2] = 0x07;
  buf[3] = 0x05;
  buf[4] = 0x01;
  buf[5] = 0x81;
  Serial.write(buf,6);
  buf[1] = 0x83;
}

void loop() {
  // put your main code here, to run repeatedly:
  buf[4] = analogRead(A0) >> 3;
  Serial.write(buf, 6);
  delay(1000/60);
}
