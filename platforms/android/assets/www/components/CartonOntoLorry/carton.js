'use strict';

app.home = kendo.observable({
    onShow: function () {},
    afterShow: function () {}
});

// START_CUSTOM_CODE_home
// Add custom code here. For more information about custom code, see http://docs.telerik.com/platform/screenbuilder/troubleshooting/how-to-keep-custom-code-changes

// END_CUSTOM_CODE_home
(function (parent) {
    var homeModel = kendo.observable({
        fields: {
            fiShipment: '',
        },
        submit: function () {
            alert("1");
        }
    });

    parent.set('homeModel', homeModel);
})(app.home);

// START_CUSTOM_CODE_homeModel
// Add custom code here. For more information about custom code, see http://docs.telerik.com/platform/screenbuilder/troubleshooting/how-to-keep-custom-code-changes

$('#shipment').keypress(function(event){
    var keycode = (event.keyCode ? event.keyCode : event.which);
    if(keycode == '13'){
		//Check the shipment in ERP then make the carton beceom enables and on focus
        //Display all the data with the MfgCartin data from ERP

        var serviceURI = "http://spectre.int.syscom.plc.uk:8980/CartonOntoLorryService",
        catalogURI = serviceURI + "/static/CartonOntoLorryService.json";

        // create a new session object
        var session = new progress.data.Session();
        session.login(serviceURI, "", "");
        session.addCatalog(catalogURI);

        // create a JSDO
        var jsdo = new progress.data.JSDO({ name: 'MfgShipment' });    
        jsdo.subscribe('AfterFill', onAfterFillCustomers, this);

        // calling fill reads from the remote OE server
        jsdo.fill();

        // this function is called after data is returned from the server
        function onAfterFillCustomers(jsdo, success, request) {

			// Find out if a record is not found
            //alert("Shipment " + document.getElementById("shipment").value + " cannot be found");

            // for each customer record returned
            jsdo.ttMfgShipment.foreach(function (MfgShipment) {
                
                var goosdreceipted = MfgShipment.data.GoodsReceipted;
                
                if(goosdreceipted == "true"){

                    alert("Shipment " + document.getElementById("shipment").value + " cannot be found");
                }
                else {

                document.getElementById("shipfrom").value = MfgShipment.data.ShipFrom;
                document.getElementById("shipto").value = MfgShipment.data.ShipTo;
                document.getElementById("planship").value = MfgShipment.data.PlannedShipDate;
                document.getElementById("carton").style.display = 'block';
        		document.getElementById("carton").focus();
                    
                }    

            });  //end of jsdo.ttMfgShipment
        }  //end of onAfterFillCustomers
    }
});

$('#carton').keypress(function(event){
    var keycode = (event.keyCode ? event.keyCode : event.which);
    if(keycode == '13'){
		//Check the shipment in ERP then make the carton beceom enables and on focus
        //Display all the data with the MfgCartin data from ERP
var carton = document.getElementById("carton").value;
    	//if(carton != ""){

        //Use the carton and pass it to the web service
    }
});


// END_CUSTOM_CODE_homeModel