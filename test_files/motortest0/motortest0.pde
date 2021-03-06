#include <AFMotor.h>

AF_DCMotor motor(4); // create motor #2, 64KHz pwm
AF_DCMotor motor2(3);

void setup() {
 Serial.begin(9600);           // set up Serial library at 9600 bps
 Serial.println("Motor test!");

 motor.setSpeed(200);     // set the speed to 200/255
 motor2.setSpeed(200);
}

void loop() {
 Serial.print("tick");

 motor.run(FORWARD);      // turn it on going forward
 motor2.run(FORWARD);
 delay(1000);

 Serial.print("tock");
 motor.run(BACKWARD);     // the other way
 motor2.run(BACKWARD);
 delay(1000);

 Serial.print("tack");
 motor.run(RELEASE);      // stopped
 motor2.run(RELEASE);
 delay(1000);
}
