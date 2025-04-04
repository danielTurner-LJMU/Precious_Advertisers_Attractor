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

//store the centre of the image preview area
float previewCentreX, previewCentreY;
float dragOffsetX = 0;
float dragOffsetY = 0;
boolean dragEnabled = false;
PVector dragStartLoc;

//-------------------------------------------------------------//

//creates offscreen image buffer to draw to screen
void createImageBuffer(float printX, float printY) {

  String fileName = "z - Output/" + "OffSite Facebok - " + year() + "-" + month() + "-" + day() + "-" + hour()+minute()+second()+".pdf";

  //println("buffer Created = " + printX + " - " + printY);
  //if (pgRaster == null) {
  pgRaster = createGraphics(int(printX), int(printY));
  // pgPDF = createGraphics(sketchWidth, sketchHeight, PDF, fileName);
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
  //drawLoginLine();
  drawDates();

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
    i.drawAd(textCentre);
  }

  for (DataObjectLogin i : dataObjectsLogin) {

    i.update();
    i.activate();
    i.drawLogin();
  }



  pg.endDraw();
}

//border controller sets the border size as percentage of buffer size
//this function converts the percentage to a pixel number based on
//the size of the current buffer image
void calculateBorder() {

  borderAsPixels = (pg.width/100) * border;
}

//Login activity is drawn along a line that is spread
//across numerous rows. (to visualise this line uncomment 'drawLoginLine())
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

  pg.stroke(0);
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

  //length of line drawn fro date marker
  int lineLength = 40;

  //y position of the end of the full date line
  float y2 = ((numRows-1)*rowGap)+yOffset;

  pg.textFont(subFont);
  pg.textSize(14);
  pg.noFill();
  pg.stroke(0);

  //pg.rectMode(CENTER);

  //draw dates and corresponding lines
  String date = firstDate.toString();
  pg.pushMatrix();
  pg.translate(borderAsPixels, yOffset);
  pg.line(0, -5, 0, -lineLength);
  pg.square(-5, -5, 10);
  pg.fill(0);
  pg.text(date, 10, -lineLength + pg.textAscent());
  pg.popMatrix();

  pg.noFill();
  date = secondDate.toString();
  pg.textAlign(RIGHT);
  pg.pushMatrix();
  pg.translate(loginLineX2, y2);
  pg.line(0, 5, 0, lineLength);
  pg.square(-5, -5, 10);
  pg.text(date, -10, lineLength);
  pg.popMatrix();

  //reset text alignment
  pg.textAlign(LEFT);
}

Date convertDate(long timestamp) {

  Date date = new Date(timestamp*1000);
  return(date);
}

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
}
