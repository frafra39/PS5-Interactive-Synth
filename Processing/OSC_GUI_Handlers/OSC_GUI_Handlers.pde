// === 1.  Setup Iniziale ===

// 1.1 Importazione librerie
import netP5.*;      // Gestione rete
import oscP5.*;      // Gestione OSC
import controlP5.*;  // Gestione GUI

//logo
PImage logoImage;
PImage psLogo;
PFont uiFont;

// 1.2 Dichiarazione oggetti principali
NetAddress sc;
NetAddress py;
OscP5 oscP5;
ControlP5 cp5;

  // Dichiarazione gruppi GUI
Group oscGroup, envGroup, lfoGroup, fxGroup, joypadGroup;  

  // Dichiarazione variabili per XY Pads
PVector leftPadCenter, rightPadCenter;   
float padRadius = 130;
float leftPadX = 0, leftPadY = 0;   
float rightPadX = 0, rightPadY = 0;

  // Glide
int cutoff_dir = 0;  // -1 sinistra, +1 destra
int glide_dir = 0;   // -1 giù, +1 su
int lastCutoffPressTime = 0;
int lastGlidePressTime = 0;
float glideMin = 0.5;
float glideMax = 2.0;

  // Posizione dei due joystick
PVector dpadCenter = new PVector(120, 200);         
PVector symbolPadCenter = new PVector(1290, 200); 
float dpadRadius = 90;
float symbolPadRadius = 90; 
float symbolButtonRadius = 28; 
float symbolSpacing = dpadRadius * 0.65; 

  // Variabili per SymbolPad
PVector symbolPadUp, symbolPadDown, symbolPadLeft, symbolPadRight;
boolean trianglePressed = false;
boolean circlePressed = false;
boolean squarePressed = false;
boolean crossPressed = false;

  // Stato illuminazione etichette controlli LFO e Cutoff
boolean L1Pressed = false;
boolean R1Pressed = false;
boolean L2Pressed = false;
boolean R2Pressed = false;

int lastL1Time = 0;
int lastR1Time = 0;
int lastL2Time = 0;
int lastR2Time = 0;



// 1.4 Inizializzazione GUI
void setup() {
  
  logoImage = loadImage("https://raw.githubusercontent.com/Frabbandera/PS5-Interactive-Synth/refs/heads/main/Resources/PlaySynth.png");
  size(1430, 820);
  
  psLogo = loadImage("https://raw.githubusercontent.com/Frabbandera/PS5-Interactive-Synth/refs/heads/main/Resources/PlayStation-Logo.wine.png");


  // 1.4.1 Setup
  sc = new NetAddress("127.0.0.1", 57120);
  py = new NetAddress("127.0.0.1", 12001);
  oscP5 = new OscP5(this, 12000);
  cp5 = new ControlP5(this);

  // 1.4.2 Sezioni GUI
  setupOscillators();
  setupEnvelope();
  setupModulation();
  setupFX();
  
 // 1.4.3 XY-Pads - Centrati visivamente
leftPadCenter  = new PVector( 120 + padRadius, 450 + padRadius );               // Spostato più a destra
rightPadCenter = new PVector(width - (170 + padRadius), 450 + padRadius );    // Spostato più a sinistra

  // 1.4.4 Font
  uiFont = createFont("Futura-Bold", 12);  
  textFont(uiFont);
  cp5.setFont(uiFont);
}

// 1.5 Gestione Sfondo e Sezioni
void draw() {
  background(255, 253, 240);
  fill(240);
  if (logoImage != null) {
    image(logoImage, 50, 10, 120, 120);  // Posizione e dimensione del logo
  }

  // Oscillatori
  fill(255, 245, 180);  
  noStroke();
  rect(240, 10, 440, 380, 20);
  fill(0);

  // Envelope
  fill(255, 180, 180);
  noStroke();
  rect(690, 10, 480, 180, 20);  
  fill(0);

  // Contenitori smussati sotto slider ADSR
  drawRoundedRect(710, 40, 70, 120, color(255, 220, 220), 12);  // Attack
  drawRoundedRect(830, 40, 70, 120, color(255, 220, 220), 12);  // Decay
  drawRoundedRect(950, 40, 70, 120, color(255, 220, 220), 12);  // Sustain
  drawRoundedRect(1070, 40, 70, 120, color(255, 220, 220), 12); // Release

  // Modulation
  fill(200, 180, 255);
  noStroke();
  rect(690, 200, 480, 190, 20); 
  fill(0);

  // FX
  fill(170, 220, 170);
  noStroke();
  rect(90, 400, 1200, 390, 20);
  fill(0);
  
  // Logo sopra Random FX
if (psLogo != null) {
  image(psLogo, 662, 700, 40, 30);
}

// Etichetta sopra RESET FX
textFont(uiFont);   // usa lo stesso font della GUI
fill(40);
textAlign(CENTER);
textSize(12);
text("Touch Pad", 685, 415);

// === XY-PADS ottimizzati ===
color knobColor = color(120, 180, 140); // lo stesso di .setColorBackground
// === XY-PADS ottimizzati ===

// LEFT PAD
noStroke(); // Rimuove il contorno
fill(knobColor);
ellipse(leftPadCenter.x, leftPadCenter.y, padRadius*2, padRadius*2);

// Punto di controllo centrale (nero)
fill(0);
ellipse(leftPadCenter.x + leftPadX*padRadius,
        leftPadCenter.y + leftPadY*padRadius,
        16, 16);

// RIGHT PAD
noStroke(); // Rimuove il contorno
fill(knobColor);
ellipse(rightPadCenter.x, rightPadCenter.y, padRadius*2, padRadius*2);

// Punto di controllo centrale (nero)
fill(0);
ellipse(rightPadCenter.x + rightPadX*padRadius,
        rightPadCenter.y + rightPadY*padRadius,
        16, 16);


  // PADS frecce e simboli
  drawJoystickCircle(dpadCenter, 90);  
  drawSymbolPad(symbolPadCenter.x, symbolPadCenter.y);

  // Etichette legenda
  // LFO 
  drawLabelBox(735 + 45 / 2, 225, "L2", color(180, 160, 230));
  drawLabelBox(735 + 45 / 2 + 30, 225, "R2", color(180, 160, 230));

  drawLabelBox(885 + 45 / 2, 225, "L1", color(180, 160, 230));
  drawLabelBox(885 + 45 / 2 + 30, 225, "R1", color(180, 160, 230));

  // Cutoff 
  drawArrowLabel(1030 + 22, 225, -1); // sinistra
  drawArrowLabel(1030 + 68, 225, 1);  // destra
  
  // Etichette attive sopra i knob LFO e Cutoff 
  color baseViolet = color(200, 180, 255);
  color activeViolet = color(120, 90, 220);

  // LFO FREQ (L2, R2)
  fill(L2Pressed ? activeViolet : baseViolet);
  rect(740, 210, 25, 20, 6);
  fill(255);
  textAlign(CENTER, CENTER);
  text("L2", 740 + 12.5, 210 + 10);

  fill(R2Pressed ? activeViolet : baseViolet);
  rect(770, 210, 25, 20, 6);
  fill(255);
  text("R2", 770 + 12.5, 210 + 10);

  // LFO DEPTH (L1, R1)
  fill(L1Pressed ? activeViolet : baseViolet);
  rect(890, 210, 25, 20, 6);
  fill(255);
  text("L1", 890 + 12.5, 210 + 10);

  fill(R1Pressed ? activeViolet : baseViolet);
  rect(920, 210, 25, 20, 6);
  fill(255);
  text("R1", 920 + 12.5, 210 + 10);

  // LOGICA DI AGGIORNAMENTO PARAMETRI DA TASTI FRECCIA (GUI o Controller)
  //float cutoffStep = 0.3;
  //float glideStep = 0.05;
  



  // === Reset automatico del colore delle frecce dopo 80ms
  int now = millis();
  if (cutoff_dir != 0 && now - lastCutoffPressTime > 80) {
    cutoff_dir = 0;
  }
  if (glide_dir != 0 && now - lastGlidePressTime > 80) {
    glide_dir = 0;
  }
}

