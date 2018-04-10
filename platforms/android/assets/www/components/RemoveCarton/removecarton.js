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
        
        //document.getElementById("carton").style.display = 'block';
        document.getElementById("carton").focus();
    }
});

$('#carton').keypress(function(event){
    var keycode = (event.keyCode ? event.keyCode : event.which);
    if(keycode == '13'){
		//Check the shipment in ERP then make the carton beceom enables and on focus
        //Display all the data with the MfgCartin data from ERP
        
        //document.getElementById("carton").style.display = 'block';
        alert("carton");
    }
});
                     
/*var serviceURI = "http://spectre.int.syscom.plc.uk:8980/BoxContentsViewService",
                catalogURI = serviceURI + "/static/BoxContentsViewService.json";

            // create a new session object
            var session = new progress.data.Session();
            session.login(serviceURI, "", "");
            session.addCatalog(catalogURI);

            // create a JSDO
            var jsdo = new progress.data.JSDO({ name: 'MfgCartonLine' });
            jsdo.subscribe('AfterFill', onAfterFillCustomers, this);

            // calling fill reads from the remote OE server
            jsdo.fill();

            // this function is called after data is returned from the server
            function onAfterFillCustomers(jsdo, success, request) {

                // for each customer record returned
                jsdo.MfgCartonLine.foreach(function (MfgCartonLine) {
                    // write out some of the customer data to the page
alert("yes");
                });
            }
*/
// END_CUSTOM_CODE_homeModel