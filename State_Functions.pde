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
    // add more states here if required
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
    // add more states here if required
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
  text(title, canvasCenterX, canvasCenterY+15);



  if (parentFolderPath == null) { //if no folder has been selected and none is stored in preferences
    textFont(subFont);
    String folderText = "Please Select Facebook Data Folder";
    text(folderText, canvasCenterX, 580);
  } else {
    textFont(subFont);
    textSize(14);
    text("Facebook data folder selected:", canvasCenterX, 590);
    textSize(18);
    text(folderName, canvasCenterX, 610);
  }
}

//main program scene
void draw1() {

  background(0);

  /* We are doing some balancing of performance here. When the 'pause' button is selected
   the offsecreen buffer only updates when a GUI element is selected.
   If you look in the GUI tab, I have excluded 'imScale' from this process.
   This makes for smoother exploration of the piece as the buffer is not re-drawn
   when we change the image scale.
   *** Am sure there are more I could exclude ****
   */
  if (bufferCreated) {
    if (!pauseMotion) {
      drawBuffer(); //draws to offscreen buffer
      shapesDrawn = true;
    } else {
      if (!shapesDrawn) {
        drawBuffer(); //draws to offscreen buffer
        shapesDrawn = true;
        //hide all helper graphics
        borderVisible = false;
        rowsVisible = false;
      }
    }
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

//cleanup functions
void cleanup0() {

  showController("confirm", false);

}

void cleanup1() {
}
