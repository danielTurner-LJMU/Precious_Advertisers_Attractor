/**
 * Precious: Advertisers — Attractor
 *
 * Part of "Precious" — a series of Processing programs that generate
 * artworks from personal Facebook data exports.
 *
 * This program visualises Facebook advertiser data as animated attractor
 * objects (X markers) that seek activity events across a timeline,
 * leaving trailing lines as they move. Designed for risograph print output.
 *
 * Author: Daniel Turner
 * Institution: Liverpool John Moores University
 * PhD Project: Precious: Reclaiming Value for Personal Data
 * Year: 2026
 * License: See LICENSE file
 *
 * Built with Processing 4
 * Dependencies: ControlP5 (GUI), processing.pdf (export)
 */

import processing.pdf.*; // Import PDF library for exporting visuals

import java.util.*; // Import utilities for date/time functions

String title = "Precious: Advertisers"; // Window and project title

/* Append for filename:
 Final program will have participants pseuso label passed here so works are
 attributable. All testing/development images will be appended "test"
 */
String fileNameAppend = "test";

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

//Hidden key command to test various opacities for risograph reproduction
void keyPressed() {
  if (state != 1 || !bufferCreated) return;

  boolean cmdOrCtrl = keyEvent.isMetaDown() || keyEvent.isControlDown();
  boolean shiftDown = keyEvent.isShiftDown();

  if (shiftDown && cmdOrCtrl && (key == 'r' || key == 'R')) {
    exportOpacityTestPDFs();
  }
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



// Function: generateFileName - builds a timestamped filename with appended string for exports

String generateFileName(String fileType, String label) {
  String saveLocation = "x - output/";
  String fileName = "Precious_Advertisers - " +
    year() + "-" + month() + "-" + day() +
    " - " + hour() + "-" + minute() + "-" + second();
  return(saveLocation + fileName + " - " + currentPrintSize + " - " + label + "." + fileType);
}

// Function: outputTiff - saves current frame as TIFF
void outputTiff() {

  String outputFileName = generateFileName("tif", fileNameAppend);
  pg.save(outputFileName);
  saveColophon(new String[]{ outputFileName });
}

// Function: outputTiffAndPDF - exports both TIFF and PDF versions
void outputTiffAndPDF() {

  String tiffFileName = generateFileName("tif", fileNameAppend);
  String pdfFileName  = generateFileName("pdf", fileNameAppend);

  pg.save(tiffFileName);
  outputMultiPagePDF(fileNameAppend);

  saveColophon(new String[]{ tiffFileName, pdfFileName });
}

/**
 * Exports the artwork as a multi-page PDF structured for risograph printing.
 *
 * Each page represents a separate ink colour layer:
 *   Page 1:   Login activity circles (the timeline base layer)
 *   Pages 2-N: One page per palette colour, containing only the lines
 *              drawn by advertisers assigned that colour
 *   Final page: Black layer — X markers, advertiser labels, and date markers
 *
 * White "knockout" shapes are drawn on each page to prevent colours from
 * printing on top of X markers and text, preserving legibility across layers.
 *
 * PDF output is scaled using pdfScaleFactor (72/300dpi) so that the file
 * opens at the correct physical size in Illustrator or Photoshop at 300dpi.
 *
 * After export, the graphics context is switched back to the raster buffer (pgRaster).
 *
 * @param label  A string appended to the output filename (e.g. "test", or a participant ID)
 */

void outputMultiPagePDF(String label) {

  String outputFileName = generateFileName("pdf", label);
  PVector bufferSize = printSize[printSizeSelect];

  pgPDF = createGraphics(int(bufferSize.x*pdfScaleFactor), int(bufferSize.y*pdfScaleFactor), PDF, outputFileName);
  pg = pgPDF;

  PGraphicsPDF pdf = (PGraphicsPDF) pgPDF;

  calculateBorder();
  calculateLoginLine();

  // Pre-calculate text measurements once
  pg.beginDraw();
  pg.textFont(labelFontMono);
  pg.textSize(fontSize);
  float ascent = pg.textAscent();
  float descent = pg.textDescent();
  float textHeight = ascent + descent;
  float baseline = (ascent + descent) * 0.5 * 0.8;

  // Recalculate cached text widths at PDF scale
  for (DataObjectAd i : dataObjectsAd) {
    i.cachedTextWidth = pg.textWidth(i.mySiteName);
  }

  /////----- PAGE 1: LOGIN CIRCLES -------///////

  pg.pushMatrix();
  pg.scale(pdfScaleFactor);

  for (DataObjectLogin i : dataObjectsLogin) {
    i.drawLogin();
  }

  // White knockouts on login circle page
  pg.textFont(labelFontMono);
  pg.textSize(fontSize);

  for (DataObjectAd i : dataObjectsAd) {
    if (!i.drawMe) continue;

    if (xWhite) {
      i.drawAdX();
    }

    if (xWhite && drawAdBlocks) {
      i.drawAdLabel(baseline, ascent, textHeight, color(255), color(255), true);
    }

    if (!xWhite && drawAdNames && drawAdBlocks) {
      i.drawAdLabel(baseline, ascent, textHeight, color(255), color(255), false);
    }
  }

  pg.popMatrix();
  pdf.nextPage();

  /////----- PAGES 2-N: COLOUR LINE LAYERS -------///////

  step = ceil(strokeThick/8);
  if (step < 10) step = 10;

  for (int p = 0; p < palette.length; p++) {
    pg.pushMatrix();
    pg.scale(pdfScaleFactor);

    // Draw this colour's lines
    for (DataObjectAd i : dataObjectsAd) {
      if (i.drawMe && i.cVal == p) {
        i.drawAdLines();
      }
    }

    // Draw white knockouts on every colour page
    pg.textFont(labelFontMono);
    pg.textSize(fontSize);

    for (DataObjectAd i : dataObjectsAd) {
      if (!i.drawMe) continue;

      // White X knockout (if xWhite)
      if (xWhite) {
        i.drawAdX();
      }

      // White rect knockout (if xWhite + drawAdBlocks)
      if (xWhite && drawAdBlocks) {
        i.drawAdLabel(baseline, ascent, textHeight, color(255), color(255), true);
      }

      // White text knockout (if NOT xWhite + drawAdNames + drawAdBlocks)
      if (!xWhite && drawAdNames && drawAdBlocks) {
        i.drawAdLabel(baseline, ascent, textHeight, color(255), color(255), false);
      }
    }

    pg.popMatrix();
    pdf.nextPage();
  }

  /////----- FINAL PAGE: BLACK LAYER -------///////

  pg.pushMatrix();
  pg.scale(pdfScaleFactor);

  //if we want to draw start/end dates
  if (drawRangeDates) {
    drawDates();
  }

  pg.textFont(labelFontMono);
  pg.textSize(fontSize);

  for (DataObjectAd i : dataObjectsAd) {
    if (!i.drawMe) continue;

    if (!xWhite) {
      // Black X
      i.drawAdX();
    }

    if (drawAdNames) {
      if (!drawAdBlocks) {
        // Plain black text, no rect
        i.drawAdLabel(baseline, ascent, textHeight, color(0), color(0), false);
      } else if (xWhite) {
        // Rect was already knocked out on colour pages - just draw black text
        i.drawAdLabel(baseline, ascent, textHeight, color(0), color(0), false);
      } else {
        // Black rect + white text knockout
        i.drawAdLabel(baseline, ascent, textHeight, color(0), color(255), true);
      }
    }
  }

  // Draw opacity label if this is a test export
  if (label.startsWith("opacity_")) {
    pg.textFont(labelFontMono);
    pg.textSize(36);
    pg.fill(0);
    pg.noStroke();
    pg.textAlign(LEFT);
    pg.text("line opacity: " + (int)alpha(pdfBlack), 50, 50 + pg.textAscent());
  }

  pg.popMatrix();
  pg.endDraw();
  pg.dispose();
  pg = pgRaster; // Switch back to raster buffer
}

// function to handle exporting muliple PDFs - Used to test opacity to draw lines for risograph reproduction

void exportOpacityTestPDFs() {
  int[] opacityValues = { 150, 172, 195, 217, 240 };
  color originalPdfBlack = pdfBlack;

  println("--- Starting opacity test export ---");
  for (int i = 0; i < opacityValues.length; i++) {
    int opacity = opacityValues[i];
    pdfBlack = color(0, opacity);
    println("Exporting opacity variant: " + opacity);
    outputMultiPagePDF("opacity_" + opacity);
  }

  pdfBlack = originalPdfBlack;
  println("--- Opacity test export complete ---");
}