void drawJoystickCircle(PVector center, float radius) {
  // Contorno grigio chiaro
  fill(230);
  noStroke();
  ellipse(center.x, center.y, radius * 2, radius * 2);

  // Colori attivi
  color activePurple = color(120, 90, 220);  // cutoff
  color activeYellow = color(255, 200, 40);  // glide
  color base = color(80); // colore di default

  // Stato delle frecce
  boolean leftActive  = (cutoff_dir == -1);
  boolean rightActive = (cutoff_dir == 1);
  boolean upActive    = (glide_dir == 1);
  boolean downActive  = (glide_dir == -1);


  // Triangolini
  drawTriangle(center.x, center.y - radius * 0.6, 0, -1, upActive ? activeYellow : base);   // ↑ (punta in basso)
  drawTriangle(center.x, center.y + radius * 0.6, 0, 1, downActive ? activeYellow : base); // ↓ (punta in alto)
  drawTriangle(center.x - radius * 0.6, center.y, -1, 0, leftActive ? activePurple : base); // ← (punta a destra)
  drawTriangle(center.x + radius * 0.6, center.y, 1, 0, rightActive ? activePurple : base); // → (punta a sinistra)
}

void drawTriangle(float cx, float cy, int dx, int dy, color fillColor) {
  pushMatrix();
  translate(cx, cy);
  rotate(atan2(-dy, -dx) + HALF_PI);
  fill(fillColor);
  noStroke();
  beginShape();
  vertex(-8, -6);
  vertex(8, -6);
  vertex(0, 10);
  endShape(CLOSE);
  popMatrix();
}


void drawDpad(int cx, int cy) {
  fill(230); // Grigio chiaro
  noStroke();
  ellipse(cx + 20, cy + 20, 160, 160); // sfondo circolare dietro le frecce

  fill(70);
  stroke(0);
  strokeWeight(1);
  int s = 35;

  // Quadrati freccia
  rect(cx - s, cy, s, s, 7);  // ←
  rect(cx + s, cy, s, s, 7);  // →
  rect(cx, cy - s, s, s, 7);  // ↑
  rect(cx, cy + s, s, s, 7);  // ↓

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(30);
  text("←", cx - s + s / 2, cy + s / 2);
  text("→", cx + s + s / 2, cy + s / 2);
  text("↑", cx + s / 2, cy - s + s / 2);
  text("↓", cx + s / 2, cy + s + s / 2);
}


void drawSymbolPad(float cx, float cy) {
  float r = 90;  // sfondo grande
  float symbolSpacing = 50;
  float symbolButtonRadius = 28;
  textAlign(CENTER, CENTER);
  textSize(30);
  PFont f = createFont("Arial Rounded MT Bold", 30);
  textFont(f);

  // Sfondo grigio grande
  fill(230);
  noStroke();
  ellipse(cx, cy, 2 * r, 2 * r);

  // TRIANGOLO ↑ (verde pastello)
  fill(trianglePressed ? color(100, 190, 100) : color(170, 230, 170));
  ellipse(cx, cy - symbolSpacing, 2 * symbolButtonRadius, 2 * symbolButtonRadius);
  fill(0);
  text("▲", cx, cy - symbolSpacing);

  // CERCHIO → (rosso pastello)
  fill(circlePressed ? color(200, 100, 100) : color(255, 180, 180));
  ellipse(cx + symbolSpacing, cy, 2 * symbolButtonRadius, 2 * symbolButtonRadius);
  fill(0);
  text("●", cx + symbolSpacing, cy);

  // QUADRATO ← (giallo pastello)
  fill(squarePressed ? color(220, 200, 80) : color(255, 240, 160));
  ellipse(cx - symbolSpacing, cy, 2 * symbolButtonRadius, 2 * symbolButtonRadius);
  fill(0);
  text("■", cx - symbolSpacing, cy);

  // X ↓ (viola pastello)
  fill(crossPressed ? color(170, 140, 200) : color(220, 190, 255));
  ellipse(cx, cy + symbolSpacing, 2 * symbolButtonRadius, 2 * symbolButtonRadius);
  fill(0);
  text("✕", cx, cy + symbolSpacing);
}


