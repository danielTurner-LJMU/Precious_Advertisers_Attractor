/**
 * Colophon.pde
 *
 * Generates and saves a plain-text colophon file alongside each artwork export.
 * The colophon records the source data, visualisation settings, and output filenames
 * for a given export session, forming a human-readable record of what is depicted
 * in the artwork and how it was produced.
 *
 * Part of "Precious" — a series of Processing programs that generate artworks
 * from personal Facebook data exports.
 *
 * Author: Daniel Turner
 * Institution: Liverpool John Moores University
 * PhD Project: Precious: Reclaiming Value for Personal Data
 */

import java.util.Map;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.text.SimpleDateFormat;

// ---- COLOPHON CONFIGURATION ---- //

// Maximum character width for wrapped text blocks (advertiser list etc.)
// 80 is the classic "safe" width that won't wrap awkwardly in Notepad or similar
final int COLOPHON_LINE_WIDTH = 80;

// Separator used between advertiser names in the compact list
final String AD_SEPARATOR = ",  ";

// The divider line used between sections — matches COLOPHON_LINE_WIDTH
final String DIVIDER = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";

// ---- SESSION ID ---- //
// Generated once per program run — a short hex string used to
// link a colophon to its associated artwork files.
String sessionID = generateSessionID();


// ---- PUBLIC API ---- //

/**
 * Call this from outputTiff(), outputMultiPagePDF(), or outputTiffAndPDF()
 * passing in a list of the filenames that were just exported in that session.
 * The colophon is saved to the same output folder with a matching name.
 *
 * @param exportedFiles  Array of filenames written in this export (tif and/or pdf)
 */
void saveColophon(String[] exportedFiles) {

  String[] lines = buildColophon(exportedFiles);
  String colophonPath = generateFileName("txt", fileNameAppend + "_colophon");//generateColophonPath();
  saveStrings(colophonPath, lines);
  println("Colophon saved: " + colophonPath);
}


// ---- INTERNAL FUNCTIONS ---- //

// Generates the output path for the colophon file,
// matching the timestamp and participant label of the artwork exports.
//String generateColophonPath() {

//  String saveLocation = "x - output/";
//  String fileName = "Precious_Advertisers - " +
//    year() + "-" + nf(month(), 2) + "-" + nf(day(), 2) +
//    " - " + nf(hour(), 2) + "-" + nf(minute(), 2) + "-" + nf(second(), 2);
//  return saveLocation + fileName + " - " + currentPrintSize + " - " + fileNameAppend + "_colophon.txt";
//}


// Generates a short random hex session ID (6 characters)
String generateSessionID() {
  return hex((int) random(0xFFFFFF), 6).toLowerCase();
}


// Formats a Unix timestamp (seconds) as "DD Month YYYY  at  HH:MM"
String formatDate(long timestamp) {
  SimpleDateFormat sdf = new SimpleDateFormat("dd MMMM yyyy  'at'  HH:mm");
  return sdf.format(new java.util.Date(timestamp * 1000));
}


// Formats a Unix timestamp as date only: "DD Month YYYY"
String formatDateOnly(long timestamp) {
  SimpleDateFormat sdf = new SimpleDateFormat("dd MMMM yyyy");
  return sdf.format(new java.util.Date(timestamp * 1000));
}


// Converts a Processing color integer to a CSS-style hex string e.g. #F229AC
String colorToHex(color c) {
  return "#" + hex(c, 6).toUpperCase();
}


// Returns a YES/NO string from a boolean — used for settings display
String yn(boolean b) {
  return b ? "YES" : "NO";
}


// Pads a string to a given length using trailing spaces
String padRight(String s, int width) {
  if (s.length() >= width) return s;
  StringBuilder sb = new StringBuilder(s);
  while (sb.length() < width) sb.append(' ');
  return sb.toString();
}


/**
 * Wraps a list of names into lines no wider than COLOPHON_LINE_WIDTH,
 * separating entries with AD_SEPARATOR. Each line is indented by two spaces.
 * Names that are longer than the line width are placed on their own line.
 */
