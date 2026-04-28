/**
 * Graphics.pde
 *
 * Manages the offscreen image buffers used for rendering and export.
 * Handles drawing the timeline layout, advertiser layers, date markers,
 * border guides, and preview display.
 *
 * Supports both raster (TIFF) and vector (PDF) output. The PDF export
 * separates artwork into layers by colour, designed for risograph printing.
 */

//------- graphic objects to draw fullscale image to ---------//

PGraphics pgRaster; //Standard PGraphic - Used to draw full scale preview and for raster output
PGraphics pgPDF; //PDF PGraphic - used to save PDF version of design

/*This is container that holds the Graphics object we want to draw to.
 When drawing preview to screen it uses pgRaster.
 When exporting PDF it switches to pgPDF.
 */
PGraphics pg;

//Used to check if a buffer has been created
boolean bufferCreated = false;

//Used to update drawing on buffer. set to false when a button is pressed
Boolean shapesDrawn = false;

//pause updates on objects
boolean pauseMotion = false;

//toggle for checking if the auto-generate mode is running
boolean autoGenerate = false;
int generateLength = 200;
int generateCount = 0;

//scale factor for drawing preview to stage
float imScale;
float imScaleStored;

//Array containing various print sizes @300dpi in pixels
PVector[] printSize = {
  new PVector(1240, 1748), //A6
  new PVector(1748, 2480), //A5
  new PVector(2480, 3508), //A4
  new PVector(3508, 4961), //A3
  new PVector(2480, 2480), //Square - A4 width
};

//This is used to calculate the scalefactor for outputting the PDFs
//I want them to be the correct size when opening in Illustrator or Photoshop (@300dpi)
//PDF's are resolution independent but work with 'points' as their units. There are 72 points per inch
//To convert we need to divide 72 by our desired dpi. This will give our scale factor.
//To invert scaling i.e. sclae up from PDF to print just reverse - dpi / 72.0 ≈ 4.1667
float dpi = 300;
float pdfScaleFactor = 72.0 / dpi;

//Matching array containing print size labels for attaching to output fileNames
String[] printSizeLabel = {
  "A6", "A5", "A4", "A3", "A4 Square"
};
//Store print size label selected
String currentPrintSize = "none";

//store the centre of the image preview area
float previewCentreX, previewCentreY;
float dragOffsetX = 0;
float dragOffsetY = 0;
boolean dragEnabled = false;
PVector dragStartLoc;

//Draw the start and end dates for the date range to the buffer?
boolean drawRangeDates = true;

//helper booleans - used to control visibility of graphics that show what user is affecting when they change values
boolean borderVisible = false;
boolean rowsVisible = false;
boolean datesVisible = false;

//variable to control font size of text drawn to artwork
float fontSize = 10;

//Debounce - to limit re-draws whne stroke thicknes changes - Make more responsive for user
int lastGuiChange = 0;
int redrawDebounceMs = 300;

// Export state — 0=none, 1=tiff, 2=pdf, 3=both
// Using a flag and frame delay so the exporting notice is visible
// before the export blocks Processing's single thread
int exportMode = 0;
int exportFrameDelay = 0;

//-------------------------------------------------------------//

//creates offscreen image buffer to draw to screen
void createImageBuffer(float printX, float printY) {

  pgRaster = createGraphics(int(printX), int(printY));
  pg = pgRaster;

  bufferCreated = true;
  poolSeeded = false;  // Reset pool so it reseeds for the new buffer

  // Calculate arrival radius as proportion of shorter buffer edge
  arrivalRadius = min(printX, printY) * arrivalRadiusProportion;

  previewCentreX = ((width-guiWidth)/2) + guiWidth;
  previewCentreY = height/2;

  //scale based on longest edge (i.e. is portrait or landscape)
  if (pg.height >= pg.width) {
    imScale = (float)height/pg.height;
  } else {
    imScale = (float)(width-guiWidth)/pg.width;
  }

  //stores 'full screen' scale for the selected print size
  //used to centre preview image after it has been dragged around.
  //when zoomed out it triggers a reset of the drag Offset.
  imScaleStored = imScale;

  imageMode(CENTER);

  //initialise the DataObjectAds
  for (DataObjectAd i : dataObjectsAd) {
    i.initDraw();
  }

  //initialise the DataObjectLogins
  for (DataObjectLogin i : dataObjectsLogin) {
    i.initDraw();
  }

  // Set initial text widths
  pg.beginDraw();
  pg.textFont(labelFontMono);
  pg.textSize(fontSize);
  for (DataObjectAd i : dataObjectsAd) {
    i.cachedTextWidth = pg.textWidth(i.mySiteName);
  }
  pg.endDraw();
}


