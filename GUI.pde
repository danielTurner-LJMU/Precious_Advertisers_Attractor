import controlP5.*;
ControlP5 cp5;


// Button Size Presets s = small, l = large
int sButtonW = 150;
int sButtonH = 50;
int lButtonW = 250;
int lButtonH = 85;

//color palette
color cBlack = #282829; //Black/grey Colour
color cTheme = #fad5e5; //pink Colour
color cGrey = #aac0c1;
color cWhite = color(255, 255, 255);
color cNothing = color(0, 0, 0);

//Spacers
int cSpaceY = 100;
int cSpaceX = 60;

PFont headerFont, subFont, labelFont14, labelFont18, labelFontMono;
ControlFont cp5FontGaramond, cp5FontInconsolata;

int guiYGap = 50;

RadioButton rOutputSize;

int printSizeSelect;

//Control Frame - Used for listing all advertiser to toggle on and off
ControlFrame cf;

RGBAController xColour;

boolean controlFrameVisible = false;

/// ---- GUI SETUP AND CONTROL ---- ///

void initGUI() {

  cp5 = new ControlP5(this);

  //load fonts
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
    //.setLabel("confirm data path")
    ;

  styleIntro("confirm", "Confirm", "Top");
}

///////******* This is where all software controllers are created *******//////
///////******* Should be updated for each program *******//////
void initProgramControls(int baseX, int baseY) {

  cp5.addSlider("imScale")
    .setLabel("SCALE")
    .setPosition(baseX, baseY + cSpaceY * 0.5)
    .setSize(300, 20)
    .setRange(0, 1)
    ;

  styleMain("imScale");

  //range slider to control date range
  cp5.addRange("timeRange")
    // disable broadcasting since setRange and setRangeValues will trigger an event
    .setLabel("TIME RANGE")
    .setBroadcast(false)
    .setPosition(baseX, baseY + cSpaceY * 0.75)
    .setSize(300, 20)
    .setHandleSize(20)
    .setRange(startDate, endDate)
    .setRangeValues(startDate, endDate)
    // after the initialization we turn broadcast back on again
    .setBroadcast(true)
    ;

  styleMain("timeRange");

  cp5.addSlider("numRows")
    .setLabel("NUMBER OF ROWS")
    .setPosition(baseX, baseY + cSpaceY * 1)
    .setSize(300, 20)
    .setRange(1, 50)
    ;

  styleMain("numRows");

  cp5.addSlider("border")
    .setLabel("BORDER")
    .setPosition(baseX, baseY + cSpaceY * 1.25)
    .setSize(300, 20)
    .setRange(1, 40)
    .setValue(border);
  ;

  styleMain("border");


  cp5.addSlider("historyLength")
    .setLabel("LINE LENGTH")
    .setPosition(baseX, baseY + cSpaceY * 1.75)
    .setSize(300, 20)
    .setRange(30, 500)
    .setValue(historyLength);
  ;
  styleMain("historyLength");

  cp5.addSlider("fixedMaxSpeed")
    .setLabel("MAX SPEED")
    .setPosition(baseX, baseY + cSpaceY * 2)
    .setSize(300, 20)
    .setRange(1, 30)
    .setValue(fixedMaxSpeed);

  styleMain("fixedMaxSpeed");

  cp5.addSlider("fixedMaxForce")
    .setLabel("MAX FORCE")
    .setPosition(baseX, baseY + cSpaceY * 2.25)
    .setSize(300, 20)
    .setRange(0.01, 0.8)
    .setValue(fixedMaxForce);

  styleMain("fixedMaxForce");

  cp5.addSlider("xScale")
    .setLabel("X SCALE")
    .setPosition(baseX, baseY + cSpaceY * 2.5)
    .setSize(300, 20)
    .setRange(1, 20)
    .setValue(xScale);

  styleMain("xScale");

  cp5.addSlider("xThickness")
    .setLabel("X WEIGHT")
    .setPosition(baseX, baseY + cSpaceY * 2.75)
    .setSize(300, 20)
    .setRange(1, 100)
    .setValue(xThickness);

  styleMain("xThickness");


  // create a toggle and change the default look to a (on/off) switch look
  cp5.addToggle("drawTail")
    .setLabel("DRAW\nLINES")
    .setPosition(baseX, baseY + cSpaceY * 3)
    .setSize(50, 20)
    .setValue(true)
    //.setMode(ControlP5.SWITCH)
    ;
  styleMain("drawTail");

  cp5.addToggle("fixedSpeed")
    .setLabel("FIXED\nSPEED")
    .setPosition(baseX + cSpaceX, baseY + cSpaceY * 3)
    .setSize(50, 20)
    ;
  styleMain("fixedSpeed");

  cp5.addToggle("drawX")
    .setLabel("DRAW\nX'S")
    .setPosition(baseX + cSpaceX * 2, baseY + cSpaceY * 3)
    .setSize(50, 20)
    ;
  styleMain("drawX");

  cp5.addToggle("drawAdNames")
    .setLabel("DRAW\nADVERT\nNAMES")
    .setPosition(baseX + cSpaceX * 3, baseY + cSpaceY * 3)
    .setSize(50, 20)
    ;
  styleMain("drawAdNames");

  cp5.addToggle("sqCaps")
    .setLabel("SQUARE\nCAPS")
    .setPosition(baseX + cSpaceX * 4, baseY + cSpaceY * 3)
    .setSize(50, 20)
    ;
  styleMain("sqCaps");

  cp5.addToggle("pauseMotion")
    .setLabel("PAUSE")
    .setPosition(baseX, baseY + cSpaceY*3.75)
    .setSize(100, 40)
    ;
  styleMain("pauseMotion");

  cp5.addToggle("showAdvertisers")
    .setLabel("SHOW/HIDE\nADVERTISERS")
    .setPosition(baseX+ cSpaceX * 2, baseY + cSpaceY*3.75)
    .setSize(100, 40)
    .setValue(false);
  styleMain("showAdvertisers");

  // Launch control frame
  cf = new ControlFrame(this, "Control Panel");

  // Create the xColour RGBA slider set at position (20, 50)
  xColour = new RGBAController(cp5, "X COLOUR", baseX, baseY + cSpaceY*4.5);

  cp5.addBang("generate")
    .setLabel("GENERATE")
    .setPosition(baseX, baseY + cSpaceY * 6)
    .setSize(sButtonW, sButtonH)
    ;

  styleMain("generate");
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
    .addItem("A6", 1)
    .addItem("A5", 2)
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

  initProgramControls(baseX, baseY);

  // --- OUTPUT GROUP --- //
  baseY = 900; //update start position on y-axis

  cp5.addTextlabel("Output")
    .setText("OUTPUT")
    .setPosition(baseX, baseY + (cSpaceY * 0))
    .setColorValue(cGrey)
    .setFont(subFont)
    ;
}

