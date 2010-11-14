#include <Wire.h>
#include <AFMotor.h>

int rspeed,lspeed;
int HMC6352Address = 0x42;
int slaveAddress;
int ledPin = 13;
int i, headingValue;
byte headingData[2];
boolean ledState = false;
static int RIGHT = 0,LEFT = 1,AHEAD = 0, BACK = 1;
AF_DCMotor rmotor(4),lmotor(3);//right motor, left motor

/*
  Shift the device's documented slave address (0x42) 1 bit right
  This compensates for how the TWI library only wants the
  7 most significant bits (with the high bit padded with 0)
*/
void setup(){
  slaveAddress = HMC6352Address >> 1;   // This results in 0x21 as the address to pass to TWI
 
  Serial.begin(9600);
  pinMode(ledPin, OUTPUT);      // Set the LED pin as output
  Wire.begin();
}//end setup function

/*
  Begin continuous loop
*/
void loop(){
  
  /*
   //testing turns
   straight(AHEAD,250,2000);
   mturn(RIGHT,1200);
   straight(AHEAD,250,2000);
   mturn(RIGHT,1200);
   straight(AHEAD,250,2000);
   mturn(RIGHT,1200);
   straight(AHEAD,250,2000);
   mturn(RIGHT,1200);
   stp(5000);
  */
  
  blinkLed();
  getCmpData();
  setHeading();
  printHeading();
 
}//end loop function

/*
  Print the current heading to the serial port
*/
void printHeading(){
  Serial.print("Current heading: ");
  Serial.print(int (headingValue / 10));     // The whole number part of the heading
  Serial.print(".");
  Serial.print(int (headingValue % 10));     // The fractional part of the heading
  Serial.println(" degrees");
}//end printHeading function

/*
  Read the 2 heading bytes, MSB first
  The resulting 16bit word is the compass heading in 10th's of a degree
  For example: a heading of 1345 would be 134.5 degrees
*/
void setHeading(){
    Wire.requestFrom(slaveAddress, 2);        // Request the 2 byte heading (MSB comes first)
  i = 0;
  while(Wire.available() && i < 2)
  { 
    headingData[i] = Wire.receive();
    i++;
  }

  headingValue = headingData[0]*256 + headingData[1];  // Put the MSB and LSB together
}//end setHeading function

/*
  Flash the LED on pin 13 just to show that something is happening
  Also serves as an indication that we're not "stuck" waiting for TWI data
 */
void blinkLed(void){
  ledState = !ledState;
  if (ledState) {
    digitalWrite(ledPin,HIGH);
  }
  else
  {
    digitalWrite(ledPin,LOW);
  }
}//end blinkLed function

/*
  Send a "A" command to the HMC6352 compass
  This requests the current heading data
 */
void getCmpData(void){
  Wire.beginTransmission(slaveAddress);
  Wire.send("A");              // The "Get Data" command
  Wire.endTransmission();
  delay(10);                   // The HMC6352 needs at least a 70us (microsecond) delay
                               // after this command.  Using 10ms just makes it safe 
}//end getData function

/*
  Travel straight
  @direction - the direction to travel (AHEAD or BACK)
  @speed - the speed at which to travel (0-255)
  @msecs - the number of miliseconds to spend traveling
*/
int straight(int direction,int speed,int msecs){
  if(speed > 0 && speed < 256){//if the speed is valid
    rmotor.setSpeed(speed);
    lmotor.setSpeed(speed);
    if(direction == AHEAD){
      rmotor.run(FORWARD);
      lmotor.run(FORWARD);
      delay(msecs);
    }//end if
    else if(direction == BACK){
      rmotor.run(BACKWARD);
      lmotor.run(BACKWARD);
      delay(msecs);
    }//end else if
    else{
      Serial.print("Attention: direction entered '");
      Serial.print(direction);
      Serial.print("' invalid.\n");
      return 1;
    }//end else
  }//end if
  else{//if the speed is invalid
    Serial.print("Attention: speed entered '");
    Serial.print(speed);
    Serial.print("' invalid.\n");
    return 1;
  }//end else
  return 0;
}//end straight function
/*
  Safely slow both motors down to a stop 
  @msecs - the number of miliseconds to spend slowing down
*/
int safestop(int msecs){
  if(msecs < 100){//if little time is left
    stp();
  }//end if
  else{
    //cut speed in half
    rmotor.setSpeed(rspeed * .5);
    lmotor.setSpeed(lspeed * .5);
    //cut time in half
    msecs = msecs * .5;
    delay(msecs);
    safestop(msecs);//making a recursive call to safestop
  }//end else
  return 0;
}//end mslow function

/*
  Stop both motors
  @msecs - the number of miliseconds to stop for
*/
int stp(){
  rmotor.run(RELEASE);
  lmotor.run(RELEASE);
  delay(msecs);
  return 0;
}//end mstop function

/*
  Navigate a right or left pivot turn
  @direction - the direction to turn (RIGHT or LEFT)
  @msecs - the number of miliseconds to turn for
*/
int mturn(int direction,int msecs){
  //set motor speed to ~40%
  rspeed = 200;
  lspeed = 200;
  rmotor.setSpeed(rspeed);
  lmotor.setSpeed(lspeed);
  if(direction == RIGHT){
    //pivot right
    rmotor.run(BACKWARD);
    lmotor.run(FORWARD);
  }//end if
  else if(direction == LEFT){
    //pivot left
    rmotor.run(FORWARD);
    lmotor.run(BACKWARD);
  }//end else if
  else{//direction parameter was entered incorrectly
    Serial.print("Attention: direction entered '");
    Serial.print(direction);
    Serial.print("' invalid.\n");
    return 1;
  }//end else
  delay(msecs);
  return 0;
}//end turn function

/*
  Read information from the serial port
*/
char readFromSerial() { //main loop

    char serialString;

    if (Serial.available() > 0) { //if there is anything on the serial port, read it
        serialString = Serial.read(); //store it in the serialString variable
    }//end if
    if (atoi(serialString) > 0) { //if we read something
        //validate read (it may be a read with poor signal)
        //if(valid read)
          //return string for calculation of direction
    }//end if
}//end readFromSerial function