void autoGenerateInBackground() {

  if (generateCount < generateLength) {
    calculateBorder();
    calculateLoginLine();

    for (DataObjectLogin i : dataObjectsLogin) {
      i.update();
      //i.activate();
    }

    for (DataObjectAd i : dataObjectsAd) {
      i.findTarget();
      i.update();
    }
    generateCount++;

    //animate generating graphics so people know something is happening.
    pushMatrix();
    translate(previewCentreX, previewCentreY);
    fill(cTheme);
    text("GENERATING", 0, 0);
    rectMode(CENTER);
    rect(0, 15, generateCount*0.5, 10);
    noFill();
    stroke(cTheme);
    rect(0, 15, historyLength*0.5, 10);
    popMatrix();
  } else {
    //update text to show it is rendering in case this takes a while
    pushMatrix();
    translate(previewCentreX, previewCentreY);
    fill(cTheme);
    noStroke();
    text("RENDERING", 0, 0);
    popMatrix();
    //--------------------
    //Pause after generation so artwork can be explored
    pauseMotion = true;
    ((Toggle) cp5.getController("pauseMotion")).changeValue(1); //set state of toggle button silently so it doesn't broadcast
    //reset autogenerate settings and draw artwork
    autoGenerate = false;
    generateCount = 0;
    drawBuffer();
  }
}

boolean poolSeeded = false;
int lastMaxActiveTargets = -1;
ArrayList<DataObjectLogin> activeList   = new ArrayList<DataObjectLogin>();
ArrayList<DataObjectLogin> inactiveList = new ArrayList<DataObjectLogin>();

void updateActivePool() {
  // Seed on first run or after buffer reset
  if (!poolSeeded) {
    for (DataObjectLogin obj : dataObjectsLogin) obj.setActive(false);
    activeList.clear();
    inactiveList.clear();
    // Only add non-hidden objects
    for (DataObjectLogin obj : dataObjectsLogin) {
      if (!obj.hideMe) inactiveList.add(obj);
    }
    java.util.Collections.shuffle(inactiveList);
    int count = min(maxActiveTargets, inactiveList.size());
    for (int i = 0; i < count; i++) {
      DataObjectLogin obj = inactiveList.remove(0);
      obj.setActive(true);
      activeList.add(obj);
    }
    poolSeeded = true;
    lastMaxActiveTargets = maxActiveTargets;
    return;
  }

  // Resize if maxActiveTargets has changed
  if (maxActiveTargets != lastMaxActiveTargets) {
    while (activeList.size() > maxActiveTargets) {
      DataObjectLogin obj = activeList.remove(activeList.size() - 1);
      obj.setActive(false);
      inactiveList.add(obj);
    }
    while (activeList.size() < maxActiveTargets && inactiveList.size() > 0) {
      int idx = (int) random(inactiveList.size());
      DataObjectLogin obj = inactiveList.remove(idx);
      obj.setActive(true);
      activeList.add(obj);
    }
    lastMaxActiveTargets = maxActiveTargets;
    return;
  }

  // Swap — runs every frame with targetActivateChance probability
  if (random(1) > targetActivateChance) return;
  if (activeList.size() == 0 || inactiveList.size() == 0) return;

  // Deactivate one random active object
  int outIdx = (int) random(activeList.size());
  DataObjectLogin leaving = activeList.remove(outIdx);
  leaving.setActive(false);
  inactiveList.add(leaving);

  // Activate one random inactive object
  int inIdx = (int) random(inactiveList.size());
  DataObjectLogin arriving = inactiveList.remove(inIdx);
  arriving.setActive(true);
  activeList.add(arriving);
}

