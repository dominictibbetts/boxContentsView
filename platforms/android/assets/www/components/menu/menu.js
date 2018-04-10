'use strict';

app.home = kendo.observable({
    onShow: function() {},
    afterShow: function() {}
});

(function(parent) {
    var homeModel = kendo.observable({
        fields: {
            fiUsername: '',
            fiPassword: '',
        },
        submit: function() {
        }
    });

    parent.set('homeModel', homeModel);
})(app.home);

// START_CUSTOM_CODE_home
// Add custom code here. For more information about custom code, see http://docs.telerik.com/platform/screenbuilder/troubleshooting/how-to-keep-custom-code-changes

// END_CUSTOM_CODE_home