void drawRoundedRect(float x, float y, float w, float h, color c, float radius) {
  noStroke();
  fill(c);
  rect(x, y, w, h, radius);
}

void drawSymbolButton(float x, float y, float r, String label, color c) {
  fill(c);
  noStroke();
  ellipse(x, y, r * 2, r * 2);

  fill(40);
  textAlign(CENTER, CENTER);
  textSize(20);
  text(label, x, y);
}

//etichette
void drawLabelBox(float x, float y, String label, color bgColor) {
  rectMode(CENTER);
  fill(bgColor);
  noStroke();
  rect(x, y, 24, 20, 5);
  fill(40);
  textAlign(CENTER, CENTER);
  textSize(10);
  text(label, x, y);
  rectMode(CORNER);
}

void drawArrowLabel(float x, float y, int direction) {
  color arrowColor = color(120, 90, 220);  // viola pastello
  pushMatrix();
  translate(x, y);
  rotate(direction == -1 ? PI : 0);  // ← o →
  fill(arrowColor);
  noStroke();
  beginShape();
  vertex(-6, -5);
  vertex(6, 0);
  vertex(-6, 5);
  endShape(CLOSE);
  popMatrix();
}

String getWaveformName(int index) {
  String[] waveNames = {"Sine", "Saw", "Square", "LFTri", "Blip"};
  if (index >= 0 && index < waveNames.length) {
    return waveNames[index];
  }
  return "Unknown";
}

// === 2. Funzioni Setup GUI ===

// 2.1 Oscillators
void setupOscillators() {

  oscGroup = cp5.addGroup("Oscillators");

  String[] waveNames = {"Sine", "Saw", "Square", "LFTri", "Blip"};

  for (int i = 0; i < 3; i++) {
    final int index = i;
    int y0 = 30 + i * 100;

    DropdownList d = cp5.addDropdownList("waveform" + (i + 1))
      .setPosition(290, y0)          // 20 → 250
      .setSize(120, 80)
      .setItems(waveNames)
      .setGroup(oscGroup)
      .setLabel("Wave " + (index + 1))
      .setColorBackground(color(235, 215, 140))   // giallo sabb
      .setColorForeground(color(180, 145, 60))    // ambra
      .setColorActive(color(180, 145, 60));
      
cp5.addTextlabel("labelWaveform" + (i + 1))
      .setText("SELECTED: —")
      .setPosition(290, y0 - 15)
      .setColorValue(color(60))
      .setFont(createFont("Arial", 12))
      .setColor(color(180, 145, 60));

    d.onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent e) {
        int idx = (int) e.getController().getValue();
        cp5.get(Textlabel.class, "labelWaveform" + (index + 1))
           .setText("SELECTED: " + getWaveformName(idx));
      }
    });

    // Aumenta altezza delle righe del menu
    d.setItemHeight(18);  // default è circa 20
    d.setBarHeight(18);   // altezza della barra visibile quando il menu è chiuso

    cp5.addKnob("level" + (i + 1))
      .setPosition(470, y0 + 10)     // 210 → 440
      .setRadius(30)
      .setRange(0, 1)
      .setValue(0.3)
      .setGroup(oscGroup)
      .setLabel("Level")
      .setDragDirection(ControlP5.VERTICAL)
      .setResolution(-100)
      .setColorBackground(color(235, 215, 140))   // giallo sabbia
      .setColorForeground(color(180, 145, 60))    // ambra
      .setColorActive(color(180, 145, 60));


    cp5.addKnob("octave" + (i + 1))
      .setPosition(570, y0 + 5)     // 320 → 550
      .setRadius(30)
      .setRange(-2, 2)
      .snapToTickMarks(true)
      .setNumberOfTickMarks(4)
      .setValue(0)
      .setGroup(oscGroup)
      .setLabel("Octave")
      .setDragDirection(ControlP5.VERTICAL)
      .setResolution(-100)
      .setColorBackground(color(235, 215, 140))   // giallo sabbia
      .setColorForeground(color(180, 145, 60))    // ambra
      .setColorActive(color(180, 145, 60));
  }
  
Slider glideSlider = cp5.addSlider("glide")
    .setPosition(475, 350)
    .setSize(150, 20)
    .setRange(0.5, 2.0)
    .setValue(1.0)
    .setGroup(oscGroup)
    .setLabel("")
    .setColorBackground(color(235, 215, 140))   // giallo sabbia
    .setColorForeground(color(180, 145, 60))    // ambra
    .setColorActive(color(180, 145, 60));


  
    // Etichetta separata centrata sotto lo slider
  cp5.addTextlabel("glideLabel")
    .setText("GLIDE FACTOR")
    .setPosition(470 + 75 - 40, 375)  // centrata: slider.x + slider.width/2 - offset visivo
    .setGroup(oscGroup)
    .setColorValue(color(180, 145, 60))
    .setFont(createFont("Futura-Bold", 12));
  
    String[] glideRangeOptions = {"1 octave", "2 octaves", "3 octaves"};

  cp5.addDropdownList("glideRange")
    .setPosition(290, 330) // accanto allo slider glide
    .setSize(120, 60)
    .setItems(glideRangeOptions)
    .setGroup(oscGroup)
    .setLabel("Glide Range")
    .setColorBackground(color(235, 215, 140))
    .setColorForeground(color(180, 145, 60))
    .setColorActive(color(180, 145, 60))
    .setItemHeight(18)
    .setBarHeight(18)
    .setValue(0); // default: 1 octave
    
