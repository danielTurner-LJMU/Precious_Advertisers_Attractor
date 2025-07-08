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

//helper booleans - used to control visibility of graphics that show what user is affecting when they change values
boolean borderVisible = false;
boolean rowsVisible = false;
boolean datesVisible = false;

//variable to control font size of text drawn to artwork
float fontSize = 10;

//-------------------------------------------------------------//

//creates offscreen image buffer to draw to screen
void createImageBuffer(float printX, float printY) {

  //println("buffer Created = " + printX + " - " + printY);
  //if (pgRaster == null) {
  pgRaster = createGraphics(int(printX), int(printY));
  //pgPDF = createGraphics(int(printX), int(printY), PDF, fileName);
  pg = pgRaster;
  //}

  bufferCreated = true;

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
}




void drawBuffer() {

  calculateBorder();
  calculateLoginLine();

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
    if (!pauseMotion) { //have to check this as these lines do not clear out when the motion is paused
      drawLoginLine();
    }
  }

  for (DataObjectLogin i : dataObjectsLogin) {
    i.update();
    i.activate();
    i.drawLogin();
    i.drawLoginText();
  }

  drawDates();

  step = ceil(strokeThick/8); // calculate spacing based on stroke weight
  if (step < 10) {
    step = 10;
  }

  //-----------------------------///

  pg.textSize(fontSize);


  float textCentre = (textDescent() + textAscent())*0.5; //find vertical centre of font

  // Apply a scalar adjustment because text ascent/descent might not be accurate
  float scalar = 0.8;
  textCentre *= scalar;

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

  for (DataObjectAd i : dataObjectsAd) {
    if (i.drawMe) {//check if it is selected from toggle list
      i.drawAd(textCentre);
    }
  }

  //if changing border value then draw the border helper
  if (borderVisible) {
    if (!pauseMotion) { //have to check this as these lines do not clear out when the motion is paused
      drawBorder();
    }
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
}

//Login activity is drawn along a line that is spread
//across numerous rows. 
//This function calculates the length of each individual line and
//the gap between the rows. The variables calculated here are used to position
//the login objects.
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
  pg.line(0, -5, 0, -lineLength);
  pg.square(-5, -5, 10);
  pg.fill(0);
  pg.text(date, 10, -lineLength + pg.textAscent());
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
  pg.line(0, 5, 0, lineLength);
  pg.square(-5, -5, 10);
  pg.text(date, -10, lineLength);
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
