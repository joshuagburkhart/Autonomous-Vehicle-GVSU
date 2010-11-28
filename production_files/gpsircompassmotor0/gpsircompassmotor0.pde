/*
@title - motorcompasstest0
@dscrp - This code contains functions that integrate arduino compass control and motors in order to help navigate a rover.
@author - Joshua Burkhart
@version - 11/20/2010
*/

#include <Wire.h>
#include <AFMotor.h>
#include <math.h>

int         fromHeading,
            toHeading,
            irReading,
            rspeed,
            lspeed,
            HMC6352Address = 0x42,
            slaveAddress,
            ledPin         = 13,
            i,
            headingValue,
            headingArray[8],
            avgHeadingValue;
double      latArray[10],       //-90 is South, +90 is North
            longArray[10];      //-180 is West, +180 is East
byte        headingData[2];
boolean     ledState       = false;
static int  RIGHT          = 0,
            LEFT           = 1,
            AHEAD          = 0,
            BACK           = 1,
            EAST           = 185,//180, //ideal degrees commented out, tuned degrees used
            SOUTHEAST      = 218,//225,
            SOUTH          = 242,//270,
            SOUTHWEST      = 274,//315,
            WEST           = 34,//0,
            NORTHWEST      = 100,//45,
            NORTH          = 125,//90,
            NORTHEAST      = 150,//135,
            IR_TOLERANCE   = 250, //determines the ir tolerance
            CMP_TOLERANCE  = 10,  //determines the compass tolerance
            GPS_TOLERANCE  = 0.00001; //determines the gps tolerance
                                         //1° latitude = 69.047 statute miles = 60 nautical miles
                                         //here our tolerance is set to (5280ft/mi * (0.00001° * 69.047mi/°)) = 3.645ft 
AF_DCMotor  rmotor(4),
            lmotor(3);//right motor, left motor

/*
  Shift the device's documented slave address (0x42) 1 bit right
  This compensates for how the TWI library only wants the
  7 most significant bits (with the high bit padded with 0)
*/
void setup(){
  
  latArray[0]      = 42.3313889;  longArray[0]     = -83.0458333; //Detroit's latitude is 42.3313889 longitude is -83.0458333
  latArray[1]      = 0;           longArray[1]     = 0;
  latArray[2]      = 0;           longArray[2]     = 0;
  latArray[3]      = 0;           longArray[3]     = 0;
  latArray[4]      = 0;           longArray[4]     = 0;
  latArray[5]      = 0;           longArray[5]     = 0;
  latArray[6]      = 0;           longArray[6]     = 0;
  latArray[7]      = 0;           longArray[7]     = 0;
  latArray[8]      = 0;           longArray[8]     = 0;
  latArray[9]      = 0;           longArray[9]     = 0;
  slaveAddress     = HMC6352Address >> 1;   // This results in 0x21 as the address to pass to TWI
  headingArray[0]  = NORTH;
  headingArray[1]  = EAST;
  headingArray[2]  = SOUTH;
  headingArray[3]  = WEST;
  headingArray[4]  = NORTHEAST;
  headingArray[5]  = SOUTHEAST;
  headingArray[6]  = SOUTHWEST;
  headingArray[7]  = NORTHWEST;
 
  Serial.begin(9600);
  pinMode(ledPin, OUTPUT);      // Set the LED pin as output
  Wire.begin();
}//end setup function

/*
  Begin continuous loop
*/
void loop(){
  int    k,
         emergencyDir = 0;
  double dir;
  for(k = 0; k < 10; k++){//go through the lat and long arrays
    while(wayPointNotReached(k)){
      dir          = calcDirFromGPS(k);
      emergencyDir = mod(emergencyDir + 90,360);
      setHeading(0);
      turnToHeading(dir);
      //printHeading();
      safeStraight(10,10,AHEAD,250,50,-1);
      straight(BACK,255,400);
      stp(0);
      turnToHeading(emergencyDir);
      safeStraight(10,10,AHEAD,250,50,10);
    }//end while
    delay(5000);
  }//end for
}//end loop function

/*
  This function returns the current latitude of the device
  @return - the current latitude
*/
double getCurrentLat(){
  //TODO: parse serial communication and return
  double lat = 42.9633333; //Grand Rapids' latitude is 42.9633333
  return lat;  
}//end getCurrentLat function

/*
  This function returns the current longitude of the device
  @return - the current longitude
*/
double getCurrentLong(){
  //TODO: parse serial communication and return
  double lon = -85.6680556; //Grand Rapids' longitude is -85.6680556
  return lon;
}//end getCurrentLong function

/*
  Travel straight while ir sensor reads acceptable distances
  @param n      - the number of samples to take
  @param msecsi - the amount of miliseconds to wait
  @param direc  - the direction to travel (AHEAD or BACK)
  @param spd    - the speed at which to travel (0-255)
  @param msecss - the number of miliseconds to spend traveling
  @param reps   - max times to execute loop or -1 for infinity
*/
void safeStraight(int n, int msecsi,int direc,int spd,int msecss,int reps){
  int x = reps;
  while(getIrReading(n, msecsi) < IR_TOLERANCE || x == 0){//while we're not close to anything
    straight(direc,spd,msecss);
    x--;
  }//end while
}//end safeStraight function

