String title = "Precious Advertisers"; //use this to set the window title

int guiWidth = 500; //stores the rigth edge location of the GUI area

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

  fill(255);
  text(state, width-20, height-20);
}

void resizeCanvas(int w, int h) {

  int windowX = (displayWidth - w)/2;
  int windowY = (displayHeight - h)/2;

  //println(displayWidth);
  //println("locx = " + windowX + "\nlocy = " + windowY);

  windowResize(w, h);
  surface.setLocation(windowX, windowY);
}

//common overaly graphics e..g line between controls and preview
void drawOverlays() {

  stroke(255);
  strokeWeight(1);
  line(guiWidth, 0, guiWidth, height);
}

void keyPressed(){
  
 
  if(key == 's' || key == 'S'){
    println("saving");
    pg.save("x - output/test.tif");
  }
}
