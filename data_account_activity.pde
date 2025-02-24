String subFolderLogin = "/security_and_login_information";
String dataFileNameLogin = "account_activity.json"; //name of the JSON file

JSONObject dataFileLogin;
JSONArray accountActivity;

//Variables used to calculate and draw timestamps across as set of horizontal lines
long startDate, endDate; //store first and last dates of activity
long dateSpread; //total distance bewteen dates
float dateCut; //modulo operator for working out line return
float dateScale; //scale factor converting date spread to line length

float border = 100;
int numRows = 10;
float rowGap;
float yOffset;
float lineLength, totalLineLength;
float loginLineX1, loginLineX2;



//-------- OBJECT CREATION ----------//
DataObjectLogin[] dataObjectsLogin;

void loadDataLogin() {

  String fullDataPath = parentFolderPath + subFolderLogin + "/" + dataFileNameLogin;
  dataFileLogin = loadJSONObject(fullDataPath);

  extractDataLogin();
}

void extractDataLogin(){
  
 accountActivity = dataFileLogin.getJSONArray("account_activity_v2");
  dataObjectsLogin = new DataObjectLogin[accountActivity.size()];

  for (int i = 0; i < accountActivity.size(); i++) {
    JSONObject thisActivity = accountActivity.getJSONObject(i);
    String action = thisActivity.getString("action");
    long timestamp = thisActivity.getLong("timestamp");
    dataObjectsLogin[i] = new DataObjectLogin(i, action, timestamp);
  }
  
  startDate = dataObjectsLogin[dataObjectsLogin.length-1].timeStamp;
  endDate = dataObjectsLogin[0].timeStamp;
  
  //println("start date = " + startDate + "\n" + "end date = " + endDate); 
}

///-------------------- LOGIN OBJECT --------------------------///
class DataObjectLogin
{
  int ID;
  String action;
  long timeStamp;
  float zeroDate;//store date zero'd out against start date
  float posX, posY; //postion for objects
  //boolean drawMe;




  DataObjectLogin(int id, String act, long time) {

    ID = id;
    action = act;
    timeStamp = time;
  }

  void initDraw() {
    
    zeroDate = timeStamp - startDate;
   // println("ID = " + ID + " time = " + timeStamp + " action = " + action);
    
  }
  void update() {
    zeroDate = timeStamp - startDate;
    posX = ((zeroDate%dateCut)*dateScale) + loginLineX1;
    posY = (int(zeroDate/dateCut)*rowGap)+yOffset;
  }

  void drawLogin() {
    
    pg.circle(posX, posY, 20);
  }
}

void calculateLoginLine(){
  
  //calculate spacing between rows
  rowGap = (pg.height-(border*2))/numRows;

  loginLineX1 = border;
  loginLineX2 = pg.width - border;

  lineLength = loginLineX2 - loginLineX1;
  totalLineLength = lineLength * numRows;

  dateSpread = endDate - startDate;
  dateScale = totalLineLength/dateSpread;
  dateCut = dateSpread/numRows;
  
}

void drawLoginLine(){
  
   //Lines require offseting to centre vertically
  yOffset = border+(rowGap/2);
  //draw guide lines
  for (int i = 0; i < numRows; i++) {
    float yBasePos = i*rowGap;
    pg.line(loginLineX1, yBasePos + yOffset, loginLineX2, yBasePos + yOffset);
  }
  
}