// POLY a sinistra → spostato a destra
cp5.addToggle("polyMode")
  .setPosition(1220, 60)  // prima era 1200
  .setSize(60, 20)
  .setValue(false)
  .setGroup(oscGroup)
  .setLabel("Poly")
  .setColorForeground(color(180, 145, 60))
  .setColorActive(color(250, 230, 100))    // giallo pastello
  .setColorBackground(color(230));

// MONO a destra → spostato a destra
cp5.addToggle("monoMode")
  .setPosition(1300, 60)  // prima era 1270
  .setSize(60, 20)
  .setValue(true)
  .setGroup(oscGroup)
  .setLabel("Mono")
  .setColorForeground(color(180, 145, 60))
  .setColorActive(color(255, 100, 100))    // rosso pastello
  .setColorBackground(color(230));

// Etichette centrate in basso
cp5.getController("monoMode").getCaptionLabel()
   .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
   .setColor(color(255, 100, 100));

cp5.getController("polyMode").getCaptionLabel()
   .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
   .setColor(color(250, 230, 100));
   
 // RANDOM a sinistra (sotto triangolo)
cp5.addToggle("randomMode")
  .setPosition(1220, 310)   // simmetrico verticale rispetto a polyMode
  .setSize(60, 20)
  .setValue(false)
  .setGroup(oscGroup)
  .setLabel("Random")
  .setColorForeground(color(60, 180, 100))
  .setColorActive(color(100, 190, 100))    // verde pastello
  .setColorBackground(color(230));
  
    cp5.getController("randomMode").getCaptionLabel()
   .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
   .setColor(color(100, 190, 100)); // verde pastello
  
  // RANDOM FX (accanto a Random Synth)
cp5.addToggle("randomFXMode")
  .setPosition(652, 730)
  .setSize(65, 30)
  .setValue(false)
  .setLabel("RANDOM FX")
  .setColorForeground(color(0))     // colore del bordo
  .setColorActive(color(0))         // colore quando premuto
  .setColorBackground(color(230));  // colore da inattivo

cp5.getController("randomFXMode").getCaptionLabel()
   .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
   .setColor(color(0));


// RESET a destra (sotto croce)
cp5.addToggle("resetMode")
  .setPosition(1300, 310)   // simmetrico verticale rispetto a monoMode
  .setSize(60, 20)
  .setValue(false)
  .setGroup(oscGroup)
  .setLabel("Reset")
  .setColorForeground(color(140, 100, 180))
  .setColorActive(color(170, 140, 200))    // viola pastello
  .setColorBackground(color(230));
  
  cp5.getController("resetMode").getCaptionLabel()
   .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
   .setColor(color(170, 140, 200)); // viola pastello
  
  // RESET a destra (sotto croce)
cp5.addToggle("resetFXMode")
  .setPosition(652, 420)
  .setSize(65, 30)
  .setValue(false)
  .setLabel("RESET FX")
  .setColorForeground(color(0))     // colore del bordo
  .setColorActive(color(0))         // colore quando premuto
  .setColorBackground(color(230));  // colore da inattivo

cp5.getController("resetFXMode").getCaptionLabel()
   .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
   .setColor(color(0, 0, 0));

}

// 2.2 Envelope
void setupEnvelope() {
  envGroup = cp5.addGroup("Envelope");

  cp5.addSlider("attack")
    .setPosition(710, 40)
    .setSize(70, 120)
    .setRange(0, 5)
    .setValue(0.01)
    .setGroup(envGroup)
    .setLabel("Attack")
    .setColorBackground(color(255, 200, 200))   // rosa pastello chiaro
    .setColorForeground(color(220, 100, 120))   // rosso medio
    .setColorActive(color(180, 60, 80));        // rosso intenso

  cp5.addSlider("decay")
    .setPosition(830, 40)
    .setSize(70, 120)
    .setRange(0, 5)
    .setValue(0.3)
    .setGroup(envGroup)
    .setLabel("Decay")
    .setColorBackground(color(255, 200, 200))
    .setColorForeground(color(220, 100, 120))
    .setColorActive(color(180, 60, 80));

  cp5.addSlider("sustain")
    .setPosition(950, 40)
    .setSize(70, 120)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(envGroup)
    .setLabel("Sustain")
    .setColorBackground(color(255, 200, 200))
    .setColorForeground(color(220, 100, 120))
    .setColorActive(color(180, 60, 80));

  cp5.addSlider("release")
    .setPosition(1070, 40)
    .setSize(70, 120)
    .setRange(0, 5)
    .setValue(0.3)
    .setGroup(envGroup)
    .setLabel("Release")
    .setColorBackground(color(255, 200, 200))
    .setColorForeground(color(220, 100, 120))
    .setColorActive(color(180, 60, 80));
}


// 2.3 Modulation Setup
void setupModulation() {

  lfoGroup = cp5.addGroup("Modulation");

  cp5.addKnob("lfoFreq")
    .setPosition(730, 245)   // 500 → 730
    .setRadius(45)
    .setRange(0, 20)
    .setValue(0)
    .setGroup(lfoGroup)
    .setLabel("LFO Freq")
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setColorBackground(color(150, 140, 225))
    .setColorForeground(color(80, 0, 160))
    .setColorActive(color(80, 0, 160));

  cp5.addKnob("lfoDepth")
    .setPosition(880, 245)   // 650 → 880
    .setRadius(45)
    .setRange(0, 1)
    .setValue(0)
    .setGroup(lfoGroup)
    .setLabel("LFO Depth")
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setColorBackground(color(150, 140, 225))
    .setColorForeground(color(80, 0, 160))
    .setColorActive(color(80, 0, 160));

  cp5.addKnob("cutoff")
    .setPosition(1030, 245)  // 800 → 1030
    .setRadius(45)
    .setRange(0, 20)
    .setValue(10)
    .setGroup(lfoGroup)
    .setLabel("Cutoff")
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setColorBackground(color(150, 140, 225))
    .setColorForeground(color(80, 0, 160))
    .setColorActive(color(80, 0, 160));
}