/*
  This function retuns false if device is not near its next waypoint
  @return - whether or not the device is near waypoint
*/
boolean wayPointNotReached(int wayPoint){
  if(distFromWayPoint(wayPoint) < GPS_TOLERANCE){
    return false;
  }//end if
  return true;
}//end wayPointNotReached function

/*
  This function calculates the distance from the next waypoint
  @param wayPoint - the next waypoint
  @return - the distance from the next waypoint
*/
double distFromWayPoint(int wayPoint){
  double y1      = getCurrentLat(),
         y2      = latArray[wayPoint],
         x1      = getCurrentLong(),
         x2      = longArray[wayPoint];
       Serial.print("Y1 is -------> ");
       Serial.print(y1);
       Serial.print("\n");
       Serial.print("Y2 is -------> ");
       Serial.print(y2);
       Serial.print("\n");
       Serial.print("X1 is -------> ");
       Serial.print(x1);
       Serial.print("\n");
       Serial.print("X2 is -------> ");
       Serial.print(x2);
       Serial.print("\n");
       Serial.print("distance is -------> ");
       Serial.print(sqrt(pow((y1 - y2),2) + pow((x1 - x2),2)));
       Serial.print("\n");
       Serial.print("Y1 - Y2 is -------> ");
       Serial.print(y1 - y2);
       Serial.print("\n");
       Serial.print("X1 - X2 is -------> ");
       Serial.print(x1 - x2);
       Serial.print("\n");
  double distance = sqrt(pow((y1 - y2),2) + pow((x1 - x2),2));//distance formula
  Serial.print("distFromWayPoint returns ");
  Serial.print(distance);
  Serial.print("\n");
  return distance;
}//end distFromWayPoint function

/*
  This function calculates the direction of the next waypoint
  @param wayPoint - the next waypoint
  @return - the distance from the next waypoint
*/
double calcDirFromGPS(int wayPoint){
  double y1     = getCurrentLat(),
         y2     = latArray[wayPoint],
         x1     = getCurrentLong(),
         x2     = longArray[wayPoint];
  double angle     = atan2((y2 - y1),(x2 - x1)),//gives +/- angle from x plane
         degree    = (angle * 180) / 3.14,      //convert radiens to degrees
         bearing   = mod(360 - degree,360),     //gives direction as 0 - 359 degrees
         mbearing  = mod(bearing + 180,360);    //maps the direction correctly for compass
      
      Serial.print("angle is --------------> ");
      printDouble(angle,10000000);
      Serial.print("\n");
      Serial.print("degree is --------------> ");
      printDouble(degree,10000000);
      Serial.print("\n");
      Serial.print("bearing is --------------> ");
      printDouble(bearing,10000000);
      Serial.print("\n");
      Serial.print("mbearing is --------------> ");
      printDouble(mbearing,10000000);
      Serial.print("\n");
  return mbearing;
}//end calcDirFromGPS function

/*
  This function sets and returns the voltage read by analog pin 0
  @return - the integer interpretation of analog 0's volatage
*/
int ir(){
  irReading = analogRead(0);
  return irReading;
}//end ir function

/*
  This function returns true if the device is on course
  @return - whether or not the device is on course;
*/
boolean onCourse(){
  return abs(fromHeading - toHeading) < CMP_TOLERANCE;
}//end onCourse function

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
void turnToHeading(int ltoHeading){

  int numTurns = 15;
  fromHeading  = (avgHeadingValue / 10);//divide for most significant digits of heading
  toHeading    = ltoHeading;
          
  while((abs(fromHeading - toHeading) > CMP_TOLERANCE)){//while current heading is not "close" to toHeading
    printHeading();
    int left  = mod((toHeading - fromHeading),360),
        right = mod((fromHeading - toHeading),360);
          
    Serial.print("ir reading ----------------> ");
    Serial.print(ir());
    Serial.print("\ntoHeading: ");
    Serial.print(toHeading);
    Serial.print("\nfromHeading ------> ");
    Serial.print(fromHeading);
    Serial.print("\nright: ");
    Serial.print(right);
    Serial.print("\nleft: ");
    Serial.print(left);
    Serial.print("\n");
    
    if(right > left){//if fromHeading is left of toHeading
      Serial.print("Turn left!\n");
      //turn right in small increment
      mturn(RIGHT, (left * numTurns) + 50);
    }//end if
    else{//fromHeading is right of toHeading
      Serial.print("Turn right!\n");
      //turn left in small increment
      mturn(LEFT, (right * numTurns) + 50);
    }//end else
    //reset current heading
    setHeading(10); //wait 10ms between readings
    fromHeading = (avgHeadingValue / 10);
    numTurns    = (numTurns - 1);
    if(numTurns < 0){
      numTurns  = 0;//we don't want negative turns
    }//end if
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
  avgHeadingValue = (avgHeadingValue / 10);
}//end setHeading function

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
  prints val with number of decimal places determine by precision
  NOTE: precision is 1 followed by the number of zeros for the desired number of decimial places
  example: printDouble( 3.1415, 100); // prints 3.14 (two decimal places)
*/
void printDouble( double val, unsigned int precision){
    Serial.print (int(val));  //prints the int part
    Serial.print("."); // print the decimal point
    unsigned int frac;
    if(val >= 0)
	  frac = (val - int(val)) * precision;
    else
	  frac = (int(val)- val ) * precision;
    Serial.println(frac,DEC) ;
}
