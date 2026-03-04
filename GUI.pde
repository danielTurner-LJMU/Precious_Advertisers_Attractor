import controlP5.*;  // GUI library
ControlP5 cp5;


// Button sizes
int sButtonW = 150, sButtonH = 50;
int lButtonW = 250, lButtonH = 85;
int sliderWidth = 350;

//color palette
color cBlack = #282829; //Black/grey Colour
color cTheme = #fad5e5; //pink Colour
color cGrey = #aac0c1;
color cWhite = color(255, 255, 255);
color cNothing = color(0, 0, 0);

// Layout spacers
int cSpaceY = 100, cSpaceX = 60;

// Fonts and styles
PFont headerFont, subFont, labelFont14, labelFont18, labelFontMono;
ControlFont cp5FontGaramond, cp5FontInconsolata;

//print size options
RadioButton rOutputSize;
int printSizeSelect;

//Control Frame - Used for listing all advertiser to toggle on and off
ControlFrame cf;
boolean controlFrameVisible = false;

//Colour wheels for controlling line colors:
ColorWheel[] wheels = new ColorWheel[5];

/// ---- GUI SETUP AND CONTROL ---- ///
void initGUI() {

  cp5 = new ControlP5(this);

  // load fonts
  labelFont14 = loadFont("AGaramondPro-Regular-14.vlw");
  subFont = createFont("Inconsolata-Regular.ttf", 18, true);
  labelFontMono = createFont("Inconsolata-Bold.ttf", 12, true);
  headerFont = loadFont("MADETOMMY-Bold-24.vlw");

  cp5FontGaramond = new ControlFont(labelFont14);
  cp5FontInconsolata = new ControlFont(labelFontMono);
}

void initIntroControls() {

  cp5.addButton("selectDataPath")
    .setPosition(canvasCenterX-(sButtonW/2), 500)
    .setSize(sButtonW, sButtonH)
    ;

  //sets label stlyeing (name of controlller, Caption Label, alignment of caption label)
  styleIntro("selectDataPath", "Select Data Folder", "Top");

  cp5.addButton("confirm")
    .setPosition(canvasCenterX-(lButtonW/2), 640)
    .setSize(lButtonW, lButtonH)
    .hide()
    ;

  styleIntro("confirm", "Confirm", "Top");
}

///////******* This is where all software controllers are created *******//////
///////******* Should be updated for each program *******//////

