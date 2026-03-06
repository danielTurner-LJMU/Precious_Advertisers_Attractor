import processing.pdf.*; // Import PDF library for exporting visuals

import java.util.*; // Import utilities for date/time functions

String title = "Advertisers"; // Window and project title

int guiWidth = 500; //stores the right edge location of the GUI area

void setup() {

  //Have to set the size fullscreen first as cp5 buttons will not work
  //if their location is outside the initial stage size
  size(1920, 1080);
  startState(); // Initialize the application state
}

// routes to state-specific rendering functions
void draw() {

  switch( state ) {
  case 0:
    draw0();
    break;
  case 1:
    draw1();
    break;
    // Add other states here if needed
  }

  // Uncomment to debug current state visually
  // fill(255);
  // text(state, width-20, height-20);
}

// Function: resizeCanvas - resizes and centers the sketch window on screen
void resizeCanvas(int w, int h) {

  int windowX = (displayWidth - w)/2;
  int windowY = (displayHeight - h)/2;

  windowResize(w, h);
  surface.setLocation(windowX, windowY);
}

// Function: drawOverlays - Draws common overaly graphics e.g. line between controls and preview
void drawOverlays() {

  stroke(255);
  strokeWeight(1);
  line(guiWidth, 0, guiWidth, height); // vertical separator line
}

// Function: mousePressed - handles mouse press interactions for dragging preview image
void mousePressed() {


  if (state == 1) {
    if ((mouseX > guiWidth) && (mouseX < width) && (mouseY > 0) && (mouseY < height)) {
      dragEnabled = true;
      float tempX = mouseX - dragOffsetX;
      float tempY = mouseY - dragOffsetY ;
      dragStartLoc = new PVector(tempX, tempY);
    }
  }
}

// Function: mouseReleased - resets mouse dragging and hides helper graphics
void mouseReleased() {

  if (state == 1) {
    dragEnabled = false;
     if (pauseMotion) shapesDrawn = false; //re-draw buffer to clear helper lines
  }

  //hide all helper graphics
  borderVisible = false;
  rowsVisible = false;
  datesVisible = false;
}

// Checking if mouse is over login objects

void checkHover() {
  // Only check when in state 1 and mouse is in the preview area
  if (state != 1 || mouseX <= guiWidth) {
    hoveredLogin = null;
    return;
  }
  hoveredLogin = null;
  for (DataObjectLogin obj : dataObjectsLogin) {
    if (isMouseOverLogin(obj, (float)mouseX, (float)mouseY)) {
      hoveredLogin = obj;
      //println(obj);
      break;
    }
  }
}



// Function: generateFileName - builds a timestamped filename for exports
String generateFileName(String fileType) {

  String saveLocation = "x - output/";
  String fileName = "Precious_Advertisers - " +
    year() + "-" + month() + "-" + day() +
    " - " + hour() + "-" + minute() + "-" + second();

  return(saveLocation + fileName + " - " + currentPrintSize + "." + fileType);
}

// Function: outputTiff - saves current frame as TIFF
void outputTiff() {

  String outputFileName = generateFileName("tif");
  pg.save(outputFileName);
}

// Function: outputTiffAndPDF - exports both TIFF and PDF versions
void outputTiffAndPDF() {

  outputTiff();
  outputMultiPagePDF();
}

// Function: outputMultiPagePDF - exports artwork as multi-page PDF
void outputMultiPagePDF() {

  String outputFileName = generateFileName("pdf");
  PVector bufferSize = printSize[printSizeSelect];

  //PDF buffer is created using the PDF scale factor to convert from DPI to points
  pgPDF = createGraphics(int(bufferSize.x*pdfScaleFactor), int(bufferSize.y*pdfScaleFactor), PDF, outputFileName);
  pg = pgPDF; // switch to PDF context

  PGraphicsPDF pdf = (PGraphicsPDF) pgPDF; // cast to PDF renderer

  calculateBorder();
  calculateLoginLine();

  pg.beginDraw();
  pg.pushMatrix();
  pg.scale(pdfScaleFactor); //Scale all drawing by the PDF scale factor

  /////----- LOGIN CIRCLE LAYER -------///////

  //draw login circles
  for (DataObjectLogin i : dataObjectsLogin) {
    i.drawLogin();
  }

  pg.popMatrix();
  pdf.nextPage();

  /////----- COLOURED LINE LAYERS -------///////

  step = ceil(strokeThick/8); // calculate spacing
  if (step < 10) {
    step = 10;
  }

  /////----- END -------///////


  // --- Temporarily disable advertiser name drawing ---
  // We need to prevent names from drawing during individual color pages,
  // since drawAd() includes the name and we only want the white crosses.
  // We'll store the current state and restore it after this section.
  boolean drawNamesState = drawAdNames;
  drawAdNames = false;

  // Loop through the palette and draw one colour layer per PDF page
  for (int p = 0; p < palette.length; p++) {
    pg.pushMatrix();
    pg.scale(pdfScaleFactor); // Scale drawing for PDF resolution

    for (DataObjectAd i : dataObjectsAd) {
      // Only draw if object is active (toggled on)
      if (i.drawMe) {
        //check if it is using the relevant from palette array
        if (i.cVal == p) {
          i.drawAdLines(); // Draw the colored line layer
        }
      }
    }

    // If X's are set to white, draw them now — they appear on every page
    // to cut through all line layers visually
    pg.textFont(labelFontMono);
    pg.textSize(fontSize);
    float ascent = pg.textAscent();
    float descent = pg.textDescent();
    float textHeight = ascent + descent;
    float baseline = (ascent + descent) * 0.5 * 0.8; //0.8. = scalar: used as ascent/descent might not be accurate

    for (DataObjectAd i : dataObjectsAd) {
      if (xWhite) {
        i.drawAd(baseline, ascent, textHeight);
      }
    }
    pg.popMatrix();
    pdf.nextPage(); // Move to the next page in the PDF
  }

  // Restore the original drawAdNames value for future pages
  drawAdNames = drawNamesState;


  /////----- BLACK PRINT LAYERS -------///////

  pg.pushMatrix();
  pg.scale(pdfScaleFactor); // Always rescale for each new page

  // Draw the login text elements (e.g. date, IP etc.)
  //for (DataObjectLogin i : dataObjectsLogin) {
  //  i.drawLoginText();
  //}

  drawDates();

  // Draw advertiser names and X's (this time, names are visible again)
  pg.textFont(labelFontMono);
  pg.textSize(fontSize);
  float ascent = pg.textAscent();
  float descent = pg.textDescent();
  float textHeight = ascent + descent;
  float baseline = (ascent + descent) * 0.5 * 0.8; //0.8. = scalar: used as ascent/descent might not be accurate
  for (DataObjectAd i : dataObjectsAd) {
    if (i.drawMe) {//check if it is selected from toggle list
      i.drawAd(baseline, ascent, textHeight);
    }
  }

  pg.popMatrix();
  pg.endDraw();
  pg.dispose(); // Dispose of PDF resources
  pg = pgRaster; // Switch back to raster graphics buffer
}
