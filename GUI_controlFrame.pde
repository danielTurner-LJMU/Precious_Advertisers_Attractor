/**
 * ControlFrame - A custom draggable and scrollable control panel for toggling visibility of dataObjectsAd.
 *
 * This class creates a separate undecorated control window with a custom-drawn title bar,
 * a vertical scrollbar, and a list of toggle switches representing the visibility of `dataObjectsAd` objects
 * in the main canvas. The `drawMe` boolean in each `dataObjectsAd` object determines whether it is drawn.
 *
 * Features:
 * - Two bang buttons at the top to "Show All" or "Hide All" data objects.
 * - Search field — type and press Enter to jump the list to the first matching advertiser name.
 * - Smooth scrolling through toggles using a custom scrollbar or mouse wheel.
 * - Smooth window dragging via an emulated title bar.
 * - Click and drag over toggles to set multiple to the same state in one gesture.
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
  Integer[] sortedIndices;  // Alphabetical ordering of dataObjectsAd indices
  int toggleHeight = 25;
  int visibleHeight = 900;
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

  // Search — tracks current text field input for scroll-to position
  String searchText = "";

  // Drag-to-toggle — records the state set by the first toggle clicked on mouseDown
  // so all subsequent toggles swept over during the drag match it
  boolean dragTogglingActive = false;
  boolean dragToggleTargetState = false;


  ControlFrame(PApplet _parent, String name) {
    super();
    parent = _parent;
    PApplet.runSketch(new String[] {name}, this);
  }

  public void settings() {
    size(400, 1000);
  }

  public void setup() {
    cp5 = new ControlP5(this);

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
      .setPosition(width - 90, dragBarHeight + 10)
      .setSize(40, 20)
      .setLabel("Hide Panel")
      .setTriggerEvent(Bang.RELEASE)
      .plugTo(parent)
      .setColorForeground(cGrey)
      .setColorActive(cTheme);
    ;

    // Search field — press Enter to scroll the list to the first matching advertiser name
    cp5.addTextfield("searchField")
      .setPosition(140, dragBarHeight + 8)
      .setSize(150, 22)
      .setLabel("SEARCH - type & press enter")
      .setColor(color(255))
      .setColorBackground(color(60))
      .setColorForeground(cGrey)
      .setColorActive(cTheme)
      .setColorCursor(color(255))
      .setColorLabel(cGrey)
      .plugTo(this)
      .setAutoClear(false);
    cp5.get(Textfield.class, "searchField").getCaptionLabel()
      .setFont(cp5FontInconsolata)
      .setSize(11)
      .align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE)
      .setPaddingY(5);

    // Build a sorted index array so toggles appear alphabetically by advertiser name.
    // The array index (i) is preserved as the toggle id so controlEvent() routing
    // to dataObjectsAd[id].drawMe continues to work correctly.
    sortedIndices = new Integer[totalToggles];
    for (int i = 0; i < totalToggles; i++) sortedIndices[i] = i;
    java.util.Arrays.sort(sortedIndices, new java.util.Comparator<Integer>() {
      public int compare(Integer a, Integer b) {
        return dataObjectsAd[a].mySiteName.compareToIgnoreCase(dataObjectsAd[b].mySiteName);
      }
    });

    // Create required number of toggles based on data entries
    for (int pos = 0; pos < totalToggles; pos++) {
      int i = sortedIndices[pos];
      String toggleName = "adToggle_" + i;
      String labelText = dataObjectsAd[i].mySiteName;

      Toggle t = cp5.addToggle(toggleName)
        .setPosition(20, toggleStartY + pos * toggleHeight)
        .setId(i)               // Set ID early
        .setSize(40, 20)
        .setLabel(labelText)
        .plugTo(parent)
        .setBroadcast(false)      // Temporarily disable event broadcast to avoid triggering event now
        .setValue(dataObjectsAd[i].drawMe)          // Set initial value silently - drawn from object
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
    for (int pos = 0; pos < totalToggles; pos++) {
      int i = sortedIndices[pos];
      Toggle t = cp5.get(Toggle.class, "adToggle_" + i);

      if (t != null) {
        float y = toggleStartY + pos * toggleHeight - scrollOffset;
        if (y < toggleStartY) {
          t.setVisible(false);
        } else {
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

  // Returns the display position (0-based) of the toggle under a given y coordinate,
  // or -1 if outside the toggle area or over the scrollbar.
  int toggleAtY(float y) {
    if (y < toggleStartY || mouseX > scrollTrackX) return -1;
    int pos = (int)((y + scrollOffset - toggleStartY) / toggleHeight);
    if (pos >= 0 && pos < totalToggles) return pos;
    return -1;
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

    // Toggle has already flipped on mouseDown — read its new state as the drag target
    int pos = toggleAtY(mouseY);
    if (pos >= 0) {
      Toggle t = cp5.get(Toggle.class, "adToggle_" + sortedIndices[pos]);
      if (t != null) {
        dragToggleTargetState = t.getBooleanValue();
        dragTogglingActive = true;
      }
    }
  }

  public void mouseReleased() {
    windowDragging = false;
    draggingThumb = false;
    dragTogglingActive = false;
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

    // Drag-to-toggle — set any toggle swept over to match the first toggle's new state
    if (dragTogglingActive && !draggingThumb && !windowDragging) {
      int pos = toggleAtY(mouseY);
      if (pos >= 0) {
        Toggle t = cp5.get(Toggle.class, "adToggle_" + sortedIndices[pos]);
        if (t != null && t.getBooleanValue() != dragToggleTargetState) {
          t.setValue(dragToggleTargetState);
        }
      }
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

  // Called by ControlP5 when Enter is pressed in the search field.
  // Finds the first advertiser name (in sorted order) that starts with
  // the typed text and jumps the scroll position to bring it to the top.
  public void searchField(String val) {
    searchText = val.trim();
    if (searchText.isEmpty()) return;

    for (int pos = 0; pos < totalToggles; pos++) {
      int i = sortedIndices[pos];
      if (dataObjectsAd[i].mySiteName.toLowerCase().startsWith(searchText.toLowerCase())) {
        float maxOffset = totalToggles * toggleHeight - visibleHeight;
        scrollOffset = constrain(pos * toggleHeight, 0, maxOffset);
        float scrollRange = scrollTrackHeight - scrollThumbHeight;
        scrollThumbY = map(scrollOffset, 0, maxOffset, scrollTrackY, scrollTrackY + scrollRange);
        return;
      }
    }
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