void initProgramControls(int baseX, int baseY) {

  cp5.addSlider("imScale")
    .setLabel("SCALE")
    .setPosition(baseX, baseY + cSpaceY * 0.25)
    .setSize(sliderWidth, 20)
    .setRange(0, 1)
    ;

  styleMain("imScale");

  //range slider to control date range
  cp5.addRange("timeRange")
    // disable broadcasting since setRange and setRangeValues will trigger an event
    .setLabel("TIME RANGE")
    .setBroadcast(false)
    .setPosition(baseX, baseY + cSpaceY * 0.5)
    .setSize(sliderWidth, 20)
    .setHandleSize(20)
    .setRange(startDate, endDate)
    .setRangeValues(startDate, endDate)
    // after the initialization we turn broadcast back on again
    .setBroadcast(true)
    ;

  styleMain("timeRange");

  cp5.addSlider("numRows")
    .setLabel("NUMBER OF ROWS")
    .setPosition(baseX, baseY + cSpaceY * 0.75)
    .setSize(sliderWidth, 20)
    .setRange(1, 50)
    ;

  styleMain("numRows");

  cp5.addSlider("border")
    .setLabel("BORDER")
    .setPosition(baseX, baseY + cSpaceY * 1)
    .setSize(sliderWidth, 20)
    .setRange(-10, 40)
    .setValue(border);
  ;

  styleMain("border");

  cp5.addSlider("targetRadius")
    .setLabel("ACTIVITY SIZE")
    .setPosition(baseX, baseY + cSpaceY * 1.35)
    .setSize(sliderWidth, 20)
    .setRange(0, 2.5)
    .setValue(targetRadius);

  styleMain("targetRadius");

  cp5.addSlider("targetOpacity")
    .setLabel("ACTIVITY OPACITY")
    .setPosition(baseX, baseY + cSpaceY * 1.6)
    .setSize(sliderWidth, 20)
    .setRange(0, 255)
    .setValue(targetOpacity);

  styleMain("targetOpacity");

  cp5.addToggle("drawCity")
    .setLabel("DRAW\nCITY")
    .setPosition(baseX, baseY + cSpaceY * 1.85)
    .setSize(50, 20)
    ;
  styleMain("drawCity");

  cp5.addToggle("drawIP")
    .setLabel("DRAW\nIP")
    .setPosition(baseX + cSpaceX, baseY + cSpaceY * 1.85)
    .setSize(50, 20)
    ;
  styleMain("drawIP");

  cp5.addToggle("drawPlatform")
    .setLabel("DRAW\nPLATFORM")
    .setPosition(baseX + cSpaceX * 2, baseY + cSpaceY * 1.85)
    .setSize(50, 20)
    ;
  styleMain("drawPlatform");

  cp5.addToggle("drawDate")
    .setLabel("DRAW\nDATE")
    .setPosition(baseX + cSpaceX * 3, baseY + cSpaceY * 1.85)
    .setSize(50, 20)
    ;
  styleMain("drawDate");

  cp5.addToggle("drawAction")
    .setLabel("DRAW\nACTION")
    .setPosition(baseX + cSpaceX * 4, baseY + cSpaceY * 1.85)
    .setSize(50, 20)
    ;
  styleMain("drawAction");

  cp5.addSlider("fixedMaxSpeed")
    .setLabel("MAX SPEED")
    .setPosition(baseX, baseY + cSpaceY * 2.5)
    .setSize(sliderWidth, 20)
    .setRange(1, 30)
    .setValue(fixedMaxSpeed);

  styleMain("fixedMaxSpeed");

  cp5.addSlider("fixedMaxForce")
    .setLabel("MAX FORCE")
    .setPosition(baseX, baseY + cSpaceY * 2.75)
    .setSize(sliderWidth, 20)
    .setRange(0.01, 0.8)
    .setValue(fixedMaxForce);

  styleMain("fixedMaxForce");

  cp5.addSlider("xScale")
    .setLabel("X SCALE")
    .setPosition(baseX, baseY + cSpaceY * 3)
    .setSize(sliderWidth, 20)
    .setRange(1, 20)
    .setValue(xScale);

  styleMain("xScale");

  cp5.addSlider("xThickness")
    .setLabel("X WEIGHT")
    .setPosition(baseX, baseY + cSpaceY * 3.25)
    .setSize(sliderWidth, 20)
    .setRange(1, 200)
    .setValue(xThickness);

  styleMain("xThickness");



  cp5.addSlider("historyLength")
    .setLabel("LINE LENGTH")
    .setPosition(baseX, baseY + cSpaceY * 3.5)
    .setSize(sliderWidth, 20)
    .setRange(30, 1000)
    .setValue(200);
    ;

  styleMain("historyLength");


  cp5.addSlider("strokeThick")
    .setLabel("LINE THICKNESS")
    .setPosition(baseX, baseY + cSpaceY * 3.75)
    .setSize(sliderWidth, 20)
    .setRange(1, 400)
    .setValue(strokeThick);

  styleMain("strokeThick");


  // create a toggle and change the default look to a (on/off) switch look
  cp5.addToggle("drawTail")
    .setLabel("DRAW\nLINES")
    .setPosition(baseX, baseY + cSpaceY * 4)
    .setSize(50, 20)
    .setValue(false)
    //.setMode(ControlP5.SWITCH)
    ;
  styleMain("drawTail");

  cp5.addToggle("fixedSpeed")
    .setLabel("FIXED\nSPEED")
    .setPosition(baseX + cSpaceX, baseY + cSpaceY * 4)
    .setSize(50, 20)
    ;
  styleMain("fixedSpeed");

  cp5.addToggle("drawX")
    .setLabel("DRAW\nX'S")
    .setPosition(baseX + cSpaceX * 2, baseY + cSpaceY * 4)
    .setSize(50, 20)
    ;
  styleMain("drawX");

  cp5.addToggle("drawAdNames")
    .setLabel("DRAW\nADVERT\nNAMES")
    .setPosition(baseX + cSpaceX * 3, baseY + cSpaceY * 4)
    .setSize(50, 20)
    ;
  styleMain("drawAdNames");

  cp5.addToggle("sqCaps")
    .setLabel("SQUARE\nCAPS")
    .setPosition(baseX + cSpaceX * 4, baseY + cSpaceY * 4)
    .setSize(50, 20)
    ;
  styleMain("sqCaps");

  cp5.addToggle("xWhite")
    .setLabel("BLACK/\nWHITE")
    .setPosition(baseX + cSpaceX * 5, baseY + cSpaceY * 4)
    .setSize(50, 20)
    ;
  styleMain("xWhite");

  cp5.addToggle("randomLineWeight")
    .setLabel("RANDOM\nLINE\nWEIGHT")
    .setPosition(baseX, baseY + cSpaceY * 4.75)
    .setSize(50, 20)
    .setBroadcast(false)
    .setValue(false)
    .setBroadcast(true)
    ;
  styleMain("randomLineWeight");

  cp5.addToggle("colourLine")
    .setLabel("COLOURED\nLINES")
    .setPosition(baseX + cSpaceX, baseY + cSpaceY * 4.75)
    .setSize(50, 20)
    .setBroadcast(false)
    .setValue(true)
    .setBroadcast(true)
    ;
  styleMain("colourLine");

  //Add colour wheels
  for (int i = 0; i < palette.length; i++) {
    wheels[i] = cp5.addColorWheel("wheel" + i, baseX + cSpaceX + (i+1) * 70, int(baseY + cSpaceY * 4.75), 60)
      .setRGB(palette[i])
      .setLabel("Color " + (i + 1));
  }


  cp5.addToggle("pauseMotion")
    .setLabel("PAUSE")
    .setPosition(baseX, baseY + cSpaceY*5.7)
    .setSize(100, 40)
    ;
  styleMain("pauseMotion");

  cp5.addToggle("showAdvertisers")
    .setLabel("SHOW/HIDE\nADVERTISERS")
    .setPosition(baseX+ cSpaceX * 2, baseY + cSpaceY*5.7)
    .setSize(100, 40)
    .setValue(false);
  styleMain("showAdvertisers");

  cp5.addSlider("fontSize")
    .setLabel("FONT SIZE")
    .setPosition(baseX + cSpaceX * 4, baseY + cSpaceY * 5.7)
    .setSize(110, 20)
    .setRange(10, 28)
    .setNumberOfTickMarks(10)
    .setValue(fontSize);
  ;
  styleMain("fontSize");


  // Launch control frame
  cf = new ControlFrame(this, "Control Panel");
}
void initMainControls() {

  int baseX = 20; //base location for x-pos of controllers
  int baseY = 20; //base location for y-pos of controllers

  // --- INPUT GROUP --- //

  cp5.addTextlabel("Input")
    .setText("INPUT")
    .setPosition(baseX, baseY + (cSpaceY * 0))
    .setColorValue(cGrey)
    .setFont(subFont)
    ;

  // --- ARTWORK SIZE --- //
  baseY = 130; //update start position on y-axis

  cp5.addTextlabel("Artwork Size")
    .setText("ARTWORK SIZE")
    .setPosition(baseX, baseY + (cSpaceY * 0))
    .setColorValue(cGrey)
    .setFont(subFont)
    ;

  //radion buttons to select print output size
  rOutputSize = cp5.addRadioButton("outputSize")
    .setLabel("PRINT SIZE")
    .setPosition(baseX, baseY + (cSpaceY * 0.3))
    .setSize(40, 20)
    .setItemsPerRow(5)
    .setSpacingColumn(10)
    .setColorBackground(cGrey)
    .setColorForeground(cTheme)
    .setColorActive(cTheme)
    .setColorLabel(cGrey)
    //.addItem("A6", 1)
   // .addItem("A5", 2)
    .addItem("A4", 3)
    .addItem("A3", 4)
    .addItem("Square", 5)
    ;

  for (Toggle t : rOutputSize.getItems()) {
    t.getCaptionLabel().align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE).setPaddingY(5);
  }

  // --- CONTROLLERS GROUP --- //
  baseY = 220; //update start position on y-axis

  cp5.addTextlabel("Controls")
    .setText("CONTROLS")
    .setPosition(baseX, baseY + (cSpaceY * 0))
    .setColorValue(cGrey)
    .setFont(subFont)
    ;

  initProgramControls(baseX, baseY); //main controls section


  // --- OUTPUT GROUP --- //
  baseY = 875; //update start position on y-axis

  cp5.addTextlabel("Output")
    .setText("OUTPUT")
    .setPosition(baseX, baseY + (cSpaceY * 0))
    .setColorValue(cGrey)
    .setFont(subFont)
    ;

  cp5.addBang("outputTiff")
    .setLabel("Save Image")
    .setPosition(baseX, baseY + cSpaceY * 0.25)
    .setSize(100, 40)
    ;

  styleMain("outputTiff");

  cp5.addBang("outputMultiPagePDF")
    .setLabel("Save PDF")
    .setPosition(baseX + (cSpaceX * 2), baseY + cSpaceY * 0.25)
    .setSize(100, 40)
    ;

  styleMain("outputMultiPagePDF");

  cp5.addBang("outputTiffAndPDF")
    .setLabel("Save image and PDF")
    .setPosition(baseX + (cSpaceX * 4), baseY + cSpaceY * 0.25)
    .setSize(100, 40)
    ;

  styleMain("outputTiffAndPDF");
}

