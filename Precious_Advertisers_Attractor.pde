import processing.pdf.*; //PDF Export

import java.util.*; //used for accesing date conversion function

String title = "Precious Advertisers"; //use this to set the window title

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

void outputMultiPagePDF() {

  println("saving PDF");

  //
  String outputFileName = generateFileName("pdf");
  PVector bufferSize = printSize[printSizeSelect];
  pgPDF = createGraphics(int(bufferSize.x), int(bufferSize.y), PDF, outputFileName);
  pg = pgPDF; //swap pg to PDF renderer

  PGraphicsPDF pdf = (PGraphicsPDF) pgPDF; //get the renderer



  calculateBorder();
  calculateLoginLine();

  pg.beginDraw();
  pg.background(255);
  //drawLoginLine();

  pdf.nextPage();

  for (DataObjectLogin i : dataObjectsLogin) {

    i.update();
    i.activate();
    i.drawLogin();
  }

  pdf.nextPage();

  drawDates();

  pdf.nextPage();

  ///**** Stroke Thickness stuff
  step = ceil(strokeThick/8);
  if (step < 10) {
    step = 10;
  }
  //-----------------------------///

  pg.textSize(10); //reset text size
  //find vertical centre of font
  float textCentre = (textDescent() + textAscent())*0.5;
  //ascent/descent maybe not reported correctly so the scalare lets us adjust for this
  float scalar = 0.8;
  textCentre *= scalar;


  for (DataObjectAd i : dataObjectsAd) {
    if (!pauseMotion) {
      i.findTarget();
      i.update();
    }
    if (i.drawMe) {//check if it is selected from toggle list
      i.drawAdLines();
     // pdf.nextPage(); this creates new page for every line
    }
  }

  pdf.nextPage();


  for (DataObjectAd i : dataObjectsAd) {
    if (i.drawMe) {//check if it is selected from toggle list
      i.drawAd(textCentre);
    }
  }
  pg.endDraw();

  pg.dispose();
  pg = pgRaster;
}
