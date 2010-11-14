//this listens to the serial port (USB) and does stuff based on what it is hearing.

int motor1Pin = 13; //the first motor's port number 
int motor2Pin = 12; //the second motor's port number
int usbnumber = 0; //this variable holds what we are currently reading from serial


void setup() { //call this once at the beginning
    pinMode(motor1Pin, OUTPUT); 
    //Tell arduino that the motor pins are going to be outputs
    pinMode(motor2Pin, OUTPUT);	
    Serial.begin(9600); //start up serial port

}

void loop() { //main loop
    if (Serial.available() > 0) { //if there is anything on the serial port, read it
        usbnumber = Serial.read(); //store it in the usbnumber variable

    }

    if (usbnumber > 0) { //if we read something
        if (usbnumber == 49){
          delay(1000);  
          digitalWrite(motor1Pin, LOW);
            digitalWrite(motor2Pin, LOW); //if we read an ascii 1, stop

    		}
    if (usbnumber == 50){
          delay(1000);
              digitalWrite(motor1Pin, HIGH);
          digitalWrite(motor2Pin, HIGH); //if we read an ascii 2, drive forward

              }    

        usbnumber = 0; //reset
    }
}

