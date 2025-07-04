import processing.pdf.*; //PDF Export

import java.util.*; //used for accesing date conversion function

String title = "Advertisers"; //use this to set the window and front page title

int guiWidth = 500; //stores the right edge location of the GUI area

void setup() {

  //Have to set the size fullscreen first as cp5 buttons will not work
  //if their location is outside the initial stage size
  size(1920, 1080);
  startState();
}

void draw() {


  switch( state ) {
  case 0:
    draw0();
    break;
  case 1:
    draw1();
    break;
  case 2:
    draw2();
    break;
    // ...
  }

  //debug marker - writes current state number to screen
  //fill(255);
  //text(state, width-20, height-20);
}

//resize and centre canvas
void resizeCanvas(int w, int h) {

  int windowX = (displayWidth - w)/2;
  int windowY = (displayHeight - h)/2;

  windowResize(w, h);
  surface.setLocation(windowX, windowY);
}

//common overaly graphics e.g. line between controls and preview
void drawOverlays() {

  stroke(255);
  strokeWeight(1);
  line(guiWidth, 0, guiWidth, height);
}

void keyPressed() {


  if (key == 's' || key == 'S') {
    println("saving");
    pg.save("x - output/test.tif");
  }
}

void mousePressed() {

  //collect mouse info for dragging around preview image when zoomed in
  if (state == 1) {
    if ((mouseX > guiWidth) && (mouseX < width) && (mouseY > 0) && (mouseY < height)) {
      dragEnabled = true;
      float tempX = mouseX - dragOffsetX;
      float tempY = mouseY - dragOffsetY ;
      dragStartLoc = new PVector(tempX, tempY);
    }
  }
}

void mouseReleased() {

  //cancel mouse dragging
  if (state == 1) {
    dragEnabled = false;
  }

  //hide all helper graphics
  borderVisible = false;
  rowsVisible = false;
  datesVisible = false;
}

String generateFileName(String fileType) {

  String saveLocation = "x - output/";
  String fileName = "Precious_Advertisers - " +
    year() + "-" + month() + "-" + day() +
    " - " + hour() + "-" + minute() + "-" + second();

  return(saveLocation + fileName + " - " + currentPrintSize + "." + fileType);
}

void outputTiff() {

  println("saving tiff");
  String outputFileName = generateFileName("tif");
  pg.save(outputFileName);
}

void outputTiffAndPDF() {

  outputTiff();
  outputMultiPagePDF();
}

void outputMultiPagePDF() {

  println("saving PDF");

  //
  String outputFileName = generateFileName("pdf");
  PVector bufferSize = printSize[printSizeSelect];

  //PDF buffer is created using the PDF scale factor to convert from DPI to points
  pgPDF = createGraphics(int(bufferSize.x*pdfScaleFactor), int(bufferSize.y*pdfScaleFactor), PDF, outputFileName);
  pg = pgPDF; //swap pg to PDF renderer

  PGraphicsPDF pdf = (PGraphicsPDF) pgPDF; //get the renderer

  calculateBorder();
  calculateLoginLine();

  pg.beginDraw();
  pg.pushMatrix();
  pg.scale(pdfScaleFactor); //adjust all drawing by the PDF scale factor

  /////----- LOGIN CIRCLE LAYER -------///////
  
  //draw login circles
  for (DataObjectLogin i : dataObjectsLogin) {
    i.drawLogin();
  }

  pg.popMatrix();

  pdf.nextPage();
  
  /////----- COLOURED LINE LAYERS -------///////

  ///**** Stroke Thickness stuff
  step = ceil(strokeThick/8);
  if (step < 10) {
    step = 10;
  }
  //-----------------------------///

  pg.textSize(fontSize); //reset text size


  float textCentre = (textDescent() + textAscent())*0.5; //find vertical centre of font
  float scalar = 0.8; //ascent/descent maybe not reported correctly so the scalare lets us adjust for this
  textCentre *= scalar;

  // temporary bool to store current state of drawAdNames
  // if we are drawing white crosses they need to be drawn over the lines
  // so they occlude when printing. drawing the advertiser names is
  // integrated within 'drawAd' so we want to temporarily turn it off here
  // meaning the advertiser name is not drawn on this page. We are storing
  // the current state so it can be reset afterwards.
  boolean drawNamesState = drawAdNames;
  drawAdNames = false;

  //loop through all line colours and draw one colour to individual pages
  for (int p = 0; p < palette.length; p++) {
    pg.pushMatrix();
    pg.scale(pdfScaleFactor);

    for (DataObjectAd i : dataObjectsAd) {
      if (i.drawMe) {//check if object is selected from toggle list
        if (i.cVal == p) { //check if it is using the relevant from palette array
          i.drawAdLines();
        }
      }
    }
    //if x's are white then draw them - We have to draw all X's to each page
    //as they need to cut through all line layers
    for (DataObjectAd i : dataObjectsAd) {
      if (xWhite) {
        i.drawAd(textCentre);
      }
    }
    pg.popMatrix();
    pdf.nextPage();
  }

  drawAdNames = drawNamesState; //reset drawAdNames value


  /////----- BLACK PRINT LAYERS -------///////
  
  pg.pushMatrix();
  pg.scale(pdfScaleFactor); //scale factor has to be applied every time we go to a new page

  //draw login data text and dates
  for (DataObjectLogin i : dataObjectsLogin) {
    i.drawLoginText();
  }

  drawDates();

  //draw the advertiser names
  for (DataObjectAd i : dataObjectsAd) {
    if (i.drawMe) {//check if it is selected from toggle list
      i.drawAd(textCentre);
    }
  }
  pg.popMatrix();
  pg.endDraw();

  pg.dispose();
  pg = pgRaster;
}
