
Since I recently had some time to work on side project, I worked on a p2p/cloud service based on BitTorrent sync : [plop-sync](http://plop.io).  I managed to build a neat REST Api useing nodejs, restify and mongoose.

Context
-----------------
The main purposes of the project were

 - Look deeper into nodejs/angularsjs
 - Look deeper into docker.io

### Angularsjs Ui / Nodejs REST Api
The Ui is build with 

 - Angularjs : simple page WebApp
 - Restangular : Easy connection with the backend
 - Bootstrap : Default layout and style

The REST API is build with

 - Nodejs : Javascript on the server
 - Restify : A nodejs module designed to build REST Api quite similare to Express without all html templating
 - Mongoose : nodejs module deigned designed to provide simple Mongodb Schema based modeling and validation and fluid quering syntax

### Btsync Backend
I obvisly used Bittorent Sync linux packages but each shared folder is runing in a separate docker.io container to provide isolation betwin each users folder. 

 
A neat REST Api
---------------
I find a lots of inspiration in [this awsome post](http://www.vinaysahni.com/best-practices-for-a-pragmatic-restful-api). After carfull thougth and reflexion I plan to build this Api :

```
/***************************
/*** User resource *********/

# create a new User
POST /users/:id
# Update user
PUT /users/:id
# Get user profile
GET /users/:id
# Login
GET /users/:id/login

/***************************
/*** Folders resource ******/

# Get folders list
GET /users/:id/folders
# Get folder details
GET /users/:id/folders/:folderId
# Create a new folder
POST /users/:id/folders
# Delete a folder
DEL /users/:id/folders/:folderId
# Update a folder
PUT /users/:id/folders/:folderId
```

Which ultimatly look like this in nodejs/restify

```javascript
// ** server.js *********************

// require restify npm module
var restify = require('restify');
// create a simple server
var server = restify.createServer({ 
    name: 'btsync-saas'
});

// Use Cross Origin Request Sharing middleware
server.use(restify.CORS({credentials: true}));
server.use(restify.fullResponse());
// Use Use HTTP Basic Authentication midleware
server.use(restify.authorizationParser());
// Use body parser middleware
server.use(restify.bodyParser());

// ***********************
// Users ressources

server.get( // Return user profile
    '/users/:id', access.authenticated(), access.idRequired(), access.userRestricted(),
    route.Users.info);

server.put( // Update user profile
    '/users/:id', access.authenticated(), access.idRequired(), access.userRestricted(), access.checkEmail(),
    route.Users.update);

server.post( // Create a new user
    '/users/:id/create', access.idRequired(), access.passwordRequired(),
    route.Users.create);

server.post( // Send credential and return auth token (login)
    '/users/:id/login', access.idRequired(), access.passwordRequired(),
    route.Users.login);


// ************************
// Folders ressources

server.get( // Return folders list
    '/users/:id/folders', access.authenticated(), access.idRequired(), access.userRestricted(),
    route.Folders.list);
server.get( // return folders details
    '/users/:id/folders/:folderId', access.authenticated(), access.idRequired(), access.folderIdRequired(), access.userRestricted(),
    route.Folders.get);
server.post( // create a new folder (with or without secret
    '/users/:id/folders', access.authenticated(), access.idRequired(), access.userRestricted(),
    route.Folders.create);
server.del( // delete a shared folder
    '/users/:id/folders/:folderId', access.authenticated(), access.idRequired(), access.folderIdRequired(), access.userRestricted(),
    route.Folders.delete);
server.put( // update existing shared folder
    '/users/:id/folders/:folderId', access.authenticated(), access.idRequired(), access.folderIdRequired(), access.userRestricted(),
    route.Folders.update);
    
    
// start server
server.listen(8080, function () {
    console.log('%s listening at %s', server.name, server.url);
});
```

Basic routes look like this
```javascript
// ** routes.js excerpt *******************

exports.login = function login(req, res, next) {
        // make a db request using predefined Mongoose Schema.
        // id and password have already been check and validate by the access middleware
        schema.User.login(req.params.id, req.params.password, function (err, user) {
            // in case of db errors just rend a Restify InternalError to the restify router
            if (err) return next(new restify.InternalError());
            // if their is no user 'throw' a restify Error 
            if (!user) return next(new restify.InvalidCredentialsError());

            // If evrything looks good juste send back filtered results
            res.send({
                id: user.id,
                token: user.token
            });
        });
    }
```

As you can see most routes are mostly error management and result filtering (we don't want our password hash roaming on the web)

One of the most complexe routes look like this.
```javascript
// ** routes.js excerpt *******************

exports.list = function getSharedFoldersList(req, res, next) {
        // db reuest for all user folders
        req.user.findFolders(function (err, folders) {
            
            // throw restify.InternalError() on db error
            if (err) return next(new restify.InternalError());

            // filter and enhance each db result
            async.map(
                folders, // we're working on folders
                function iterator(item, cb) {
                    
                    // for each folder we make two more db request 
                    async.parallel({
                        // find folder size in logs
                        size: function (sizeCallback) {
                            logSchema.DiskLog.findSize(item.containerId.trim(), false, sizeCallback);
                        },
                        // find folders iostat in logs
                        dstat: function (dstatCallback) {
                            logSchema.DstatLog.findDstat(item.containerId.trim(), dstatCallback);
                        }
                    }, function parallelCallback(err, results) { // enhance and filter single folder result

                        // as always, throw Restify InternalError in case of db errors
                        if (err) return next(
                            new restify.InternalError());

                        // return filter and enhanced folder object
                        cb(undefined, {
                            id: item._id,
                            name: item.name,
                            description: item.description,
                            created: item.created,
                            size: (results.size ? results.size.size : undefined),
                            dstat: (results.dstat ? results.dstat.dstat : undefined)
                        });

                    });
                },
                // async.parallel callback
                function callback(err, results) {
                    // in case of errors throw Restify InternalError
                    if (err) return next(new restify.InternalError());

                    // send filtered results
                    res.send(results);
                }
            );
        });
    }
```
As you can see, it's still mostly error management and result filtering.
All authentication and input filtering/validation burden has been take care by generic middleware
```javascript
// ** server.js excerpt **********

server.get( // Return folders list
    // route URL
    '/users/:id/folders',       
    // User need to be authenticated (throw NotAuthorizedError)
    access.authenticated(),     
    // userid is required and validate (throw MissingParameterError)
    access.idRequired(),      
    // Users can only acces their own ressources (throw NotAuthorizedError)
    access.userRestricted(),  
    // route handler
    route.Folders.list);
```

### Conclusion
