var gcLoginSuccess = "";
var gcInEntity = "";
var gcGlEntity = "";
var gcUsername = "";
var gcEntityWip = "";
var gcArEntity = "";
var gcActive = "";
var gcShipmentNo = "";
var gcShipmentNoForBundle = "";
var gcNoCartons = "";
var gcNoBundles = "";
var gcNoItems = "";
var gcScanBundleCarton = "";
var glCartonSingleItem = "";
var glRemocartonQ = "";
var ibundlescan = 0;
var glRemoveBundle = "";
var gcCartonSize = "";
var gcLabelPrinter = "";
var cartonkeycode = "";
var glRemoveCartonScan = "";
var glUpdateScanDate  = "";
var glAskRemoveCarton = true;
//var csite = "http://snowball.eveden.local:8980";
var csite = "http://ned.eveden.local:8980";
var gcRemoveAllPassword;
document.addEventListener("backbutton", onBackKeyDown, false);
function onBackKeyDown(e) {
  e.preventDefault();
}