// 2.4 FXs Setup
void setupFX() {

    fxGroup = cp5.addGroup("FXPads");
  
  cp5.addSlider("FX3")
    .setPosition(450, 420)
    .setSize(180, 20)
    .setRange(0, 1)
    .setValue(0)
    .setGroup(fxGroup)
    .setLabel("Reverb")
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20));
cp5.getController("FX3").getCaptionLabel().align(ControlP5.CENTER, ControlP5.TOP_OUTSIDE); // ✅ etichetta sopra

  cp5.addKnob("r_roomsize")
    .setPosition(475, 445)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Room Size");

  cp5.addKnob("r_damping")
    .setPosition(555, 445)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Damping");

  cp5.addKnob("r_mix")
    .setPosition(515, 515)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Mix");

  cp5.addSlider("FX4")
    .setPosition(450, 620)
    .setSize(180, 20)
    .setRange(0, 1)
    .setValue(0)
    .setGroup(fxGroup)
    .setLabel("Delay")
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20));
cp5.getController("FX4").getCaptionLabel().align(ControlP5.CENTER, ControlP5.TOP_OUTSIDE); // ✅ etichetta sopra

  cp5.addKnob("de_delaytime")
    .setPosition(475, 650)
    .setRadius(25)
    .setRange(0,1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Delay Time");

  cp5.addKnob("de_feedback")
    .setPosition(555, 650)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Feedback");

  cp5.addKnob("de_mix")
    .setPosition(515, 720)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Mix");

  cp5.addSlider("FX6")
    .setPosition(735, 420)
    .setSize(180, 20)
    .setRange(0, 1)
    .setValue(0)
    .setGroup(fxGroup)
    .setLabel("Flanger")
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20));
cp5.getController("FX6").getCaptionLabel().align(ControlP5.CENTER, ControlP5.TOP_OUTSIDE); // ✅ etichetta sopra

  cp5.addKnob("f_drywet")
    .setPosition(735, 445)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Dry/Wet");

  cp5.addKnob("f_depth")
    .setPosition(800, 445)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Depth");

  cp5.addKnob("f_rate")
    .setPosition(865, 445)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Rate");

  cp5.addKnob("f_feedback")
    .setPosition(760, 515)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Feedback");

  cp5.addKnob("f_amplitude")
    .setPosition(840, 515)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Amplitude");

  cp5.addSlider("FX7")
    .setPosition(735, 620)
    .setSize(180, 20)
    .setRange(0, 1)
    .setValue(0)
    .setGroup(fxGroup)
    .setLabel("Distortion")
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20));
cp5.getController("FX7").getCaptionLabel().align(ControlP5.CENTER, ControlP5.TOP_OUTSIDE); // ✅ etichetta sopra

  cp5.addKnob("di_drive")
    .setPosition(760, 650)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Drive");

  cp5.addKnob("di_tone")
    .setPosition(840, 650)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Tone");

  cp5.addKnob("di_mix")
    .setPosition(760, 720)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.5)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Mix");

  cp5.addKnob("di_output")
    .setPosition(840, 720)
    .setRadius(25)
    .setRange(0, 1)
    .setValue(0.3)
    .setGroup(fxGroup)
    .setColorBackground(color(120, 180, 140))
    .setColorForeground(color(20, 100, 20))
    .setColorActive(color(20, 100, 20))
    .setDragDirection(ControlP5.VERTICAL)
    .setResolution(-100)
    .setLabel("Output");
}

// === 3. Gestione Pads ===
// 3.1 Pads Frecce e Simboli
void mousePressed() {
  
  // Joystick Dpad
  if (dist(mouseX, mouseY, dpadCenter.x, dpadCenter.y) < dpadRadius) {
    float dx = mouseX - dpadCenter.x;
    float dy = mouseY - dpadCenter.y;

    if (abs(dx) > abs(dy)) {
      if (dx > 0) {
        cutoff_dir = 1;
        lastCutoffPressTime = millis();
        sendOSC("/controller/dpadRight", 1);
      } else {
        cutoff_dir = -1;
        lastCutoffPressTime = millis();
        sendOSC("/controller/dpadLeft", 1);
      }
    }

  }

  // === Simboli cliccabili ===
  float sx = symbolPadCenter.x;
  float sy = symbolPadCenter.y;

  // Joystick Simboli cliccabili precisi
if (dist(mouseX, mouseY, sx, sy - 60) < 30) {  // Triangolo
  trianglePressed = true;
  cp5.get(Toggle.class, "randomMode").setValue(1);
  cp5.get(Toggle.class, "resetMode").setValue(0);
  sendOSC("/controller/randomize", 1);
}

if (dist(mouseX, mouseY, sx, sy + 60) < 30) {  // Croce
  crossPressed = true;
  cp5.get(Toggle.class, "resetMode").setValue(1);
  cp5.get(Toggle.class, "randomMode").setValue(0);
  sendOSC("/controller/reset", 1);
}

  if (dist(mouseX, mouseY, sx - 60, sy) < 30) {         // Quadrato
    squarePressed = true;
    cp5.get(Toggle.class, "polyMode").setValue(1);
    cp5.get(Toggle.class, "monoMode").setValue(0);
    sendOSC("/controller/polyMode", 1);
    sendOSC("/controller/monoMode", 0);
    //sendOSC("/controller/buttonSquare", 1);
  }
  if (dist(mouseX, mouseY, sx + 60, sy) < 30) {         // Cerchio
    circlePressed = true;
    cp5.get(Toggle.class, "monoMode").setValue(1);
    cp5.get(Toggle.class, "polyMode").setValue(0);
    sendOSC("/controller/monoMode", 1);
    sendOSC("/controller/polyMode", 0);
    //sendOSC("/controller/buttonCircle", 1);
  }
}

