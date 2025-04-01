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
