I recently had some time to learn a bit more about nodejs, angularjs, docker ...
I end up building a single page web app named [Plop Sync](https://plop.io/sync)
wired to a REST Api.

While building the server api, I learn a lot about building RESTfull api with
nodejs, restify and mongoose.

With those series of article, I'll try to sum up all the good practices I learned when it comes to building a
neat REST api from scratch, with nodejs.


A simple messages REST Api
--------------

For those articles let's build a simple REST Api which allow to publish and list messages (kind a very basic twiter clone). Let's keep it simple.

First, we need to bootstrap the project :

```bash
mkdir rest-api
cd rest-api

# initialize a package.json files
npm init

# install restify mongoose async packages and update package.json
npm install --save restify mongoose async

# create a basic directories structure
mkdir -p app/models app/routes/messages
```

### Server entrypoint `app/server.js`

 * Bootstrap everything : Create restify server and connects database.
 * Routes REST urls to controllers.

```javascript
// *******************
// ** app/server.js **
var restify =  require('restify');
var mongoose = require('mongoose');

// ************************
// **  Bootstraping *******

// connect to mongodb database rest-api on localhost
mongoose.connect('mongodb://localhost/rest-api')


// create restify server named 'rest-api'
var server = restify.createServer({
    name: 'rest-api',
});

// Use body parser middleware to parse json post body
server.use(restify.bodyParser());


// ************************
// **  Routing ************

// RESTfull url should be separated in logical resources (noun) accessed via
// HTTP methods

/* GET /messages
 * List all messages */
server.get('/messages',      require('./routes/messages/list'));

/* GET /messages/:id
 * Get messages details by id */
server.get('/messages/:id',  require('./routes/messages/details'));

/* PUT /messages/:id
 * Update messages by id */
server.put('/messages/:id',  require('./routes/messages/update'));

/* DEL /messages/:id
 * Delete messages by id */
server.del('/messages/:id',  require('./routes/messages/delete'));

/* POST /messages
 * Create new messages */
server.post('/messages',     require('./routes/messages/create'));


// ******************
// ** Starting ******

// start listening on port 1337
server.listen(1337);
```

### Messages model

Data models are simple mongoose Schemas which provides

 * Model definition
 * Validation
 * Basic database CRUD actions
 * Model and instance custom actions

For now, let's create a Message Model with a simple content

```javascript
// loading mongoose module
var mongoose = require('mongoose');
var Schema = mongoose.Schema;


// Message schema
var messageSchema = new Schema({
	content:       { type: String, require: true}
});

// Create Message model
var Message = mongoose.model('Message', messageSchema);

// exports Message model
module.exports = Message;
```

### Routes controllers

Lastly we need controllers for each routes.

Remember `server.get('/messages', require('./routes/messages/list'))` from
`app/server.js` ? It wire url `/messages` to the controller located
`routes/messages/list.js`.


#### Controller `app/routes/messages/list.js` for `GET /messages`
```javascript
var restify = require('restify');
var Messages = require('../../models/Messages');

// exports controller
module.exports = function(req, res, next) {

	// find all messages
    Messages.find({}, function(err, messages) {
        if (err) {
            // loging errors
            console.error('InternalError :', err);
            // returning generic InternalError to clients on errors
            return next(new restify.InternalError());
        }

		// send all messages
        res.send(messages);
    });
}
```
#### Controller `app/routes/messages/details.js` for `GET /messages/:id`
```javascript
var restify = require('restify');
var Messages = require('../../models/Messages');

module.exports = function(req, res, next) {

    Messages.findById(req.params.id, function(err, message) {
        if (err) {
            // loging errors
            console.error('InternalError :', err);
            // returning generic InternalError to clients
            return next(new restify.InternalError());
        }

        // returning ResourceNotFoundError (error 404)
        if (!message) { return next(new restify.ResourceNotFoundError()); }

        // returning message on success
        res.send(message);
    });
}
```

#### Controller `app/routes/messages/update.js` for `PUT /messages/:id`
```javascript
var restify = require('restify');
var Messages = require('../../models/Messages');

module.exports = function(req, res, next) {

    if (!req.params.content) {
        return next(new restify.MissingParameterError('Missing :content param'))
    }

    Messages.findByIdAndUpdate(req.params.id,
        {
            content: req.params.content, // update content
            lastUpdatedOn: Date.now()       // change lastUpdate date
        },
        function(err, message) {
            if (err) {
                // loging errors
                console.error('InternalError :', err);
                // returning generic InternalError to clients
                return next(new restify.InternalError());
            }

            // returning ResourceNotFoundError (error 404)
            if (!message) { return next(new restify.ResourceNotFoundError()); }

            // returning updated message on success
            res.send(message);
        }
    );
}
```
#### Controller `app/routes/messages/delete.js` for `DEL /messages/:id`
```javascript
var restify = require('restify');
var Messages = require('../../models/Messages');

module.exports = function(req, res, next) {

    Messages.findByIdAndRemove(req.params.id, function(err, message) {
        if (err) {
            // loging errors
            console.error('InternalError :', err);
            // returning generic InternalError to clients
            return next(new restify.InternalError());
        }

        // returning ResourceNotFoundError (error 404)
        if (!message) { return next(new restify.ResourceNotFoundError()); }

        // returning deleted message on success
        res.send(message);
    });
}
```

#### Controller `app/routes/messages/create.js` for `POST /messages`
```javascript
var restify = require('restify');
var Messages = require('../../models/Messages');

module.exports = function(req, res, next) {

    if (!req.params.content) {
        return next(new restify.MissingParameterError('Missing :content'));
    }

    var message = new Messages({
        content: req.params.content
    });

    message.save(function(err, message) {
        if (err) {
            // loging errors
            console.error('InternalError :', err);
            // returning generic InternalError to clients
            return next(new restify.InternalError());
        }

        // returning newly created message on success
        res.send(message);
    })
}
```

Rest-api v0.0.0 is finiched, let's test it (badly)
-------------------

We should be testing a real project with `mocha` for exemple.
But we will just run some `curl` commands to keep things simple for the moment.

```bash
# start server
node app/server.js


# list all messages
curl http://localhost:1337/messages
=> []

# post a message
curl http://localhost:1337/messages \
	-H 'Content-Type:application/json' \
	-d '{"content":"first message"}'
=> {
        "__v": 0,
        "content": "first message",
        "_id": "52936b3d972b40d352000001"
    }

# post a second message
curl http://localhost:1337/messages \
    -H 'Content-Type:application/json' \
    -d '{"content":"2nd message"}'
=> {
        "__v": 0,
        "content": "2nd message",
        "_id": "52936bc4972b40d352000002"
    }


# list all messages again
curl http://localhost:1337/messages
=> [
        {
            "content": "first message",
            "_id": "52936b3d972b40d352000001",
            "__v": 0
        },
        {
            "content": "2nd message",
            "_id": "52936bc4972b40d352000002",
            "__v": 0
        }
    ]

# gets a message details (use _id returned in YOUR terminal or it won't work)
curl http://localhost:1337/messages/52936b3d972b40d352000001
=> {
        "content": "first message",
        "_id": "52936b3d972b40d352000001",
        "__v": 0
    }

# update a message
curl --request PUT http://localhost:1337/messages/52936b3d972b40d352000001 \
    -H 'Content-Type:application/json' \
    -d '{"content":"New content for our first message"}'
=>  {
        "content": "New content for our first message",
        "_id": "52936b3d972b40d352000001",
        "__v": 0
    }

# and let's delete a message
curl --request DELETE http://localhost:1337/messages/52936b3d972b40d352000001
=>  {
        "content": "New content for our first message",
        "_id": "52936b3d972b40d352000001",
        "__v": 0
    }

# delete again (should return 404 error since the resouce don't exist any more)
curl --request DELETE http://localhost:1337/messages/52936b3d972b40d352000001
=> 404 {"code":"ResourceNotFound","message":""}
```


Next steps
------------------

Many things are still missing :

 * User management
 * Validation
 * Authentification
 * Real tests

I'll cover those in later posts :-)

Thanks for reading.