String[] wrapNameList(String[] names) {

  String indent = "  ";
  int usableWidth = COLOPHON_LINE_WIDTH - indent.length();
  ArrayList<String> wrappedLines = new ArrayList<String>();
  StringBuilder currentLine = new StringBuilder();

  for (int i = 0; i < names.length; i++) {
    String name = names[i];
    boolean isLast = (i == names.length - 1);
    String entry = isLast ? name : name + AD_SEPARATOR;

    // If adding this entry would overflow the line, flush and start a new one
    if (currentLine.length() > 0 && currentLine.length() + entry.length() > usableWidth) {
      wrappedLines.add(indent + currentLine.toString().trim());
      currentLine = new StringBuilder();
    }
    currentLine.append(entry);
  }

  // Flush any remaining content
  if (currentLine.length() > 0) {
    wrappedLines.add(indent + currentLine.toString().trim());
  }

  return wrappedLines.toArray(new String[0]);
}


/**
 * Sorts a HashMap<String, Integer> by value descending and returns
 * formatted lines as "  Key    Count" with the key padded to keyWidth characters.
 */
String[] formatHashMap(HashMap<String, Integer> map, int keyWidth) {

  // Collect entries into a sortable list
  ArrayList<Map.Entry<String, Integer>> entries = new ArrayList<Map.Entry<String, Integer>>(map.entrySet());

  // Sort descending by count
  Collections.sort(entries, new Comparator<Map.Entry<String, Integer>>() {
    public int compare(Map.Entry<String, Integer> a, Map.Entry<String, Integer> b) {
      return b.getValue().compareTo(a.getValue());
    }
  });

  String[] lines = new String[entries.size()];
  for (int i = 0; i < entries.size(); i++) {
    String key = entries.get(i).getKey();
    int count = entries.get(i).getValue();
    // Truncate key if it is longer than keyWidth to keep layout tidy
    if (key.length() > keyWidth) {
      key = key.substring(0, keyWidth - 3) + "...";
    }
    lines[i] = "  " + padRight(key, keyWidth) + nf(count, 0);
  }

  return lines;
}


/**
 * Assembles the full colophon as an array of Strings (one per line).
 * This is what gets written to the .txt file.
 *
 * @param exportedFiles  The filenames written during this export session
 */