void drawBuffer() {

  calculateBorder();
  calculateLoginLine();

  // When timescale changes, recount visible targets and recalculate maxActiveTargets
  // as 5% of visible count (minimum 10), then reseed the pool to reflect new state.
  if (recalculateActiveTargets) {
    int visibleCount = 0;
    for (DataObjectLogin obj : dataObjectsLogin) {
      if (!obj.hideMe) visibleCount++;
    }
    maxActiveTargets = max(1, round(visibleCount * 0.05));
    // Scale swap frequency proportionally to visible target count
    targetActivateChance = constrain(visibleCount / 1000.0, 0.02, 0.95);
    poolSeeded = false; // trigger reseed
    recalculateActiveTargets = false;
  }

  pg.beginDraw();
  pg.background(255);

  //choose drawing square or round caps. Affects crosses and lines
  if (sqCaps) {
    pg.strokeCap(PROJECT);
  } else {
    pg.strokeCap(ROUND);
  }

  //if changing login Lines slider make the helper visible
  if (rowsVisible) {
    drawLoginLine();
  }

  updateActivePool();
  for (DataObjectLogin i : dataObjectsLogin) {
    i.update();
    //i.activate();
    i.drawLogin();
    //i.drawLoginText();
  }

  //if we want to draw start/end dates
  if (drawRangeDates) {
    drawDates();
  }

  step = ceil(strokeThick/8); // calculate spacing based on stroke weight
  if (step < 10) {
    step = 10;
  }

  //-----------------------------///

  //apply multiply mode so we get a sense of risograph output
  pg.blendMode(MULTIPLY);
  for (DataObjectAd i : dataObjectsAd) {
    if (!pauseMotion) {
      i.findTarget();
      i.update();
    }
    if (i.drawMe) {//check if it is selected from toggle list
      i.drawAdLines();
    }
  }
  pg.blendMode(BLEND); // Reset blending mode

  pg.textFont(labelFontMono);
  pg.textSize(fontSize);
  float ascent = pg.textAscent();
  float descent = pg.textDescent();
  float textHeight = ascent + descent;
  float baseline = (ascent + descent) * 0.5 * 0.8; //0.8. = scalar: used as ascent/descent might not be accurate

  for (DataObjectAd i : dataObjectsAd) {
    if (i.drawMe) {//check if it is selected from toggle list
      i.drawAdX();
      if (drawAdBlocks) {
        // With a rect: rect uses xColor, text colour flips to contrast
        i.drawAdLabel(baseline, ascent, textHeight, xColor, xWhite ? color(0) : color(255), true);
      } else {
        // No rect: text is always black
        i.drawAdLabel(baseline, ascent, textHeight, color(0), color(0), false);
      }
    }
  }

  //if changing border value then draw the border helper
  if (borderVisible) {
    drawBorder();
  }

  pg.endDraw();
}

//border controller sets the border size as percentage of buffer size
//this function converts the percentage to a pixel number based on
//the size of the current buffer image
void calculateBorder() {

  borderAsPixels = (pg.width/100) * border;
}

//draw border while re-sizing so user can see what they're controlling
void drawBorder() {

  pg.noFill();
  pg.stroke(0, 255, 0);
  pg.strokeWeight(4);
  pg.line(borderAsPixels, 0, borderAsPixels, pg.height);
  pg.line(pg.width - borderAsPixels, 0, pg.width - borderAsPixels, pg.height);
  pg.line(0, borderAsPixels, pg.width, borderAsPixels);
  pg.line(0, pg.height - borderAsPixels, pg.width, pg.height - borderAsPixels);
}


