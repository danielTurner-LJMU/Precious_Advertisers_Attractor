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

// Maximum character width for wrapped text blocks (advertiser list, low-freq IPs etc.)
// 80 is the classic "safe" width that won't wrap awkwardly in Notepad or similar
final int COLOPHON_LINE_WIDTH = 80;

// Separator used between names in compact wrapped lists
final String AD_SEPARATOR = ",  ";

// Entries with counts below this threshold are grouped into a compact wrapped list
// rather than listed individually with their count
final int FREQ_THRESHOLD = 10;

// The divider line used between sections — matches COLOPHON_LINE_WIDTH
final String DIVIDER = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━";

// ---- SESSION ID ---- //
// Generated once per program run — a short hex string used to
// link a colophon to its associated artwork files.
String sessionID = generateSessionID();


// ---- PUBLIC API ---- //

/**
 * Call this from outputTiff(), savePDF(), or outputTiffAndPDF()
 * passing in a list of the filenames that were just exported in that session.
 * The colophon is saved to the same output folder with a matching name.
 *
 * @param exportedFiles  Array of filenames written in this export (tif and/or pdf)
 */
void saveColophon(String[] exportedFiles) {

  String[] lines = buildColophon(exportedFiles);
  String colophonPath = generateColophonPath();
  saveStrings(colophonPath, lines);
  println("Colophon saved: " + colophonPath);
}


// ---- INTERNAL FUNCTIONS ---- //

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
 * Names longer than the line width are placed on their own line.
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

    if (currentLine.length() > 0 && currentLine.length() + entry.length() > usableWidth) {
      wrappedLines.add(indent + currentLine.toString().trim());
      currentLine = new StringBuilder();
    }
    currentLine.append(entry);
  }

  if (currentLine.length() > 0) {
    wrappedLines.add(indent + currentLine.toString().trim());
  }

  return wrappedLines.toArray(new String[0]);
}


/**
 * Builds a filtered HashMap containing only entries whose keys appear
 * in the login data within the given date range (visStart to visEnd).
 * Used to show only what is actually visualised in the artwork.
 *
 * @param fieldName   The DataObjectLogin field to group by ("IP", "platformInfo", "action")
 * @param visStart    Start of the visualised range as a Unix timestamp
 * @param visEnd      End of the visualised range as a Unix timestamp
 */
HashMap<String, Integer> buildFilteredMap(String fieldName, long visStart, long visEnd) {

  HashMap<String, Integer> filtered = new HashMap<String, Integer>();

  for (DataObjectLogin obj : dataObjectsLogin) {
    if (obj.timeStamp < visStart || obj.timeStamp > visEnd) continue;

    String key = "";
    if (fieldName.equals("IP"))           key = obj.IP;
    else if (fieldName.equals("platform")) key = obj.platformInfo;
    else if (fieldName.equals("action"))   key = obj.action;

    if (key != null && !key.isEmpty()) {
      filtered.put(key, filtered.containsKey(key) ? filtered.get(key) + 1 : 1);
    }
  }

  return filtered;
}


/**
 * Formats a HashMap with a two-tier display:
 *
 * Entries at or above FREQ_THRESHOLD are listed individually,
 * sorted descending by count, with the count shown on the right.
 *
 * Entries below FREQ_THRESHOLD are wrapped into a compact comma-separated
 * list under a "Seen fewer than N times:" subheading.
 *
 * @param map         The HashMap to format
 * @param allMap      The full (unfiltered) HashMap — used to calculate not-visualised count
 * @param keyWidth    Column width for keys in the individual listing
 * @param label       Human-readable label for the "not visualised" summary line
 * @param visStart    Start of visualised range (for counting not-visualised entries)
 * @param visEnd      End of visualised range
 */