//Output size selector
void outputSize(int a) {
  //println("a radio Button event: "+ a);

  //if a radio button is clicked when already selected it returns a value of -1.
  //This first 'if' catches that event.
  if (a != -1) {
    if ((a-1 != printSizeSelect)||(!bufferCreated)) { //button numbering starts at 1. Here we are aligning for an arrray that starts at 0.
      printSizeSelect = a-1;
      PVector bufferSize = printSize[printSizeSelect];
      createImageBuffer(bufferSize.x, bufferSize.y);
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
  if (theEvent.isFrom(rOutputSize)) {
    return;
  }
  c = theEvent.getController();

  shapesDrawn = false;
  //print("got an event from "+theEvent.getName()+"\t");

  if (theEvent.isFrom("timeRange")) {
    // min and max values are stored in an array.
    // access this array with controller().arrayValue().
    // min is at index 0, max is at index 1.
    startDate = int(theEvent.getController().getArrayValue(0));
    endDate = int(theEvent.getController().getArrayValue(1));
    //println(dateSpread);
  }


  if (theEvent.isFrom("fixedMaxSpeed")||theEvent.isFrom("fixedMaxForce")) {
    for (DataObjectAd i : dataObjectsAd) {
      i.changeSpeed();
    }
  }

  // Handle toggle state changes for dataObjectsAd from the controlFrame
  // This code checks if the control event came from a toggle named "adToggle_#"
  // and uses the toggle's ID to update the corresponding data object's `drawMe` flag,
  // which determines whether that object is drawn in the artwork buffer.

  if (c != null) {
    String name = c.getName();
    if (name != null && name.startsWith("adToggle_")) {
      int id = c.getId();
      boolean val = c.getValue() == 1.0;
      // update objects here
      dataObjectsAd[id].drawMe = val;
    }
  }

  //hide controlFrame and sync main tiggle button if "hidePanel" Bang is clicked in the controlFrame
  if (theEvent.isFrom("hidePanel")) {
    cp5.get(Toggle.class, "showAdvertisers").setValue(false);
  }

  ///check xColor is fully initialised + event is from xColor controller
  if (xColour != null && xColour.detectEvent(theEvent)) {
    xColor = xColour.getColor();
  }
}

void fixedSpeed() {

  fixedSpeed = !fixedSpeed;

  for (DataObjectAd i : dataObjectsAd) {
    i.changeSpeed();
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

public void showAdvertisers(boolean val) {
  controlFrameVisible = val;
  if (cf != null && cf.isReady()) {
    cf.getSurface().setVisible(controlFrameVisible);
  }
}

class RGBAController {
  Textlabel titleLabel;
  Slider[] sliders = new Slider[3]; //change to 4 to add alpha
  String[] labels = {"Red", "Green", "Blue"}; //, "Opacity"};
  color[] sliderColors = {
    color(255, 0, 0), // Red
    color(0, 255, 0), // Green
    color(0, 0, 255), // Blue
    //color(0, 0, 0) // Gray for Alpha
  };

  float x, y;   // position of the entire control set

  RGBAController(ControlP5 cp5, String title, float x, float y) {
    this.x = x;
    this.y = y;

    // Add the title label (like a group header)
    titleLabel = cp5.addTextlabel(title + "Label")
      .setText(title)
      .setPosition(x, y)
      .setFont(cp5FontInconsolata)
      .setColorValue(cGrey); // black text

    int sliderWidth = 75; // total width 300 / 4 sliders

    // Create sliders individually
    for (int i = 0; i < sliders.length; i++) {
      sliders[i] = cp5.addSlider(labels[i])
        .setRange(0, 255)
        .setValue(0)
        .setSize(sliderWidth - 5, 15)
        .setPosition(x + i * sliderWidth, y + 20)  // placed below label
        .setLabel(labels[i])
        .setColorForeground(sliderColors[i])
        .setColorActive(sliderColors[i])
        .setColorBackground(cGrey);

      sliders[i].getCaptionLabel()
        .setText(labels[i])
        .align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE)
        .setPaddingX(2)
        .setPaddingY(2)
        .setColor(cGrey);
    }
  }

  color getColor() {
    return color(sliders[0].getValue(),
      sliders[1].getValue(),
      sliders[2].getValue());
      //sliders[3].getValue());
  }

// Checks whether a given ControlEvent came from one of this RGBAController's sliders
  boolean detectEvent(ControlEvent theEvent) {
    for (Slider s : sliders) {
      if (theEvent.isFrom(s)) return true;
    }
    return false;
  }
}
