/**
 * ControlFrame - A custom draggable and scrollable control panel for toggling visibility of dataObjectsAd.
 *
 * This class creates a separate undecorated control window with a custom-drawn title bar,
 * a vertical scrollbar, and a list of toggle switches representing the visibility of `dataObjectsAd` objects
 * in the main canvas. The `drawMe` boolean in each `dataObjectsAd` object determines whether it is drawn.
 *
 * Features:
 * - Two bang buttons at the top to "Show All" or "Hide All" data objects.
 * - Smooth scrolling through toggles using a custom scrollbar or mouse wheel.
 * - Smooth window dragging via an emulated title bar.
 * - Performance-optimized toggle management using ControlP5.
 *
 * Intended for use as a companion control window to interactively manage large sets of visual elements
 * in the main canvas.
 */

class ControlFrame extends PApplet {

  ControlP5 cp5;
  PApplet parent;
  boolean ready = false;

  //Draggable title bar
  int dragBarHeight = 30;
  int windowDragOffsetX, windowDragOffsetY;
  boolean windowDragging = false;
  float windowTargetX, windowTargetY;    // Where the window *should* move to, updated on drag
  float windowCurrentX, windowCurrentY;  // Current window position, updated smoothly toward target

  int totalToggles = dataObjectsAd.length; //match number of toggles to number of advertisers
  int toggleHeight = 25;
  int visibleHeight = 500;
  int toggleStartY = dragBarHeight + 50;

  //scrollbar
  float scrollOffset = 0;
  float scrollTrackX = 370;
  float scrollTrackY = toggleStartY;
  float scrollTrackHeight = visibleHeight;

  float scrollThumbY = scrollTrackY;
  float scrollThumbHeight = 40;

  boolean draggingThumb = false;
  float dragOffsetY = 0;
  boolean thumbHovered = false;


  ControlFrame(PApplet _parent, String name) {
    super();
    parent = _parent;
    PApplet.runSketch(new String[] {name}, this);
  }

  public void settings() {
    size(400, 600);
  }

  public void setup() {
    cp5 = new ControlP5(this);
    //surface.setTitle("Show / Hide Advertisers");


    // Disable window decorations (removes close, minimize, etc.)
    javax.swing.SwingUtilities.invokeLater(() -> {
      java.awt.Frame frame = (java.awt.Frame) javax.swing.SwingUtilities.getWindowAncestor((java.awt.Component) surface.getNative());
      if (frame != null) {
        frame.dispose(); // Needed to change undecorated status
        frame.setUndecorated(true);
        // Resize the frame AFTER undecorating - to account for loss of title bar
        int newWidth = frame.getWidth();
        int newHeight = Math.max(frame.getHeight() - 30, 100);
        frame.setSize(newWidth, newHeight);
        frame.setVisible(false); // hide the frame
      }
    }
    );

    // Add "All ON" bang button
    cp5.addBang("setAllOn")
      .setPosition(20, dragBarHeight + 10)
      .setSize(40, 20)
      .setLabel("All ON")
      .plugTo(this)
      .setColorForeground(cGrey)
      .setColorActive(cTheme);
    ;

    // Add "All OFF" bang button
    cp5.addBang("setAllOff")
      .setPosition(80, dragBarHeight + 10)
      .setSize(40, 20)
      .setLabel("All OFF")
      .plugTo(this)
      .setColorForeground(cGrey)
      .setColorActive(cTheme);
    ;

    // Hide Control Panel button
    cp5.addBang("hidePanel")
      .setPosition(width - 90, dragBarHeight + 10)  // Adjust position to top-right
      .setSize(40, 20)
      .setLabel("Hide Panel")
      .setTriggerEvent(Bang.RELEASE)
      .plugTo(parent)
      .setColorForeground(cGrey)
      .setColorActive(cTheme);
    ;

    // Create 200 toggles and store them
    for (int i = 0; i < totalToggles; i++) {
      String toggleName = "adToggle_" + i;
      String labelText = dataObjectsAd[i].mySiteName; // Labels start at 1

      Toggle t = cp5.addToggle(toggleName)
        .setPosition(20, toggleStartY + i * toggleHeight)
        .setId(i)               // Set ID early
        .setSize(40, 20)
        .setLabel(labelText)
        .plugTo(parent)
        .setBroadcast(false)      // Temporarily disable event broadcast to avoid triggering event now
        .setValue(true)          // Set initial value silently
        .setBroadcast(true)      // Re-enable event broadcast
        .setColorBackground(cGrey)
        .setColorActive(cTheme)
        .setColorForeground(cWhite);
      ;


      // Make sure label is visible and positioned nicely
      t.getCaptionLabel().setVisible(true);
      t.getCaptionLabel().getStyle().marginTop = -20;
      t.getCaptionLabel().getStyle().marginLeft = 45;
    }

    ready = true;
  }

