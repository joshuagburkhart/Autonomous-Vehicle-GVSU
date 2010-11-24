/*
* A simple sketch that pulls a $GPRMC string from the arduino GPS shield
* and responds with this string over serial when requested.
* Date: 11/22/2010
*/

#include <NewSoftSerial.h>

NewSoftSerial mySerial =  NewSoftSerial(2, 3);
#define powerpin 4

#define GPSRATE 4800
//#define GPSRATE 38400


// GPS parser for 406a
#define BUFFSIZ 90 // plenty big
char buffer[BUFFSIZ];
char buffidx;
char signal;

void setup() 
{ 
  if (powerpin) {
    pinMode(powerpin, OUTPUT);
  }
  pinMode(13, OUTPUT);
  Serial.begin(GPSRATE);
  mySerial.begin(GPSRATE);
 
   digitalWrite(powerpin, LOW);         // pull low to turn on!
} 
 
 
void loop() 
{ 
  parseGps();
  // send data only when data is requested:
  if (Serial.available() > 0) {
    // read the incoming byte:
    signal = Serial.read();
  }
}

/* Parses the $GPRMC string to ensure that it is valid */
void parseGps() {
  readline();
  // check if $GPRMC (global positioning fixed data)
  if (strncmp(buffer, "$GPRMC",6) == 0) {
    if (buffer[18] == 'A') {
      if (signal == '1') {
        Serial.println(buffer);
        signal = '0';    // Set signal back to zero
      }
    }
  }
}

/*
* Custom function for parsing a decimal value from a string
*/
uint32_t parsedecimal(char *str) {
  uint32_t d = 0;
  
  while (str[0] != 0) {
   if ((str[0] > '9') || (str[0] < '0'))
     return d;
   d *= 10;
   d += str[0] - '0';
   str++;
  }
  return d;
}

/*
* Read the line from the GPS module and place it in buffer[]
*/
void readline(void) {
  char c;
  
  buffidx = 0; // start at begninning
  while (1) {
      c=mySerial.read();
      if (c == -1)
        continue;
      if (c == '\n')
        continue;
      if ((buffidx == BUFFSIZ-1) || (c == '\r')) {
        buffer[buffidx] = 0;
        return;
      }
      buffer[buffidx++]= c;
  }
}