void mouseReleased() {
  //cutoff_dir = 0;
  //glide_dir = 0;
  trianglePressed = false;
  circlePressed = false;
  squarePressed = false;
  crossPressed = false;
}

// 3.2 XY-Pads

PVector computePad(PVector c) {
  float dx = mouseX - c.x;
  float dy = mouseY - c.y;
  // se il click è fuori dal cerchio, rimappo sul bordo
  float d = dist(mouseX, mouseY, c.x, c.y);
  if (d > padRadius) {
    dx *= padRadius / d;
    dy *= padRadius / d;
  }
  return new PVector(dx / padRadius, dy / padRadius);
}

void mouseDragged() {
  // se dentro left pad
  if (dist(mouseX, mouseY, leftPadCenter.x, leftPadCenter.y) < padRadius) {
    PVector v = computePad(leftPadCenter);
    leftPadX = v.x;
    leftPadY = v.y;
    // aggiorno GUI e OSC
    float reverb = abs(leftPadY);
    float delay  = abs(leftPadX);
    cp5.get(Slider.class, "FX3").setValue(reverb);
    cp5.get(Slider.class ,"FX4").setValue(delay);
    sendOSC("/controller/sendLevel1", reverb);
    sendOSC("/controller/sendLevel2", delay);
  }
  // se dentro right pad
  if (dist(mouseX, mouseY, rightPadCenter.x, rightPadCenter.y) < padRadius) {
    PVector v = computePad(rightPadCenter);
    rightPadX = v.x;
    rightPadY = v.y;
    float flanger     = abs(rightPadY);
    float distortion = abs(rightPadX);
    cp5.get(Slider.class, "FX6").setValue(flanger);
    cp5.get(Slider.class, "FX7").setValue(distortion);
    sendOSC("/controller/sendLevel3", flanger);
    sendOSC("/controller/sendLevel4", distortion);
  }
}

// === 4. Invio OSC ===

// 4.1 Logica invio OSC
void sendOSC(String address, float val) {

  OscMessage m = new OscMessage(address);
  m.add(val);
  oscP5.send(m, sc);
  oscP5.send(m, py);
}

// 4.2 Invio OSC a seguito di modifica controlli GUI

void controlEvent(ControlEvent e) {

  String name = e.getName();
  float val = e.getValue();

  // 4.2.1 LPF & LFO
  if (name.equals("cutoff")) {
    sendOSC("/controller/cutoff", val);
  } else if (name.equals("lfoFreq")) {
    sendOSC("/controller/lfoFreq", val);
  } else if (name.equals("lfoDepth")) {
    sendOSC("/controller/lfoDepth", val);

    // 4.2.2 Envelope (ADSR)
  } else if (name.equals("attack")) {
    sendOSC("/controller/attack", val);
  } else if (name.equals("decay")) {
    sendOSC("/controller/decay", val);
  } else if (name.equals("sustain")) {
    sendOSC("/controller/sustain", val);
  } else if (name.equals("release")) {
    sendOSC("/controller/release", val);

    // 4.2.3 Fxs
  } else if (name.equals("FX3")) {               // riverbero
    sendOSC("/controller/sendLevel1", val);
  } else if (name.equals("r_roomsize")) {
    sendOSC("/controller/r_roomsize", val);
  } else if (name.equals("r_damping")) {
    sendOSC("/controller/r_damping", val);
  } else if (name.equals("r_mix")) {
    sendOSC("/controller/r_mix", val);
  } else if (name.equals("r_predelay")) {
    sendOSC("/controller/r_predelay", val);
  } else if (name.equals("FX4")) {
    sendOSC("/controller/sendLevel2", val);
  } else if (name.equals("de_delaytime")) {
    sendOSC("/controller/de_delaytime", val);
  } else if (name.equals("de_feedback")) {
    sendOSC("/controller/de_feedback", val);
  } else if (name.equals("de_mix")) {
    sendOSC("/controller/de_mix", val);
  } else if (name.equals("FX6")) {
    sendOSC("/controller/sendLevel3", val);
  } else if (name.equals("f_drywet")) {
    sendOSC("/controller/f_drywet", val);
  } else if (name.equals("f_depth")) {
    sendOSC("/controller/f_depth", val);
  } else if (name.equals("f_rate")) {
    sendOSC("/controller/f_rate", val);
  } else if (name.equals("f_feedback")) {
    sendOSC("/controller/f_feedback", val);
  } else if (name.equals("f_amplitude")) {
    sendOSC("/controller/f_amplitude", val);
  } else if (name.equals("FX7")) {
    sendOSC("/controller/sendLevel4", val);
  } else if (name.equals("di_drive")) {
    sendOSC("/controller/di_drive", val);
  } else if (name.equals("di_tone")) {
    sendOSC("/controller/di_tone", val);
  } else if (name.equals("di_mix")) {
    sendOSC("/controller/di_mix", val);
  } else if (name.equals("di_output")) {
    sendOSC("/controller/di_output", val);

    // 4.2.4 Waveforms Levels
  } else if (name.equals("level1")) {
    sendOSC("/controller/level1", val);
  } else if (name.equals("level2")) {
    sendOSC("/controller/level2", val);
  } else if (name.equals("level3")) {
    sendOSC("/controller/level3", val);

    // 4.2.5 Waveforms Octaves
  } else if (name.equals("octave1")) {
    sendOSC("/controller/octave1", round(val));
  } else if (name.equals("octave2")) {
    sendOSC("/controller/octave2", round(val));
  } else if (name.equals("octave3")) {
    sendOSC("/controller/octave3", round(val));

    // 4.2.6 Waveforms Types
  } else if (name.startsWith("waveform")) {
    int idx = (int) val;
    sendOSC("/controller/" + name, idx);

    // 4.2.7 Glide
  //} else if (name.equals("glide")) {
  //  sendOSC("/controller/glide", val);

    
    
        // 4.2.7 Glide
  } else if (name.equals("glide")) {
    sendOSC("/controller/glide", val);
  } else if (name.equals("glideRange")) {
  int selected = (int) val;
  
  // aggiorna i limiti in base alla selezione
  if (selected == 0) { // 1 octave
    glideMin = 0.5;
    glideMax = 2.0;
  } else if (selected == 1) { // 2 octaves
    glideMin = 0.25;
    glideMax = 4.0;
  } else if (selected == 2) { // 3 octaves
    glideMin = 0.125;
    glideMax = 8.0;
  }

  // aggiorna dinamicamente i limiti dello slider
  Slider glideSlider = cp5.get(Slider.class, "glide");
  glideSlider.setRange(glideMin, glideMax);
  sendOSC("/controller/glideRange", selected + 1);  // invia 1, 2 o 3
    
    // 4.2.8 POLY MONO
  } else if (name.equals("monoMode") && val == 1) {
    cp5.get(Toggle.class, "polyMode").setValue(0); // Disattiva il toggle opposto
    sendOSC("/controller/monoMode", 1);         // Attiva modalità mono
  } else if (name.equals("polyMode") && val == 1) {
    cp5.get(Toggle.class, "monoMode").setValue(0); // Disattiva il toggle opposto
    sendOSC("/controller/polyMode", 1);         // Attiva modalità poly
  
      // 4.2.9 RANDOM RESET synth
      
  } else if (name.equals("randomMode") && val == 1) {
    cp5.get(Toggle.class, "resetMode").setValue(0); 
    sendOSC("/controller/randomize", 1);         
  } else if (name.equals("resetMode") && val == 1) {
    cp5.get(Toggle.class, "randomMode").setValue(0); 
    sendOSC("/controller/reset", 1); 
  }
  
  // 4.2.10 Random e reset fx
  
    else if (name.equals("randomFXMode") && val == 1) {
    cp5.get(Toggle.class, "resetFXMode").setValue(0);
    sendOSC("/controller/randomizeFX", 1);
  } else if (name.equals("resetFXMode") && val == 1) {
    cp5.get(Toggle.class, "randomFXMode").setValue(0); 
    sendOSC("/controller/resetFX", 1); 
  }
    
}