//draw start/end dates while re-scaling so user can see the date range easily
void drawHelperDates() {

  //convert timestamps to dates
  Date firstDate = convertDate(startDate);
  Date secondDate = convertDate(endDate);

  //create string for readout and set up meaasurmeents for background rect
  String dateReadout = "Start Date: " + firstDate + "\n" + "End Date: " + secondDate;
  textSize(18);
  float dateLength = textWidth(dateReadout);
  int padding = 10;
  rectMode(CORNER);
  textAlign(LEFT);

  //draw the rect and date
  pushMatrix();
  translate(guiWidth + 100, 100);
  fill(0, 200);
  noStroke();
  rect(0, -textAscent(), dateLength + (padding*2), textAscent() + (padding * 4.3));
  fill(0, 255, 0);
  text(dateReadout, 10, 10);
  popMatrix();

  rectMode(CENTER); //reset rect mode
  textAlign(CENTER); //reset text align
}

/**
 * Calculates the geometry of the multi-row timeline used to position login events.
 *
 * Login events are distributed across a series of horizontal rows rather than
 * a single line, so that the full date range fits within the canvas. Each row
 * represents a continuous segment of the timeline — when the line reaches the
 * right edge it wraps to the next row, similar to text wrapping on a page.
 *
 * Variables calculated here are used by DataObjectLogin.update() to position
 * each login event on the canvas based on its timestamp.
 *
 * Calculated values:
 *   rowGap          — vertical distance between rows
 *   loginLineX1/X2  — left and right x-coordinates of each row
 *   lineLength      — width of a single row
 *   totalLineLength — combined length of all rows
 *   dateSpread      — total time range (endDate - startDate) in seconds
 *   dateScale       — conversion factor from seconds to pixels
 *   dateCut         — the time duration represented by each row
 *   yOffset         — vertical offset to centre rows within the bordered area
 */
void calculateLoginLine() {

  //calculate spacing between rows
  rowGap = (pg.height-(borderAsPixels*2))/numRows;

  loginLineX1 = borderAsPixels;
  loginLineX2 = pg.width - borderAsPixels;

  lineLength = loginLineX2 - loginLineX1;
  totalLineLength = lineLength * numRows;

  dateSpread = endDate - startDate;
  dateScale = totalLineLength/dateSpread;
  dateCut = dateSpread/numRows;

  //Lines require offseting to centre vertically
  yOffset = borderAsPixels+(rowGap/2);
}

void drawLoginLine() {

  pg.stroke(0, 255, 0);
  pg.strokeWeight(4);
  //draw guide lines
  for (int i = 0; i < numRows; i++) {
    float yBasePos = i*rowGap;
    pg.line(loginLineX1, yBasePos + yOffset, loginLineX2, yBasePos + yOffset);
  }
}

//Draws the start and end dates represented by the overall date line
void drawDates() {

  //convert timestamps to dates
  Date firstDate = convertDate(startDate);
  Date secondDate = convertDate(endDate);

  //length of line drawn from date marker
  int lineLength = 40;

  //y position of the end of the full date line
  float y2 = ((numRows-1)*rowGap)+yOffset;

  pg.textFont(subFont);
  // if (pg == pgPDF) {
  //   pg.textSize(14*pdfScaleFactor);
  // } else {
  pg.textSize(fontSize + 4);
  // }
  pg.noFill();
  pg.stroke(0);
  pg.strokeWeight(1);

  //pg.rectMode(CENTER);

  //draw dates and corresponding lines
  String date = firstDate.toString();
  pg.pushMatrix();
  if (pg == pgPDF) {
    pg.translate(borderAsPixels/pdfScaleFactor, yOffset/pdfScaleFactor);
  } else {
    pg.translate(borderAsPixels, yOffset);
  }
  pg.line(0, -5, 0, -lineLength-fontSize);
  pg.square(-5, -5, 10);
  pg.fill(0);
  pg.text(date, 10, -lineLength + pg.textAscent()-fontSize);
  pg.popMatrix();

  pg.noFill();
  date = secondDate.toString();
  pg.textAlign(RIGHT);
  pg.pushMatrix();
  if (pg == pgPDF) {
    pg.translate(loginLineX2/pdfScaleFactor, y2/pdfScaleFactor);
  } else {
    pg.translate(loginLineX2, y2);
  }
  pg.line(0, 5, 0, lineLength+fontSize);
  pg.square(-5, -5, 10);
  pg.text(date, -10, lineLength+fontSize);
  pg.popMatrix();

  //reset text alignment
  pg.textAlign(LEFT);
}