ArrayList<String> formatTieredHashMap(
  HashMap<String, Integer> map,
  HashMap<String, Integer> allMap,
  int keyWidth,
  String label,
  long visStart,
  long visEnd
) {
  ArrayList<String> out = new ArrayList<String>();

  // Sort all entries by count descending
  ArrayList<Map.Entry<String, Integer>> entries =
    new ArrayList<Map.Entry<String, Integer>>(map.entrySet());

  Collections.sort(entries, new Comparator<Map.Entry<String, Integer>>() {
    public int compare(Map.Entry<String, Integer> a, Map.Entry<String, Integer> b) {
      return b.getValue().compareTo(a.getValue());
    }
  });

  // Split into above and below threshold
  ArrayList<String> highFreqLines = new ArrayList<String>();
  ArrayList<String> lowFreqNames  = new ArrayList<String>();

  for (Map.Entry<String, Integer> entry : entries) {
    String key   = entry.getKey();
    int    count = entry.getValue();

    if (count >= FREQ_THRESHOLD) {
      String displayKey = key.length() > keyWidth ? key.substring(0, keyWidth - 3) + "..." : key;
      highFreqLines.add("  " + padRight(displayKey, keyWidth) + nf(count, 0));
    } else {
      lowFreqNames.add(key);
    }
  }

  // Add high-frequency entries
  for (String l : highFreqLines) out.add(l);

  // Add low-frequency compact block if there are any
  if (lowFreqNames.size() > 0) {
    if (highFreqLines.size() > 0) out.add(""); // spacer between tiers
    out.add("  Seen fewer than " + FREQ_THRESHOLD + " times:");
    String[] lowFreqArray = lowFreqNames.toArray(new String[0]);
    for (String l : wrapNameList(lowFreqArray)) out.add(l);
  }

  // Count entries in the full map that fall outside the visualised range
  int notVisualised = 0;
  for (String key : allMap.keySet()) {
    if (!map.containsKey(key)) notVisualised++;
  }

  if (notVisualised > 0) {
    out.add("");
    out.add("  " + notVisualised + " " + label + (notVisualised == 1 ? "" : "s") +
            " not present in the visualised date range.");
  }

  return out;
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

  // Build filtered maps for the visualised date range
  HashMap<String, Integer> filteredIP       = buildFilteredMap("IP",       visStart, visEnd);
  HashMap<String, Integer> filteredPlatform = buildFilteredMap("platform", visStart, visEnd);
  HashMap<String, Integer> filteredAction   = buildFilteredMap("action",   visStart, visEnd);

  // Build filtered location map (locationCounts uses city+country key, so we filter manually)
  HashMap<String, Integer> filteredLocation = new HashMap<String, Integer>();
  for (DataObjectLogin obj : dataObjectsLogin) {
    if (obj.timeStamp >= visStart && obj.timeStamp <= visEnd) {
      String key = obj.locationKey;
      filteredLocation.put(key, filteredLocation.containsKey(key) ?
        filteredLocation.get(key) + 1 : 1);
    }
  }

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
  lines.add("Reclaiming Value from Personal Data");
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
    lines.add("  " + f.substring(f.lastIndexOf("/") + 1));
  }
  lines.add("");


  // ---- PRINT SETTINGS ---- //

  lines.add(DIVIDER);
  lines.add("PRINT SETTINGS");
  lines.add(DIVIDER);
  lines.add("");
  lines.add("  Paper size       " + currentPrintSize);
  lines.add("");

  // Palette colours — iterates over however many entries are in the array
  StringBuilder paletteLine = new StringBuilder("  ");
  for (int i = 0; i < palette.length; i++) {
    paletteLine.append("Colour " + (i + 1) + "   " + colorToHex(palette[i]));
    if (i < palette.length - 1) paletteLine.append("    ");
  }
  lines.add(paletteLine.toString());
  lines.add("");

  // Layout settings — grouped into rows of three for compactness
  lines.add("  " + padRight("Rows",        16) + padRight(str((int)numRows),       12) +
            padRight("Border",      16) + padRight(str((int)border) + "%",  12) +
            padRight("Font size",   16) + str((int)fontSize));

  lines.add("  " + padRight("Line length", 16) + padRight(str((int)historyLength), 12) +
            padRight("Line wt",     16) + padRight(str((int)strokeThick),   12) +
            padRight("X scale",     16) + str((int)xScale));

  lines.add("  " + padRight("X weight",    16) + padRight(str((int)xThickness),    12) +
            padRight("Activity",    16) + padRight(str((int)targetRadius),  12) +
            padRight("Opacity",     16) + str((int)targetOpacity));

  lines.add("");

  // Toggle settings — grouped into rows of three
  lines.add("  " + padRight("Draw lines",     16) + padRight(yn(drawTail),         12) +
            padRight("Draw X's",       16) + padRight(yn(drawX),            12) +
            padRight("Sq. caps",       16) + yn(sqCaps));

  lines.add("  " + padRight("Ad names",       16) + padRight(yn(drawAdNames),      12) +
            padRight("Ad blocks",      16) + padRight(yn(drawAdBlocks),     12) +
            padRight("X black",        16) + yn(!xWhite));

  lines.add("  " + padRight("Coloured lines", 16) + padRight(yn(colourLine),       12) +
            padRight("Random wt",      16) + padRight(yn(randomLineWeight),  12) +
            padRight("Dates",          16) + yn(drawRangeDates));

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
  lines.add("  Full data range     " +
            formatDateOnly(dataObjectsLogin[dataObjectsLogin.length - 1].timeStamp) +
            "  —  " + formatDateOnly(dataObjectsLogin[0].timeStamp));
  lines.add("  Visualised range    " + formatDateOnly(visStart) + "  —  " + formatDateOnly(visEnd));
  lines.add("");


  // ---- LOCATION ACTIVITY ( visualised range ) ---- //

  lines.add(DIVIDER);
  lines.add("LOCATION ACTIVITY  ( visualised range )");
  lines.add(DIVIDER);
  lines.add("");
  for (String l : formatTieredHashMap(filteredLocation, locationCounts, 45, "location", visStart, visEnd)) {
    lines.add(l);
  }
  lines.add("");


  // ---- IP ADDRESSES ( visualised range ) ---- //

  lines.add(DIVIDER);
  lines.add("IP ADDRESSES  ( visualised range )");
  lines.add(DIVIDER);
  lines.add("");
  for (String l : formatTieredHashMap(filteredIP, ipCounts, 45, "IP address", visStart, visEnd)) {
    lines.add(l);
  }
  lines.add("");


  // ---- PLATFORMS ( visualised range ) ---- //

  lines.add(DIVIDER);
  lines.add("PLATFORMS  ( visualised range )");
  lines.add(DIVIDER);
  lines.add("");
  for (String l : formatTieredHashMap(filteredPlatform, platformCounts, 45, "platform", visStart, visEnd)) {
    lines.add(l);
  }
  lines.add("");


  // ---- ACTIONS ( visualised range ) ---- //

  lines.add(DIVIDER);
  lines.add("ACTIONS  ( visualised range )");
  lines.add(DIVIDER);
  lines.add("");
  for (String l : formatTieredHashMap(filteredAction, actionCounts, 45, "action", visStart, visEnd)) {
    lines.add(l);
  }
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
  lines.add("  " + adsHidden + " advertiser" + (adsHidden == 1 ? "" : "s") +
            " not visualised in this artwork.");
  lines.add("");


  // ---- FOOTER ---- //

  lines.add(DIVIDER);

  return lines.toArray(new String[0]);
}