  public void draw() {
    // Background fill for entire control window, slightly extended height
    noStroke();
    fill(cBlack);
    rect(0, 0, width, height + 20);

    // Draw custom title bar background
    fill(cTheme);
    rect(0, 0, width, dragBarHeight);

    // Draw title text centered vertically within the drag bar
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(14);
    fill(cBlack);
    text("Show/Hide Advertisers", 10, dragBarHeight / 2);

    // Determine if the mouse is hovering over the scroll thumb area
    thumbHovered = mouseX > scrollTrackX &&
      mouseX < scrollTrackX + 10 &&
      mouseY > scrollThumbY &&
      mouseY < scrollThumbY + scrollThumbHeight;

    // Draw the scroll track background
    fill(cGrey);
    rect(scrollTrackX, scrollTrackY, 10, scrollTrackHeight);

    stroke(cWhite);
    // Draw the scroll thumb (the draggable part)
    // Highlight it if hovered or actively being dragged
    if (thumbHovered || draggingThumb) {
      fill(cTheme);  // Orange highlight color
    } else {
      fill(cBlack);           // Normal thumb color
    }
    rect(scrollTrackX, scrollThumbY, 10, scrollThumbHeight);

    // Smoothly update window position when dragging the window
    if (windowDragging) {
      float easing = 0.3;  // Controls smoothness of window movement

      // Gradually interpolate current window position toward the target position
      windowCurrentX = lerp(windowCurrentX, windowTargetX, easing);
      windowCurrentY = lerp(windowCurrentY, windowTargetY, easing);

      // Obtain the actual native window and update its screen position
      java.awt.Component comp = (java.awt.Component) surface.getNative();
      java.awt.Window win = javax.swing.SwingUtilities.getWindowAncestor(comp);
      if (win != null) {
        win.setLocation(Math.round(windowCurrentX), Math.round(windowCurrentY));
      }
    }

    // Loop through all toggles and update their positions based on scroll offset
    for (int i = 0; i < totalToggles; i++) {
      String toggleName = "adToggle_" + i;  // Construct toggle control name
      Toggle t = cp5.get(Toggle.class, toggleName);

      if (t != null) {
        // Calculate vertical position with scrolling offset applied
        float y = toggleStartY + i * toggleHeight - scrollOffset;

        // Hide toggles that would be covered by the title bar area
        if (y < toggleStartY) {
          t.setVisible(false);
        } else {
          // Show and position toggles normally
          t.setVisible(true);
          t.setPosition(20, y);
        }
      }
    }
  }


  public void scrollOffset(float val) {
    scrollOffset = val;
  }

  public boolean isReady() {
    return ready;
  }

  public void mousePressed() {

    if (mouseY < dragBarHeight) {
      windowDragging = true;

      java.awt.Component comp = (java.awt.Component) surface.getNative();
      java.awt.Window win = javax.swing.SwingUtilities.getWindowAncestor(comp);

      if (win != null) {
        java.awt.Point windowPos = comp.getLocationOnScreen();
        int mouseAbsX = windowPos.x + mouseX;
        int mouseAbsY = windowPos.y + mouseY;

        windowDragOffsetX = mouseAbsX - win.getX();
        windowDragOffsetY = mouseAbsY - win.getY();

        // Initialize current and target window positions
        windowCurrentX = win.getX();
        windowCurrentY = win.getY();
        windowTargetX = windowCurrentX;
        windowTargetY = windowCurrentY;
      }
    }

    if (mouseX > scrollTrackX && mouseX < scrollTrackX + 10 &&
      mouseY > scrollThumbY && mouseY < scrollThumbY + scrollThumbHeight) {
      draggingThumb = true;
      dragOffsetY = mouseY - scrollThumbY;
    }
  }

  public void mouseReleased() {

    windowDragging = false;
    draggingThumb = false;
  }

  public void mouseDragged() {
    if (windowDragging) {
      java.awt.Component comp = (java.awt.Component) surface.getNative();
      java.awt.Window win = javax.swing.SwingUtilities.getWindowAncestor(comp);

      if (win != null) {
        java.awt.Point windowPos = comp.getLocationOnScreen();
        int mouseAbsX = windowPos.x + mouseX;
        int mouseAbsY = windowPos.y + mouseY;

        // Update only target position here
        windowTargetX = mouseAbsX - windowDragOffsetX;
        windowTargetY = mouseAbsY - windowDragOffsetY;
      }
    }

    if (draggingThumb) {
      scrollThumbY = constrain(mouseY - dragOffsetY, scrollTrackY, scrollTrackY + scrollTrackHeight - scrollThumbHeight);

      // Convert thumb position to scrollOffset
      float maxOffset = totalToggles * toggleHeight - visibleHeight;
      float scrollRange = scrollTrackHeight - scrollThumbHeight;
      float thumbPos = scrollThumbY - scrollTrackY;
      scrollOffset = map(thumbPos, 0, scrollRange, 0, maxOffset);
    }
  }

  public void mouseWheel(MouseEvent event) {
    float e = event.getCount();  // Scroll direction
    scrollOffset += e * 10;      // Adjust scroll speed as needed

    // Clamp the scrollOffset to valid bounds
    float maxScroll = totalToggles * toggleHeight - visibleHeight;
    scrollOffset = constrain(scrollOffset, 0, maxScroll);

    // Update custom scroll thumb position to match scrollOffset
    scrollThumbY = map(scrollOffset, 0, maxScroll, scrollTrackY, scrollTrackY + scrollTrackHeight - scrollThumbHeight);
  }

  public void setAllOn() {
    for (int i = 0; i < totalToggles; i++) {
      String toggleName = "adToggle_" + i;
      Toggle t = cp5.get(Toggle.class, toggleName);
      if (t != null) {
        t.setValue(true);
      }
    }
  }

  public void setAllOff() {
    for (int i = 0; i < totalToggles; i++) {
      String toggleName = "adToggle_" + i;
      Toggle t = cp5.get(Toggle.class, toggleName);
      if (t != null) {
        t.setValue(false);
      }
    }
  }
}