String[] buildColophon(String[] exportedFiles) {

  ArrayList<String> lines = new ArrayList<String>();

  // Read the live time range slider values at the moment of export
  long visStart = (long) cp5.getController("timeRange").getArrayValue(0);
  long visEnd   = (long) cp5.getController("timeRange").getArrayValue(1);

  // Count visible vs hidden advertisers
  int adsVisible = 0;
  int adsHidden  = 0;
  ArrayList<String> visibleAdNames = new ArrayList<String>();

  for (DataObjectAd ad : dataObjectsAd) {
    if (ad.drawMe) {
      adsVisible++;
      visibleAdNames.add(ad.mySiteName);
    } else {
      adsHidden++;
    }
  }


  // ---- HEADER ---- //

  lines.add(DIVIDER);
  lines.add("P R E C I O U S  :  A D V E R T I S E R S");
  lines.add("Reclaiming Value for Personal Data");
  lines.add("Daniel Turner  —  LJMU  —  PhD Project, 2026");
  lines.add(DIVIDER);
  lines.add("");
  lines.add("SESSION       " + sessionID.toUpperCase());
  lines.add("PARTICIPANT   " + fileNameAppend);
  lines.add("EXPORTED      " + formatDate(System.currentTimeMillis() / 1000));
  lines.add("");


  // ---- OUTPUT FILES ---- //

  lines.add(DIVIDER);
  lines.add("OUTPUT FILES");
  lines.add(DIVIDER);
  lines.add("");
  for (String f : exportedFiles) {
    // Strip the output folder prefix for cleaner display
    lines.add("  " + f.replace("x - output/", ""));
  }
  lines.add("");


  // ---- SOURCE DATA ---- //

  lines.add(DIVIDER);
  lines.add("SOURCE DATA");
  lines.add(DIVIDER);
  lines.add("");
  lines.add("  Advertiser data   " + dataFileNameAd);
  lines.add("  Login data        " + dataFileNameLogin);
  lines.add("");
  lines.add("  Total login events      " + nf(dataObjectsLogin.length, 0));
  lines.add("  Total advertisers       " + nf(dataObjectsAd.length, 0));
  lines.add("");
  lines.add("  Full data range     " + formatDateOnly(dataObjectsLogin[dataObjectsLogin.length-1].timeStamp)
            + "  —  " + formatDateOnly(dataObjectsLogin[0].timeStamp));
  lines.add("  Visualised range    " + formatDateOnly(visStart) + "  —  " + formatDateOnly(visEnd));
  lines.add("");


  // ---- LOCATION ACTIVITY ---- //

  lines.add(DIVIDER);
  lines.add("LOCATION ACTIVITY");
  lines.add(DIVIDER);
  lines.add("");
  for (String l : formatHashMap(locationCounts, 45)) lines.add(l);
  lines.add("");


  // ---- IP ADDRESSES / PLATFORMS / ACTIONS ---- //

  lines.add(DIVIDER);
  lines.add("IP ADDRESSES");
  lines.add(DIVIDER);
  lines.add("");
  for (String l : formatHashMap(ipCounts, 45)) lines.add(l);
  lines.add("");

  lines.add(DIVIDER);
  lines.add("PLATFORMS");
  lines.add(DIVIDER);
  lines.add("");
  for (String l : formatHashMap(platformCounts, 45)) lines.add(l);
  lines.add("");

  lines.add(DIVIDER);
  lines.add("ACTIONS");
  lines.add(DIVIDER);
  lines.add("");
  for (String l : formatHashMap(actionCounts, 45)) lines.add(l);
  lines.add("");


  // ---- ADVERTISERS VISUALISED ---- //

  lines.add(DIVIDER);
  lines.add("ADVERTISERS VISUALISED  ( " + adsVisible + " of " + dataObjectsAd.length + " )");
  lines.add(DIVIDER);
  lines.add("");

  if (adsVisible > 0) {
    String[] adNameArray = visibleAdNames.toArray(new String[0]);
    for (String l : wrapNameList(adNameArray)) lines.add(l);
  } else {
    lines.add("  None");
  }

  lines.add("");
  lines.add("  " + adsHidden + " advertiser" + (adsHidden == 1 ? "" : "s") + " not visualised in this artwork.");
  lines.add("");


  // ---- PRINT SETTINGS ---- //

  lines.add(DIVIDER);
  lines.add("PRINT SETTINGS");
  lines.add(DIVIDER);
  lines.add("");
  lines.add("  Paper size       " + currentPrintSize);
  lines.add("");

  // Palette colours — iterate over however many are in the array
  StringBuilder paletteLine = new StringBuilder("  ");
  for (int i = 0; i < palette.length; i++) {
    paletteLine.append("Colour " + (i+1) + "   " + colorToHex(palette[i]));
    if (i < palette.length - 1) paletteLine.append("    ");
  }
  lines.add(paletteLine.toString());
  lines.add("");

  // Layout settings — grouped into rows of three for compactness
  lines.add("  " + padRight("Rows",        16) + padRight(str((int)numRows),   12) +
            padRight("Border",    16) + padRight(str((int)border) + "%", 12) +
            padRight("Font size", 16) + str((int)fontSize));

  lines.add("  " + padRight("Line length", 16) + padRight(str((int)historyLength), 12) +
            padRight("Line wt",    16) + padRight(str((int)strokeThick),   12) +
            padRight("X scale",    16) + str((int)xScale));

  lines.add("  " + padRight("X weight",    16) + padRight(str((int)xThickness),   12) +
            padRight("Activity",   16) + padRight(str((int)targetRadius),  12) +
            padRight("Opacity",    16) + str((int)targetOpacity));

  lines.add("");

  // Toggle settings — grouped into rows of three
  lines.add("  " + padRight("Draw lines",    16) + padRight(yn(drawTail),        12) +
            padRight("Draw X's",      16) + padRight(yn(drawX),           12) +
            padRight("Sq. caps",      16) + yn(sqCaps));

  lines.add("  " + padRight("Ad names",      16) + padRight(yn(drawAdNames),     12) +
            padRight("Ad blocks",     16) + padRight(yn(drawAdBlocks),    12) +
            padRight("X black",       16) + yn(!xWhite));

  lines.add("  " + padRight("Coloured lines",16) + padRight(yn(colourLine),      12) +
            padRight("Random wt",     16) + padRight(yn(randomLineWeight), 12) +
            padRight("Dates",         16) + yn(drawRangeDates));

  lines.add("");

  // ---- FOOTER ---- //
  lines.add(DIVIDER);

  return lines.toArray(new String[0]);
}
