#include <StandardCplusplus.h>
#include <vector>
#include <Adafruit_NeoPixel.h>

#define PIN 6
#define lightCount 60
#define INPUT_SIZE 200

Adafruit_NeoPixel strip = Adafruit_NeoPixel(lightCount, PIN, NEO_GRB + NEO_KHZ800);

const int wheelFactor = 6;
std::vector< std::vector<uint8_t> > palette;
std::vector<uint8_t> thisColorVector;
std::vector<uint8_t> targetColorVector(3,0);
std::vector<uint8_t> currentColorVector(3,0);
const int maxChange = 2;
const float velocity = 10.0; // in leds per second
const int wait = 3; // in milliseconds
const int maxBeats = 15;
float beats[maxBeats] = {};
int beatRepeats[maxBeats] = {};
int beatColors[maxBeats][3] = {};
int mostRecentBeat = 0;
int oldBeatColor[3];
//std::vector<float> beats;
//std::vector<std::vector<uint8_t> > beatColors;
const int numSlots = strip.numPixels() / 2;

void setPalette(std::vector<char *> commands) {
  palette.clear();

  for (int j = 0; j < commands.size(); j++) {
    char* rgb = strtok(commands[j], ",");

    std::vector<char *> thisColor;

    while ( rgb != 0 ) {
      thisColor.push_back(rgb);
      rgb = strtok(0, ",");
    }

    thisColorVector.clear();
    thisColorVector.push_back(atoi(thisColor[0]));
    thisColorVector.push_back(atoi(thisColor[1]));
    thisColorVector.push_back(atoi(thisColor[2]));
    palette.push_back(thisColorVector);
  }
}

void setTargetColor(int colorIndex) {
  targetColorVector = palette[colorIndex % palette.size()];

  // track current beat color
  oldBeatColor[0] = beatColors[mostRecentBeat][0];
  oldBeatColor[1] = beatColors[mostRecentBeat][1];
  oldBeatColor[2] = beatColors[mostRecentBeat][2];
  
  int currentRepetitionCount = beatRepeats[mostRecentBeat];
  
  mostRecentBeat = ( mostRecentBeat + 1 ) % maxBeats;

//  Serial.print("setting target.  most recent beat is now ");
//  Serial.println(String(mostRecentBeat));

  // set beat location and beatcolors
  beats[mostRecentBeat] = 0;
  beatColors[mostRecentBeat][0] = targetColorVector[0];
  beatColors[mostRecentBeat][1] = targetColorVector[1];
  beatColors[mostRecentBeat][2] = targetColorVector[2];

//  Serial.println(String(beatColors[mostRecentBeat][0]));
//  Serial.println(String(beatColors[mostRecentBeat][1]));
//  Serial.println(String(beatColors[mostRecentBeat][2]));

  // track how many times this color has repeated
  if(beatColors[mostRecentBeat][0] == oldBeatColor[0] && beatColors[mostRecentBeat][1] == oldBeatColor[1] && beatColors[mostRecentBeat][2] == oldBeatColor[2]) {
    beatRepeats[mostRecentBeat] = currentRepetitionCount + 1;
  }
  else {
    beatRepeats[mostRecentBeat] = 0;
  }

//  Serial.print("beatRepeats = ");
//  Serial.println(String(beatRepeats[mostRecentBeat]));

  
}

void setColor(std::vector<uint8_t> colorVector) {
  for (int j = 0; j < strip.numPixels(); j++) {
    strip.setPixelColor(j, strip.Color(colorVector[0], colorVector[1], colorVector[2]));
  }
  strip.show();
}

