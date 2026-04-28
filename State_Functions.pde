/**
 * State_Functions.pde
 *
 * Manages application state transitions between the intro screen (state 0)
 * and the main program (state 1). Each state has its own setup(), draw(),
 * and cleanup() functions, allowing for clean separation of program phases.
 */

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

  //set the maximum number of active targets to a proportion of the total login events
  maxActiveTargets = max(1, round(dataObjectsLogin.length * 0.05)); // 5%, minimum 1
  // Scale swap frequency proportionally to dataset size
  targetActivateChance = constrain(dataObjectsLogin.length / 1000.0, 0.02, 0.95);

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

  /* Performance balancing notes:
   - imScale is excluded from buffer redraws — scale is handled by drawPreview()
   - strokeThick uses a debounce — buffer only redraws after slider settles
   - All other GUI changes while paused use the same debounce so the
     rendering notice has time to appear before the redraw fires
   - Export uses a frame delay so the exporting notice is visible before
     Processing's single thread blocks during file output
   */
  if (bufferCreated) {
    if (!autoGenerate) { // check if we are autogenerating
      handleBufferRedraw();  // manages pause/debounce/redraw logic
      drawPreview();         // copies offscreen buffer to stage
      handleNotices();       // rendering and exporting notices — drawn after preview so they appear on top
      handleExport();        // deferred export with frame delay
      handleHover();         // rollover detection — only runs when mouse is in preview area
      drawHoverTooltip();
    } else {
      autoGenerateInBackground();
    }
  }

  // Draw background rectangle to cover GUI area
  fill(cBlack);
  rect(guiWidth/2, height/2, guiWidth, height);
  drawOverlays();
}

//cleanup functions
void cleanup0() {

  showController("confirm", false);
  showController("selectDataPath", false);
}

void cleanup1() {
}