//Output size selector
void outputSize(int a) {

  //if a radio button is clicked when already selected it returns a value of -1.
  //This first 'if' catches that event.
  if (a != -1) {

    //button numbering starts at 1. Here we are aligning for an arrray that starts at 0.
    if ((a-1 != printSizeSelect)||(!bufferCreated)) {
      printSizeSelect = a-1;
      PVector bufferSize = printSize[printSizeSelect];
      createImageBuffer(bufferSize.x, bufferSize.y);
      currentPrintSize = printSizeLabel[printSizeSelect]; //store label for print size
    }
  }

  //set scale value to match imScale
  Controller c = cp5.getController("imScale");
  c.setValue(imScale);
}

void selectDataPath() {

  //selectFolder(prompt for user, name of function to call)
  selectFolder("Select a folder to process:", "folderSelected");
  initPreferences();
}

void confirm() {

  //move onto next state
  setState(1);
}

void controlEvent(ControlEvent theEvent) {

  Controller c;

  //radio buttons for output size throw an error if they are not caught here
  if (theEvent.isFrom(rOutputSize)) return;

  c = theEvent.getController();

  if (theEvent.isFrom("timeRange")) {
    // min and max values are stored in an array.
    // access this array with controller().arrayValue().
    // min is at index 0, max is at index 1.
    startDate = int(theEvent.getController().getArrayValue(0));
    endDate = int(theEvent.getController().getArrayValue(1));
    datesVisible = true;
  }


  if (theEvent.isFrom("fixedMaxSpeed")||theEvent.isFrom("fixedMaxForce")) {
    for (DataObjectAd i : dataObjectsAd) i.changeSpeed();
  }

  if (c != null) {
    String name = c.getName();

    // Handle toggle state changes for dataObjectsAd from the controlFrame
    // This code checks if the control event came from a toggle named "adToggle_#"
    // and uses the toggle's ID to update the corresponding data object's `drawMe` flag,
    // which determines whether that object is drawn in the artwork buffer.
    if (name != null && name.startsWith("adToggle_")) {
      int id = c.getId();
      dataObjectsAd[id].drawMe = c.getValue() == 1.0; // set boolean to match toggle state
    }

    // ColorWheel controls to update colours stored in "palette" array
    // it subsequently updates the 'myColor' variable in each advertiser object
    if (name != null && name.startsWith("wheel")) {
      for (int i = 0; i < wheels.length; i++) {
        if (c == wheels[i]) {
          palette[i] = wheels[i].getRGB();
          if (colourLine) {
            for (DataObjectAd p : dataObjectsAd) {
              p.myColor = palette[p.cVal];
            }
          }
        }
      }
    }
  }

  //hide controlFrame and sync main toggle button if "hidePanel" Bang is clicked in the controlFrame
  if (theEvent.isFrom("hidePanel")) {
    cp5.get(Toggle.class, "showAdvertisers").setValue(false);
  }

  if (theEvent.isFrom("border")) {
    borderVisible = true;
  }

  if (theEvent.isFrom("numRows")) {
    rowsVisible = true;
  }

  if (theEvent.isFrom("strokeThick")) {
    if (randomLineWeight) {
      for (DataObjectAd i : dataObjectsAd) {
        i.randomiseWeight();
      }
    }
  }

  //
  if (pauseMotion) {
    if (theEvent.isFrom("imScale")) {
    } else {
      shapesDrawn = false;
    }
  }
}