//commands are either a single number corresponding to an index on the color palette, or a palette
//e.g. "5" sets the color to index 5 % palette_size
//e.g. p255,255,0;0,255,0;0,0,255| sets the palette to [yellow,green,blue]
void processCommands() {
  byte size = Serial.read();

//  Serial.print("Processing command starting with: ");
//  Serial.println(size);
  
  if ( size != 'p' ) {
    setTargetColor(size);
    return;
  };

  std::vector<char*> commands;

  char input[INPUT_SIZE + 1];
  byte size2 = Serial.readBytesUntil('|', input, INPUT_SIZE);
  input[size2] = 0;

  char* command = strtok(input, ";");
  while ( command != 0 ) {
//    Serial.print("received command: ");
//    Serial.println(command);

    commands.push_back(command);

    command = strtok(0, ";");
  }

//  Serial.print("found commands: ");
//  Serial.println(commands.size());

  setPalette(commands);
}

std::vector<uint8_t> Wheel(byte WheelPos) {
  WheelPos = 255 - WheelPos;
  int c[3];
  if(WheelPos < 85) {
   int c[] = { (255 - WheelPos * 3)/wheelFactor, 0, WheelPos * 3 / wheelFactor };
  } else if(WheelPos < 170) {
    WheelPos -= 85;
   int c[] = { 0, WheelPos * 3 / wheelFactor, (255 - WheelPos * 3)/wheelFactor };
  } else {
   WheelPos -= 170;
   int c[] = { WheelPos * 3 / wheelFactor, ( 255 - WheelPos * 3 ) / wheelFactor, 0 };
  }

  std::vector<uint8_t> cv(c,c+sizeof(c) / sizeof(uint8_t));
  return cv;
}

void setup() {
  Serial.begin(9600);
  strip.begin();

  for(int x = 0; x < lightCount; x++ ){
    strip.setPixelColor(x,strip.Color(0,0,0));
  }
  
  strip.show(); // Initialize all pixels to 'off'

  // set default palette to simple R,G, and B.
  int r[] = {255,0,0};
  std::vector<uint8_t> rv(r,r+sizeof(r) / sizeof(uint8_t));
  palette.push_back(rv);
  
  int g[] = {0,255,0};
  std::vector<uint8_t> gv(g,g+sizeof(g) / sizeof(uint8_t));
  palette.push_back(gv);
  
  int b[] = {0,0,255};
  std::vector<uint8_t> bv(b,b+sizeof(b) / sizeof(uint8_t));
  palette.push_back(bv);
}

void loop() {
  // read in commands
  if (Serial.available() > 0) {
    processCommands();
  }

  // move the beats at specified velocity
  for( int x = 0; x < maxBeats; x++ ) {
    beats[x] += velocity * wait / 100.0;
  }

  // set colors on the strip
  // start in the center and proceed outward
  int currentBeatIndex = mostRecentBeat;

  for( int k = 0; k < numSlots; k++ ) {
    // choose the relevant beatindex based on the beat locations and current location on the strip
    if( k > beats[currentBeatIndex] ) {
      int newBeatIndex = ( currentBeatIndex - 1 + maxBeats ) % maxBeats;

      if( newBeatIndex == mostRecentBeat ) {
        break;
      }
      
      currentBeatIndex = newBeatIndex;
    }

    // calculate intensity for the color at this pixel
    float intrabeatTrailOff = constrain((25.0 - ( beats[currentBeatIndex] - k ))/25.0,0,1.0); // beat trails off after initial hit
    float distanceTrailOff = constrain(0.8 * float(5 + numSlots - k)/float(numSlots),0.0,1.0); // intensity goes down with distance from center
    float repetitionTrailOff = constrain(float((4.0 - beatRepeats[currentBeatIndex]) / 4.0),0.3,1.0); // lessen intensity for repeated chords.  puts more emphasis on chord changes
    
    float intensity = intrabeatTrailOff * distanceTrailOff * repetitionTrailOff;

    // set color based on the color for this beat and the intensity
    uint32_t pixelColor = strip.Color(int(beatColors[currentBeatIndex][0] * intensity), int(beatColors[currentBeatIndex][1] * intensity), int(beatColors[currentBeatIndex][2] * intensity));
    strip.setPixelColor(k+numSlots,pixelColor);
    strip.setPixelColor(numSlots - k,pixelColor);
  }

  strip.show();

  delay(wait);
}
