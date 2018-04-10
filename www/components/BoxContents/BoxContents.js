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
            fiCarton: '',
        },
        submit: function () {},
        exit: function () {}
    });

    parent.set('homeModel', homeModel);
})(app.home);

// START_CUSTOM_CODE_homeModel
// Add custom code here. For more information about custom code, see http://docs.telerik.com/platform/screenbuilder/troubleshooting/how-to-keep-custom-code-changes
$('#carton').keypress(function(event){

    var keycode = (event.keyCode ? event.keyCode : event.which);
   
    if(keycode == '13'){
    	var carton = document.getElementById("carton").value;
    	//if(carton != ""){
 
        //Use the carton and pass it to the web service

        // When we have the carton send it to OE and get those specific lines
        var serviceURI = 'http://spectre.int.syscom.plc.uk:8980/BoxContentsViewService',
            catalogURI = serviceURI + '/static/BoxContentsViewService.json';

        // create a new session object
        var session = new progress.data.Session();
        session.login(serviceURI, '', '');
        session.addCatalog(catalogURI);

        // create a JSDO
        var jsdo = new progress.data.JSDO({
            name: 'MfgCartonLine'
        });
        // select the "grid" div with jQuery and turn it into a Kendo UI Grid
        $('#grid').kendoGrid({
            // all Kendo UI widgets use a DataSource to specify which data to display
            dataSource: {
                transport: {
                    // when the grid tries to read data, it will call this function
                    // this could alternatively be a URL
                    read: jsdoTransportRead
                },
                error: function (e) {
                    console.log('Error: ', e);
                }
            },

            // setting up most of the grid functionality is as easy as toggling properties on and off
            groupable: false,
            sortable: false,
            reorderable: false,
            resizable: false,
            selectable: false,
            pageable: {
                refresh: true,
            },
            columns: [
                {
                    field: 'ItemCode',
                    title: 'Item'
                },
                {
                    field: 'BundleBarcode',
                    title: 'Bundle Number'
                },
                {
                    field: 'ActualQuantity',
                    title: 'Quantity'
                }
        ]

        });
        // this function is called after data is returned from the server
        function jsdoTransportRead(options) {
            jsdo.subscribe('AfterFill', function callback(jsdo, success, request) {
                jsdo.unsubscribe('AfterFill', callback, jsdo);
                if (success) {
                    options.success(jsdo.getData());
                } else {
                    options.error(request.xhr, request.xhr.status, request.exception);
                }
            }, jsdo);
            jsdo.fill();
        }
    }       
    //}
    event.preventDefault();
    //document.getElementById("carton").value = "";
});

// END_CUSTOM_CODE_homeModel