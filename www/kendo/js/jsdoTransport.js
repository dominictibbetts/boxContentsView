// Begin class declaration
var JSDOTransport = kendo.Class.extend({

    // The `init` method will be called when a new instance is created
    init: function (serviceURI, catalogURI, resourceName, tableName, filter) {
        // Create and configure the session object

        this._createSession(serviceURI, catalogURI);
        // Create the JSDO
        this.jsdo = new progress.data.JSDO({ name: resourceName });
        // Create proxies to internal methods to maintain the correct 'this' reference
        this.transport = {
            tableName: tableName,
            filter: filter,
            read: $.proxy(this._read, this),
            create: $.proxy(this._create, this),
            update: $.proxy(this._update, this),
            destroy: $.proxy(this._destroy, this)
        }
    },
    
    // methods with an "_" are private and are only to be used by the class
    _createSession: function (serviceURI, catalogURI) {
        this.session = new progress.data.Session();
        this.session.login(serviceURI, '', '');
        this.session.addCatalog(catalogURI);
    },
    
    // the transports needed by the DataSource
    _read: function (options) {
        var jsdo = this.jsdo;
        var tableName = this.transport.tableName;
        
        jsdo.subscribe('AfterFill', function callback(jsdo, success, request) {
            jsdo.unsubscribe('AfterFill', callback, jsdo);
            if (success) {
                var data;
                if (tableName) {
                    options.success(jsdo[tableName].getData());
                }
                else {
                    options.success(jsdo.getData());                    
                }                
            }
            else
                options.error(request.xhr, request.xhr.status, request.exception);
        }, jsdo);
        jsdo.fill(this.transport.filter);
    },
    
    _create: function (options) {
        var jsdo = this.jsdo;
        var jsrecord = jsdo.add(options.data);
        
        jsdo.subscribe('AfterSaveChanges', function callback(jsdo, success, request) {
            jsdo.unsubscribe('AfterSaveChanges', callback, jsdo);
            var data;
            if (success) {
                if (request.batch
                    && request.batch.operations instanceof Array
                    && request.batch.operations.length == 1) {
                    data = request.batch.operations[0].jsrecord.data;
                }
                options.success(data);
            }
            else {
                var xhr, status, exception;
                
                if (request.batch
                    && request.batch.operations instanceof Array
                    && request.batch.operations.length == 1) {
                        xhr = request.batch.operations[0].xhr;
                        status = request.batch.operations[0].xhr.status;
                        exception = request.batch.operations[0].exception;
                    }
                options.error(xhr, status, exception);                
            }
        }, jsdo);

        jsdo.saveChanges();
    },

    _update: function (options) {
        var jsdo = this.jsdo;
        var jsrecord = jsdo.findById(options.data._id);
        
        try {
            jsdo.assign(options.data);
        } catch (e) {
            options.error(null, null, e);
        }

        jsdo.subscribe('AfterSaveChanges', function callback(jsdo, success, request) {
            jsdo.unsubscribe('AfterSaveChanges', callback, jsdo);
            var data;
            if (success) {
                if (request.batch
                    && request.batch.operations instanceof Array
                    && request.batch.operations.length == 1) {
                    data = request.batch.operations[0].jsrecord.data;
                }
                options.success(data);
            }
            else {
                var xhr, status, exception;
                
                if (request.batch
                    && request.batch.operations instanceof Array
                    && request.batch.operations.length == 1) {
                        xhr = request.batch.operations[0].xhr;
                        status = request.batch.operations[0].xhr.status;
                        exception = request.batch.operations[0].exception;
                    }
                options.error(xhr, status, exception);                
            }
        }, jsdo);
        
        jsdo.saveChanges();
    },
    
    _destroy: function (options) {
        var jsdo = this.jsdo;
        var jsrecord = jsdo.findById(options.data._id);
        try {
            jsdo.remove();
        } catch (e) {
            options.error(null, null, e);
        }
        
        jsdo.subscribe('AfterSaveChanges', function callback(jsdo, success, request) {
            jsdo.unsubscribe('AfterSaveChanges', callback, jsdo);
            if (success)
                options.success([]);
            else {
                var xhr, status, exception;
                
                if (request.batch
                    && request.batch.operations instanceof Array
                    && request.batch.operations.length == 1) {
                        xhr = request.batch.operations[0].xhr;
                        status = request.batch.operations[0].xhr.status;
                        exception = request.batch.operations[0].exception;
                    }
                options.error(xhr, status, exception);                
            }
        }, jsdo);
    
        jsdo.saveChanges();
    }
});
// End class declaration