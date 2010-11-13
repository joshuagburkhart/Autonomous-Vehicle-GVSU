#include <AFMotor.h>

AF_DCMotor rmotor(4),lmotor(3);//right motor, left motor

static int RIGHT = 0,LEFT = 1,AHEAD = 0, BACK = 1;

int rspeed,lspeed;


void setup() {
 Serial.begin(9600);           // set up Serial library at 9600 bps
 Serial.println("Motor test!");
}//end setup function

void loop() {
   /*
   //testing motor wiring------
   //turn right motor forward |
   rmotor.run(FORWARD);//     |
   delay(5000);//             |
   stp();//                   |
   //turn left motor forward  |
   lmotor.run(FORWARD);//     |
   delay(5000);//             |
   stp();//                   |
   //--------------------------
   */
 
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

}//end loop function

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
char* readFromSerial() { //main loop

    char* serialString;

    if (Serial.available() > 0) { //if there is anything on the serial port, read it
        serialString = Serial.read(); //store it in the serialString variable
    }//end if
    if (atoi(serialString) > 0) { //if we read something
        //validate read (it may be a read with poor signal)
        //if(valid read)
          //return string for calculation of direction
    }//end if
}//end readFromSerial function