// Converts a Unix timestamp (in seconds) to a Java Date object
Date convertDate(long timestamp) {

  Date date = new Date(timestamp*1000); // Multiply by 1000 to convert seconds to milliseconds
  return(date);
}

// Calculates how far the mouse has been dragged from its starting point
void calculatePreviewOffset() {

  dragOffsetX = mouseX - dragStartLoc.x;
  dragOffsetY = mouseY - dragStartLoc.y;
}

/**
 * Converts a screen coordinate (mouse position) to the corresponding
 * coordinate within the offscreen image buffer.
 *
 * The preview image is drawn to screen using a chain of transformations:
 * it is translated to the preview centre, offset by any drag movement,
 * and scaled by imScale. It is also drawn in CENTER image mode, meaning
 * its origin is at its centre rather than its top-left corner.
 *
 * This function reverses all of those transformations in order, allowing
 * a screen position (e.g. the mouse) to be mapped back to the correct
 * pixel location on the buffer — used for detecting rollovers on login objects.
 *
 * @param mx  Mouse x position in screen coordinates
 * @param my  Mouse y position in screen coordinates
 * @return    A PVector containing the equivalent position in buffer coordinates
 */
PVector screenToBuffer(float mx, float my) {
  // Reverse the translate
  float bx = mx - (previewCentreX + dragOffsetX);
  float by = my - (previewCentreY + dragOffsetY);
  // Reverse the scale
  bx /= imScale;
  by /= imScale;
  // Reverse the CENTER image mode offset (shift from centre back to top-left origin)
  bx += pg.width / 2.0;
  by += pg.height / 2.0;
  return new PVector(bx, by);
}

void drawPreview() {

  //set scale value to match imScale
  Controller c = cp5.getController("imScale");

  //Each paper size has a different scale value where it shows the entire piece.
  //If the preview scale (zoom) is sufficient to show the whole image, this function
  //re-centres the preview by reducing the drag offset.
  if (c.getValue() <= imScaleStored) {
    dragOffsetX = dragOffsetX * 0.6;
    dragOffsetY = dragOffsetY * 0.6;
  }

  if (dragEnabled) {
    calculatePreviewOffset();
  }

  pushMatrix();
  translate(previewCentreX + dragOffsetX, previewCentreY + dragOffsetY);
  scale(imScale);
  image(pg, 0, 0);
  popMatrix();

  //if changing date value then draw the date helper
  if (datesVisible) {
    drawHelperDates();
  }
}

//drawing the rollover information for login objects
void drawHoverTooltip() {
  if (hoveredLogin == null) return;

  String[] lines = {
    hoveredLogin.date,
    hoveredLogin.city + ", " + hoveredLogin.country,
    hoveredLogin.IP,
    hoveredLogin.platformInfo
  };

  int padding = 10;
  int lineH = 18;
  textFont(labelFontMono);
  textSize(13);

  // Calculate rectangle size based on widest line
  float maxW = 0;
  for (String l : lines) {
    float w = textWidth(l);
    if (w > maxW) maxW = w;
  }
  float rectW = maxW + padding * 2;
  float rectH = lines.length * lineH + padding * 2;

  // Offset tooltip to the right of the cursor
  float tx = mouseX + 15;
  float ty = mouseY;

  // Nudge left if it would go off the right edge of the screen
  if (tx + rectW > width) tx = mouseX - rectW - 15;

  // Draw background rect
  noStroke();
  fill(cTheme, 200);
  rectMode(CORNER);
  rect(tx, ty, rectW, rectH);

  // Draw text lines
  fill(cBlack);
  textAlign(LEFT);
  for (int i = 0; i < lines.length; i++) {
    if (lines[i] != null && !lines[i].isEmpty()) {
      text(lines[i], tx + padding, ty + padding + (i + 1) * lineH - 4);
    }
  }
  textAlign(CENTER);

  rectMode(CENTER); // reset to match rest of sketch
}


