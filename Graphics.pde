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


  pg.beginDraw();
  pg.background(255);
  calculateLoginLine();
  drawLoginLine();

  //find vertical centre of font
  float textCentre = (textDescent() + textAscent())*0.5;
  //Might have to be adjusted as ascent/descent maybe not reported correctly
  float scalar = 0.8;
  textCentre *= scalar;

  for (DataObjectAd i : dataObjectsAd) {
    i.findTarget();
    i.update();
    i.drawAd(textCentre);
  }
  for (DataObjectLogin i : dataObjectsLogin) {
    i.update();
    i.activate();
    i.drawLogin();
  }
  //for (int y = 0; y < pg.height; y+= 50) {
  //  for (int x = 0; x < pg.width; x+= 50) {
  //    pg.pushMatrix();
  //    pg.translate(25, 25);
  //    pg.line(x-15, y-15, x+15, y+15);
  //    pg.line(x+15, y-15, x-15, y+15);
  //    pg.popMatrix();
  //  }
  //}
  pg.endDraw();
}

void calculatePreviewOffset() {

  dragOffsetX = mouseX - dragStartLoc.x;
  dragOffsetY = mouseY - dragStartLoc.y;
}

void drawPreview() {

  //set scale value to match imScale
  Controller c = cp5.getController("imScale");

  if (c.getValue() <= imScaleStored) {
    dragOffsetX = dragOffsetX * 0.6;
    dragOffsetY = dragOffsetY * 0.6;
  }

  if (dragEnabled) {
    calculatePreviewOffset();
  }
  //println(imScale);

  pushMatrix();
  translate(previewCentreX + dragOffsetX, previewCentreY + dragOffsetY);
  scale(imScale);
  image(pg, 0, 0);
  popMatrix();

  //println("drawing");
}
