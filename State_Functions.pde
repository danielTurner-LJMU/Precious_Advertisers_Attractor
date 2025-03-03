int state = 0; //stores the current state

//store centre of canvas - used for button layout
float canvasCenterX, canvasCenterY;



/// ---- MAIN STATE FUNCTIONS ---- ///
//These manage the transition from one state to another.

void setState( int newState ) {
  endState();
  state = newState;
  startState();
}

void endState() {
  switch( state ) {
  case 0:
    cleanup0();
    break;
  case 1:
    cleanup1();
    break;
  case 2:
    cleanup2();
    break;
    // ...
  }
}
void startState() {
  switch( state ) {
  case 0:
    setup0();
    break;
  case 1:
    setup1();
    break;
  case 2:
    setup2();
    break;
    // ...
  }
}

// ---- INDIVIDUAL STATE CONTROLS ---- //
//individual setup(), draw() and cleanup() functions for each state

//setup functions
void setup0() {
  initGUI();
  surface.setResizable(true);
  windowTitle(title);

  //Rsize window to intro size
  resizeCanvas(800, 800);

  canvasCenterX = width/2;
  canvasCenterY = height/2;

  initIntroControls();
  initPreferences();
}

void setup1() {

  resizeCanvas(1500, 1000);

  //move datapath button and re-style
  cp5.getController("selectDataPath").setPosition(20, 50);
  styleMain("selectDataPath");

  loadDataAd();
  loadDataLogin();

  initMainControls();
}

void setup2() {
  //surface.setSize(800, 400);
}

//draw functions

//intro / folder select scene
void draw0() {
  background(cTheme);

  textAlign(CENTER);
  rectMode(CENTER);

  noFill();
  stroke(cBlack);
  strokeWeight(20);
  rect(canvasCenterX, canvasCenterY, width, height);

  textFont(headerFont);
  textSize(24);
  fill(cBlack);
  text("P R E C I O U S", canvasCenterX, canvasCenterY);

  textFont(labelFont14);
  textSize(14);
  text("Program Name Here", canvasCenterX, canvasCenterY+15);



  if (parentFolderPath == null) { //if no folder has been selected and none is stored in preferences
    textFont(subFont);
    String folderText = "Please Select Facebook Data Folder";
    text(folderText, canvasCenterX, 580);
  } else {
    textFont(subFont);
    textSize(14);
    text("Facebook data folder selected:", canvasCenterX, 590);
    // folderName = parentFolderName[parentFolderName.length - 1]; //extract final folder name from full path
    //String folderText = "Facebook data folder selected:\n\n" + folderName;
    textSize(18);
    text(folderName, canvasCenterX, 610);
  }
}

//main program scene
void draw1() {

  background(0);

  //*** drawBuffer maybe should not be called every frame as it is here.
  //*** a sub-process that draw only when it is updated makes more sense
  //*** from a performance viewpoint.
  if (bufferCreated) {
    //if(!shapesDrawn){
    drawBuffer(); //draws to offscreen buffer
    shapesDrawn = true;
    //}
    
    drawPreview(); //copies offscreen buffer to the stage
  }

  //draw background rectangle to cover GUI area
  fill(cBlack);
  rect(guiWidth/2, height/2, guiWidth, height);

  drawOverlays();

  //draw parent folder name to screen
  textFont(subFont);
  textSize(14);
  textAlign(LEFT);
  fill(cGrey);
  text(folderName, 200, 80);
}

void draw2() {
  background(100);
}

//cleanup functions
void cleanup0() {

  showController("confirm", false);

  //cp5.getController("selectDataPath").hide();
  //cp5.getController("confirm").hide();
}

void cleanup1() {
}

void cleanup2() {
}
