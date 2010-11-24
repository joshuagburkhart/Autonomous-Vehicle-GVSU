/*
@title - motorcompasstest0
@dscrp - This code contains functions that integrate arduino compass control and motors in order to help navigate a rover.
@author - Joshua Burkhart
@version - 11/20/2010
*/

#include <Wire.h>
#include <AFMotor.h>

int         irReading,
            rspeed,
            lspeed,
            HMC6352Address = 0x42,
            slaveAddress,
            ledPin         = 13,
            i,
            headingValue,
            avgHeadingValue;
byte        headingData[2];
boolean     ledState       = false;
static int  VRATING        = 200,
            RIGHT          = 0,
            LEFT           = 1,
            AHEAD          = 0,
            BACK           = 1,
            EAST           = 180, //degrees dependant of orientation of device relative to motors
            SOUTHEAST      = 225,
            SOUTH          = 270,
            SOUTHWEST      = 315,
            WEST           = 0,
            NORTHWEST      = 45,
            NORTH          = 90,
            NORTHEAST      = 135,
            TOLERANCE      = 5;  //determines the accuracy required by device
AF_DCMotor  rmotor(4),
            lmotor(3);//right motor, left motor

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
  
  int k;
  for(k = 0; k < 4; k++){
  
  setHeading(0);
  turnToHeading(k * 90);
  printHeading();
  if(getIrReading(10, 100) < VRATING){//if we are close to something
    straight(AHEAD,250,3000);
  }//end if

  }//end for
 
}//end loop function

/*
  This function sets and returns the voltage read by analog pin 0
  @return - the integer interpretation of analog 0's volatage
*/
int ir(){
  irReading = analogRead(0);
  return irReading;
}//end ir function

/*
  This function returns an average reading from ir sensor
  @param n - the number of samples to take
  @param msecs - the amount of miliseconds to wait
  @return - the average reading of the samples
*/
int getIrReading(int n, int msecs){
  int p,
      avg = 0;
  for(p = 0; p < n; p++){
    delay(msecs);
    avg = (avg + ir());
  }//end for
  return (avg / n);
}//end getIrReading function

/*
  This function replaces the under-powered '%' function
  @return - the result of (x mod m)
*/
int mod(int x, int m) {
    return (x%m + m)%m;
}//end mod function

/*
  Turn the vehicle toward the direction
  @toHeading - the direction in which to turn 
*/
void turnToHeading(int toHeading){

  int numTurns = 0,
      fromHeading = (avgHeadingValue / 10);//divide for most significant digits of heading
          
  while((abs(fromHeading - toHeading) > TOLERANCE)){//while current heading is not "close" to toHeading
    printHeading();
    int left  = mod((toHeading - fromHeading),360),
        right = mod((fromHeading - toHeading),360);
          
    Serial.print("val ----------------> ");
    Serial.print(ir());
    Serial.print("\ntoHeading: ");
    Serial.print(toHeading);
    Serial.print("\nfromHeading: ");
    Serial.print(fromHeading);
    Serial.print("\nright: ");
    Serial.print(right);
    Serial.print("\nleft: ");
    Serial.print(left);
    Serial.print("\n");
    
    if(right > left){//if fromHeading is left of toHeading
      Serial.print("Turn right!\n");
      //turn right in small increment
      mturn(RIGHT, (left * abs(15 - numTurns)));
    }//end if
    else{//fromHeading is right of toHeading
      Serial.print("Turn left!\n");
      //turn left in small increment
      mturn(LEFT, (right * abs(15 - numTurns)));
    }//end else
    //reset current heading
    setHeading(10); //wait 10ms between readings
    fromHeading = (avgHeadingValue / 10);
    numTurns = (numTurns + 1);
  }//end while
}//end turnToHeading function

/*
  Print the current heading to the serial port
*/
void printHeading(){
  Serial.print("Current heading: ");
  Serial.print(int (headingValue / 10));     //whole number part of the heading
  Serial.print(".");
  Serial.print(int (headingValue % 10));     //fractional part of the heading
  Serial.println(" degrees");
}//end printHeading function

/*
  Read the 2 heading bytes, MSB first
  The resulting 16 bit word is the compass heading in 10th's of a degree
  ex: a heading of 1345 == 134.5 degrees
  do 10 times and divide for avg heading
  @msecs - the number of miliseconds to wait between compass readings
*/
void setHeading(int msecs){
  delay(500); //wait for compass readings to settle
  avgHeadingValue = 0;
  int k;
  for(k = 0; k < 10; k++){
    getCmpData();
    Wire.requestFrom(slaveAddress, 2);        //request 2 byte heading (MSB comes first)
    i = 0;
    while(Wire.available() && i < 2)
    { 
      headingData[i] = Wire.receive();
      i++;
    }//end while
    headingValue = headingData[0]*256 + headingData[1];  //put MSB and LSB together
    avgHeadingValue = abs(avgHeadingValue + headingValue);
    delay(msecs);
  }//end for
  Serial.print(avgHeadingValue);
  Serial.print("\n");
  avgHeadingValue = (avgHeadingValue / 10);
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
  //stop
  stp(0);
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
  //stop
  stp(0);
  return 0;
}//end straight function
/*
  Safely slow both motors down to a stop 
  @msecs - the number of miliseconds to spend slowing down
*/
int safestop(int msecs){
  if(msecs < 100){//if little time is left
    stp(msecs);
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
int stp(int msecs){
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
  //stop
  stp(0);
  //set motor speed to ~80%
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
  //stop
  stp(0);
  return 0;
}//end turn function

/*
  Read information from the serial port
*/
int readFromSerial() { //main loop

    int serialString;

    if (Serial.available() > 0) { //if there is anything on the serial port, read it
        serialString = Serial.read(); //store it in the serialString variable
    }//end if
    if (serialString > 0) { //if we read something
        //validate read (it may be a read with poor signal)
        //if(valid read)
          //return string for calculation of direction
    }//end if
}//end readFromSerial function