// === 5. Ricezione OSC ===
void oscEvent(OscMessage m) {

  String addr = m.addrPattern();
  float val = m.get(0).floatValue();

  // 5.1 LPF & LFO
  if (addr.equals("/controller/cutoff")) {
    cp5.get(Knob.class, "cutoff").setValue(val);
  } else if (addr.equals("/controller/lfoFreq")) {
    cp5.get(Knob.class, "lfoFreq").setValue(val);
  } else if (addr.equals("/controller/lfoDepth")) {
    cp5.get(Knob.class, "lfoDepth").setValue(val);

    // 5.2 Envelope (ADSR)
  } else if (addr.equals("/controller/attack")) {
    val = constrain(val, 0.001, 5.0);
    cp5.get(Slider.class, "attack").setValue(val);
  } else if (addr.equals("/controller/decay")) {
    cp5.get(Slider.class, "decay").setValue(val);
  } else if (addr.equals("/controller/sustain")) {
    cp5.get(Slider.class, "sustain").setValue(val);
  } else if (addr.equals("/controller/release")) {
    cp5.get(Slider.class, "release").setValue(val);

    // 5.3 FXs
  } else if (addr.equals("/controller/sendLevel1Raw")) {
    leftPadY = val;
    cp5.get(Slider.class, "FX3").setValue(abs(val));
  } else if (addr.equals("/controller/sendLevel1")) {
    cp5.get(Slider.class, "FX3").setValue(val);
    
  } else if (addr.equals("/controller/r_roomsize")) {
    cp5.get(Knob.class, "r_roomsize").setValue(val);
  } else if (addr.equals("/controller/r_mix")) {
    cp5.get(Knob.class, "r_mix").setValue(val);
  } else if (addr.equals("/controller/r_damping")) {
    cp5.get(Knob.class, "r_damping").setValue(val);
  } else if (addr.equals("/controller/r_predelay")) {
    cp5.get(Knob.class, "r_predelay").setValue(val);
    
  } else if (addr.equals("/controller/sendLevel2Raw")) {
    leftPadX = val;
    cp5.get(Slider.class, "FX4").setValue(abs(val));
  } else if (addr.equals("/controller/sendLevel2")) {
    cp5.get(Slider.class, "FX4").setValue(val);
  } else if (addr.equals("/controller/de_feedback")) {
    cp5.get(Knob.class, "de_feedback").setValue(val);
  } else if (addr.equals("/controller/de_delaytime")) {
    cp5.get(Knob.class, "de_delaytime").setValue(val);
  } else if (addr.equals("/controller/de_mix")) {
    cp5.get(Knob.class, "de_mix").setValue(val);
    
  } else if (addr.equals("/controller/sendLevel3Raw")) {
    rightPadY = val;
    cp5.get(Slider.class, "FX6").setValue(abs(val));
  } else if (addr.equals("/controller/sendLevel3")) {
    cp5.get(Slider.class, "FX6").setValue(val);
  } else if (addr.equals("/controller/f_amplitude")) {
    cp5.get(Knob.class, "f_amplitude").setValue(val);
      } else if (addr.equals("/controller/f_drywet")) {
    cp5.get(Knob.class, "f_drywet").setValue(val);
      } else if (addr.equals("/controller/f_depth")) {
    cp5.get(Knob.class, "f_depth").setValue(val);
      } else if (addr.equals("/controller/f_rate")) {
    cp5.get(Knob.class, "f_rate").setValue(val);
      } else if (addr.equals("/controller/f_feedback")) {
    cp5.get(Knob.class, "f_feedback").setValue(val);
    
  } else if (addr.equals("/controller/sendLevel4Raw")) {
    rightPadX = val;
    cp5.get(Slider.class, "FX7").setValue(abs(val));
  } else if (addr.equals("/controller/sendLevel4")) {
    cp5.get(Slider.class, "FX7").setValue(val);
  } else if (addr.equals("/controller/di_tone")) {
    cp5.get(Knob.class, "di_tone").setValue(val);
      } else if (addr.equals("/controller/di_drive")) {
    cp5.get(Knob.class, "di_drive").setValue(val);
      } else if (addr.equals("/controller/di_mix")) {
    cp5.get(Knob.class, "di_mix").setValue(val);
      } else if (addr.equals("/controller/di_output")) {
    cp5.get(Knob.class, "di_output").setValue(val);
    
    // 5.4 Waveforms Levels
  } else if (addr.equals("/controller/level1")) {
    cp5.get(Knob.class, "level1").setValue(val);
  } else if (addr.equals("/controller/level2")) {
    cp5.get(Knob.class, "level2").setValue(val);
  } else if (addr.equals("/controller/level3")) {
    cp5.get(Knob.class, "level3").setValue(val);

    // 5.5 Waveforms Types
  } else if (addr.equals("/controller/waveform1")) {
    cp5.get(DropdownList.class, "waveform1").setValue(val);
  } else if (addr.equals("/controller/waveform2")) {
    cp5.get(DropdownList.class, "waveform2").setValue(val);
  } else if (addr.equals("/controller/waveform3")) {
    cp5.get(DropdownList.class, "waveform3").setValue(val);

    // 5.6 Waveforms Octaves
  } else if (addr.equals("/controller/octave1")) {
    cp5.get(Knob.class, "octave1").setValue(val);
  } else if (addr.equals("/controller/octave2")) {
    cp5.get(Knob.class, "octave2").setValue(val);
  } else if (addr.equals("/controller/octave3")) {
    cp5.get(Knob.class, "octave3").setValue(val);

    // 5.7 Glide
  } else if (addr.equals("/controller/glide")) {
    cp5.get(Slider.class, "glide").setValue(val);
  } else {
    println("OSC ricevuto: " + addr + " = " + val);
  }

  // === Gestione frecce PS5 ===
  if (addr.equals("/controller/dpadLeft")) {
    cutoff_dir = -1;
    lastCutoffPressTime = millis();
  } else if (addr.equals("/controller/dpadRight")) {
    cutoff_dir = 1;
    lastCutoffPressTime = millis();
  } else if (addr.equals("/controller/dpadUp")) {
    glide_dir = 1;
    lastGlidePressTime = millis();
  } else if (addr.equals("/controller/dpadDown")) {
    glide_dir = -1;
    lastGlidePressTime = millis();
    
    // 5.8 Modalità Mono / Poly
  } else if (addr.equals("/controller/monoMode")) {
    if (val==1.0) {
    cp5.get(Toggle.class, "monoMode").setValue(1);
    cp5.get(Toggle.class, "polyMode").setValue(0);  // Disattiva l'altro
    }
  } else if (addr.equals("/controller/polyMode")) {
    if (val == 1.0) {
    cp5.get(Toggle.class, "polyMode").setValue(1);
    cp5.get(Toggle.class, "monoMode").setValue(0);// Disattiva l'altro
    }
    
    // 5.8 Modalità Random / Reset sintesi
  } else if (addr.equals("/controller/randomize")) {
    if (val==1.0) {
    cp5.get(Toggle.class, "randomMode").setValue(1);
    cp5.get(Toggle.class, "resetMode").setValue(0);  // Disattiva l'altro
    }
  } else if (addr.equals("/controller/reset")) {
    if (val == 1.0) {
    cp5.get(Toggle.class, "resetMode").setValue(1);
    cp5.get(Toggle.class, "randomMode").setValue(0);
    //sendOSC("/controller/reset", 1);// Disattiva l'altro
   }
   
   } else if (addr.equals("/controller/randomizeFX")) {
     if (val == 1.0) {
     cp5.get(Toggle.class, "resetFXMode").setValue(0);
     cp5.get(Toggle.class, "randomFXMode").setValue(1);
     }
   } else if (addr.equals("/controller/resetFX")) {
     if (val == 1.0) {
     cp5.get(Toggle.class, "randomFXMode").setValue(0);
     cp5.get(Toggle.class, "resetFXMode").setValue(1);
   }
   


    
    
    
    

    

  // Joystick Simboli
  } else if (dist(mouseX, mouseY, symbolPadCenter.x, symbolPadCenter.y - 50) < 28) {
    trianglePressed = true;
    sendOSC("/controller/buttonTriangle", 1);
  } else if (dist(mouseX, mouseY, symbolPadCenter.x, symbolPadCenter.y + 50) < 28) {
    crossPressed = true;
    sendOSC("/controller/buttonCross", 1);
  } else if (dist(mouseX, mouseY, symbolPadCenter.x - 50, symbolPadCenter.y) < 28) {
    squarePressed = true;
    sendOSC("/controller/buttonSquare", 1);
  } else if (dist(mouseX, mouseY, symbolPadCenter.x + 50, symbolPadCenter.y) < 28) {
    circlePressed = true;
    sendOSC("/controller/buttonCircle", 1);
  }

}