// Manages buffer redraws — when running, redraws every frame.
// When paused, waits for a GUI change then uses a debounce so heavy
// renders don't fire on every slider tick.
void handleBufferRedraw() {
  if (!pauseMotion) {
    drawBuffer();
    shapesDrawn = true;
  } else if (!shapesDrawn) {
    if (millis() - lastGuiChange > redrawDebounceMs) {
      drawBuffer();
      shapesDrawn = true;
      // Hide all helper graphics once redraw is complete
      borderVisible = false;
      rowsVisible = false;
    }
  }
}

// Shows feedback notices on top of the preview when the program
// is busy — either waiting to redraw or waiting to export.
// Both are drawn after drawPreview() so they appear on top of the artwork.
void handleNotices() {
  if (!shapesDrawn) drawRenderingNotice();
  if (exportMode > 0) drawExportingNotice();
}

// Deferred export handler.
// Because Processing is single-threaded the UI freezes during export.
// We count down frames first so the exporting notice is visible
// for at least 2 frames before the export blocks the thread.
void handleExport() {
  if (exportMode == 0) return; // nothing pending

  if (exportFrameDelay > 0) {
    exportFrameDelay--; // still counting down — notice is showing
    return;
  }

  // Frame delay elapsed — safe to export
  currentExportBaseName = generateBaseName(fileNameAppend);

  if (exportMode == 1) {
    // Tiff only
    String outputFileName = generateFileName("tif", fileNameAppend);
    pg.save(outputFileName);
    saveColophon(new String[]{ outputFileName });
  } else if (exportMode == 2) {
    // PDF only
    String outputFileName = generateFileName("pdf", fileNameAppend);
    outputMultiPagePDF(fileNameAppend);
    saveColophon(new String[]{ outputFileName });
  } else if (exportMode == 3) {
    // Tiff and PDF
    String tiffFileName = generateFileName("tif", fileNameAppend);
    String pdfFileName  = generateFileName("pdf", fileNameAppend);
    pg.save(tiffFileName);
    outputMultiPagePDF(fileNameAppend);
    saveColophon(new String[]{ tiffFileName, pdfFileName });
  }

  exportMode = 0; // Reset — export complete
}

// Only checks hover when mouse is in the preview area and not dragging.
// Avoids iterating all login objects unnecessarily every frame.
void handleHover() {
  if (!dragEnabled && mouseX > guiWidth) {
    checkHover();
  }
}

// Shows a 'RENDERING...' notice in the centre of the preview area.
// Appears whenever a buffer redraw is pending — quick renders will
// flash it briefly, slow ones will hold it until complete.
void drawRenderingNotice() {
  pushMatrix();
  translate(previewCentreX, previewCentreY);

  String msg = "RENDERING...";
  textFont(labelFontMono);
  textSize(18);
  float msgWidth = textWidth(msg);
  int padding = 10;

  rectMode(CENTER);
  textAlign(CENTER);
  fill(0, 200);
  noStroke();
  rect(0, 0, msgWidth + (padding * 2), textAscent() + textDescent() + (padding * 2));
  fill(cTheme);
  text(msg, 0, textAscent() * 0.4);

  rectMode(CENTER);
  textAlign(CENTER);
  popMatrix();
}

// Shows an 'EXPORTING...' notice in the centre of the preview area.
// Appears for at least 2 frames before the export blocks the thread,
// giving the user feedback that something is happening.
void drawExportingNotice() {
  pushMatrix();
  translate(previewCentreX, previewCentreY);

  String msg = "EXPORTING...";
  textFont(labelFontMono);
  textSize(18);
  float msgWidth = textWidth(msg);
  int padding = 10;

  rectMode(CENTER);
  textAlign(CENTER);
  fill(0, 200);
  noStroke();
  rect(0, 0, msgWidth + (padding * 2), textAscent() + textDescent() + (padding * 2));
  fill(cTheme);
  text(msg, 0, textAscent() * 0.4);

  rectMode(CENTER);
  textAlign(CENTER);
  popMatrix();
}