void fixedSpeed() {

  fixedSpeed = !fixedSpeed;

  for (DataObjectAd i : dataObjectsAd) {
    i.changeSpeed();
  }
}

void xWhite() {

  xWhite = !xWhite;

  if (xWhite) {
    xColor = color(255, 255, 255);
  } else {
    xColor = color(0, 0, 0);
  }
}

void colourLine() {

  colourLine = !colourLine;

  if (colourLine) {
    for (DataObjectAd i : dataObjectsAd) {
      i.myColor = palette[i.cVal];
    }
  } else {
    for (DataObjectAd i : dataObjectsAd) {
      i.myColor = color(0, 0, 0);
    }
  }
}

void randomLineWeight() {

  randomLineWeight = !randomLineWeight;

  if (randomLineWeight) {
    for (DataObjectAd i : dataObjectsAd) {
      i.randomiseWeight();
    }
  }
}


void showController(String theControllerName, boolean show) {

  Controller c = cp5.getController(theControllerName);

  if (show) {
    c.show();
  } else {
    c.hide();
  }
}

//// ------ CONTROLLER STYLING -------- ///

//Style settings for the app main screen

void styleMain(String theControllerName) {

  Controller c = cp5.getController(theControllerName);

  c.setColorBackground(cGrey);
  c.setColorForeground(cWhite); //needs updating
  c.setColorActive(cTheme);
  c.getCaptionLabel().setColor(cGrey);
  c.getCaptionLabel().setFont(cp5FontInconsolata);
  c.getValueLabel().setFont(cp5FontInconsolata);
  c.getCaptionLabel().setSize(14);
  c.getValueLabel().setColor(cBlack);
  c.getValueLabel().setSize(14);

  //catch bang buttons and reset foreground colour to grey
  if (c instanceof Bang) {
    c.setColorForeground(cGrey);
  }
}


//Style settings for the app intro screen

void styleIntro(String theControllerName, String label, String align) {

  Controller c = cp5.getController(theControllerName);

  c.setColorForeground(cGrey);
  c.setColorBackground(cBlack);
  c.setColorActive(cGrey);
  c.getCaptionLabel().toUpperCase(false);
  c.getCaptionLabel().setColor(cWhite);
  c.getValueLabel().setColor(cWhite);
  c.getValueLabel().setFont(cp5FontGaramond);
  c.getValueLabel().setSize(14);
  c.getCaptionLabel().setFont(cp5FontGaramond);
  c.getCaptionLabel().setSize(14);

  c.getCaptionLabel().setText(label);
}

// Show / Hide controlfrma with advertiser toggles buttons
public void showAdvertisers(boolean val) {
  controlFrameVisible = val;
  if (cf != null && cf.isReady()) {
    cf.getSurface().setVisible(controlFrameVisible);
  }
}
