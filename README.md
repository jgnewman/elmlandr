# Elmlandr

Elmlandr is a robust bootstrapping environment for Elm apps running on Node servers with Postgres databases powered by Yarn.

Jump to...

- [Features](#features)
- [Getting set up](#getting-set-up)
- [Environment files](#environment-files)
- [Using a database](#using-a-database)
- [Exposing a dev app to the internet](#exposing-a-dev-app-to-the-internet)
- [Enabling CORS](#enabling-cors)
- [Configuring server routes](#configuring-server-routes)
- [Configuring server middleware](#configuring-server-middleware)
- [Scheduling jobs](#scheduling-jobs)
- [Using the http API](#using-the-http-api)
- [Using the websocket API](#using-the-websocket-api)
- [Using authentication](#using-authentication)
- [Understanding the front end](#understanding-the-front-end)
- [About auto refreshing](#about-auto-refreshing)
- [All the yarn commands](#all-the-yarn-commands)

## Features

On the front end:

- Elm
- A simple Elm architecture scaffold using `Html.programWithFlags` and files helping you to separate concerns.
- A clean, ready-made scss architecture dividing styles up in a way that follows your application structure
- Bootstrapped localStorage model persistence
- Axios for utilizing a built-in REST API
- Websockets for utilizing a built-in Websocket API
- Placeholders for fonts, images, and a favicon

On the back end:

- ES201x
- Gulp + Express
- A configurable nature
- Env variables for both prod vs dev environments
- A job scheduler
- Minified CSS and Elm for prod environment
- Automatic browser refreshing for dev environment
- Automatic server refresh + browser refresh when server files change
- Optionally enable/disable ngrok for development
- Optionally enable/disable CORS
- Optionally enable/disable use of a database
- A bootstrapped database schema with Users and Sessions
- A bootstrapped database setup and seeding script + Yarn command
- A bootstrapped http API
- A bootstrapped Websocket API
- Built-in authentication using JSON web tokens
- Authentication shared between http and Websocket APIs
- Ability to easily add express middleware and routes

## Getting set up

1. Make a copy of this repo using the method of your choice.
2. Make sure you have Yarn installed globally then install deps by running `$ yarn`.
3. Prepare a basic environment so Yarn commands will work. See [Environment files](#environment-files).
4. Open up config.js and choose a server port. The default is 8080. If you want to be up and running quickly, temporarily forego your database by setting `dbEnabled` to false.
5. Run `$ yarn dev`.

The app is now running on a local server!

To learn about all the cool things you can do with Elmlandr, keep reading.

## Environment files

Elmlandr is configurable for both development and production environments. To make this work, you will need to create two new files at the top level. These files are not included in the repo for security purposes as you will eventually need to add various secret keys to them.

The files should be called `env-dev` and `env-prod` respectively. No file extension is necessary. At the very least you should add the following content to these files:

**env-dev**

```bash
export NODE_ENV=development
export PORT=8080
export DATABASE_DEV_NAME=elmlandr
export DATABASE_DEV_PASSWORD=password
export DATABASE_SECRET="I've got a secret, I'm not gonna tell you"
```

**env-prod**

```bash
export NODE_ENV=production
# Some production environments automatically choose a port
# export PORT=5000
export DATABASE_SECRET="Pirates always fight with cutlasses"
```

Everything you do with Elmlandr is run through Yarn commands. These commands will source the environment files as appropriate, making them available to every file on the server. That said, the expected workflow is that the config file should adjust itself based on these variables, then the rest of the server uses the config file. As you add new layers to your application that require environment variables, you will want to store those in these files and then create corresponding config values.

Note that these are just example values. You should change them as needed.

## Using a database

### Creation

Elmlandr is optimized for Postgres. You can switch this out for something else if you'd like but I wouldn't recommend it unless you are intimately familiar with all of the Elmlandr source code. A lot of things are bootstrapped for you and they assume a Postgres database.

To set up a local database, make sure you have Postgres installed and some method of looking inside your database to make sure everything is working. If you're a visual person and are using a Mac, I highly recommend [Postico](https://eggerapps.at/postico/). Otherwise, [pgAdmin](https://www.pgadmin.org) is a great alternative.

Elmlandr can't actually create a database for you so you'll need to do this yourself. Creating databases is extremely easy with either of the previously mentioned tools.

### Configuration

Once you've created a database and named it, you'll need to plug that name into your env-dev file for the `DATABASE_DEV_NAME` key. Also make sure you choose a `DATABASE_PASSWORD` and/or `DATABASE_SECRET` as necessary.

Open up config.js, find the `backend` object, and make sure you set `dbEnabled` to true. Notice how other database values are pulled in from the environment. You'll want to follow this pattern when adding new configuration options.

The `DATABASE_URL` key is only necessary for production databases such as on Heroku. When you're ready to use it, it will often take a form like:

```
postgres://axjxocwjzztraf:6f8b8351f2f87b26e50fa06210d7cbf1474567891dbdde5abb64440c7aa9c608@ec2-48-21-220-167.compute-1.amazonaws.com:5432/d2v3v3huf99oin
```

### Seeding

In order to create a database schema, Elmlandr uses [Sequelize](http://docs.sequelizejs.com/en/v3/) with a [Reduquelize](https://www.npmjs.com/package/reduquelize) layer to simplify things.

If you open backend/db-models.js you will see that the first two ORM models have been created for you, namely Users and Sessions. These two models are necessary for Elmlandr's built-in authentication to work properly so I'd recommend against deleting them, although you can feel free to modify the Users model to your heart's content as long as you leave email and password-related fields intact.

Define all the additional models you'd like in the area labeled "Define your models here". This will allow Sequelize to set up all of the necessary tables and relations for you.

Next, open up backend/db-seed.js and look for the area labeled "Create your data here". Just above this line you will see two examples of users that will be seeded into the database whenever you run your seed script. Feel free to copy/paste this pattern in order to easily add new seed data:

```javascript
// Create a new User with values like these
await create(Users, {
  firstName: 'John',
  lastName: 'Doe',
  email: 'fake@fake.com',
  password: 'asdf;laksjdf'
}, 'Created user John Doe') // Useful console output on creation success
```

The seed command is `yarn dev:seed` for development environments or `yarn prod:seed` for production environments. Remember that the only difference between these two commands is which set of envionment variables it uses and how it connects to your database.

**The seed script will drop all tables** if they already exist and then create everything from scratch. So only use it when that's what you want.

### Defining an API

In order to make using the http API and websocket API easy, you'll want to simplify how these layers access your database. Sequelize can often be verbose so Elmlandr includes a Reduquelize layer.

Reduquelize generates a simplified model for each of your tables, containing methods like `get`, `getOne`, `getMany`, `create`, `saveCreate`, `update`, `updateMany`, `destroy`, `destroyMany`, and `count`. You can also call the `augment` function to add new, more robust methods to these models.

To do that, open up the file backend/db-interface.js and locate the area labeled "Augment your models here". Follow the pattern you see below that area to see how the Users and Sessions models have been augmented to facilitate authentication.

Here is an example for how you might augment a Users model to find all adult users:

```javascript
Users.augment({

  getAdults: async() => {
    const users = await Users.getMany({ age: { $gte: 18 } })
    return users;
  }

})
```

You will have these models available to you when defining both your http API and your websocket API.

## Exposing a dev app to the internet

Elmlandr allows you to _easily_ expose a development app to the internet if that ability is necessary for testing. To do this, it uses [ngrok](https://ngrok.com/).

Open up config.js and set `ngrokEnabled` to true. That's it. When you run the app via `$ yarn dev`, you'll see a temporary URL logged to the console through which external connections should be able to access your application.

Note that if your _computer_ is not currently allowing outside connections, you'll have to turn that off in order for ngrok to work.

## Enabling CORS

Elmlandr makes cross origin resource sharing a breeze as well. Simply open up config.js and set `enableCORS` to true. Feel free to base this on an environment variable if you'd like. This will enable CORS for all http requests.

## Configuring server routes

Elmlandr uses [Express](https://expressjs.com/) for the http server. The first route that serves up your Elm app has already been configured for you. To add more, open the file backend/server-routes.js.

Within this file, locate the area labeled "Attach your routes here". You'll want to define all of your additional routes in this area following the pattern shown above.

Note that static assets are already configured for you in the file server-middlewares.js. A good rule of thumb for determining whether something should go into server-middlewares or server-routes is whether it's a call to `app.get` or `app.use`. If it's `app.use`, put it in middlewares.

## Configuring server middleware

As stated above, Elmlandr uses [Express](https://expressjs.com/) for the http server. If you'd like to add middleware to http requests on your server app, you can do that in backend/server-middlewares.js.

Within this file, you'll see that lots of cool middleware is already being applied (including request body parsing, authentication checks, and CORS stuff). To add more, find the area labeled "Attach your custom middleware here" and add in all the calls to `app.use` that you want.

## Scheduling jobs

Elmlandr comes packaged with a built-in scheduler using [node-schedule](https://www.npmjs.com/package/node-schedule). To create a scheduled job, simply add a new file to the "backend/schedules" directory. When the server starts up, each file in this directory will be launched in a child_process so that when jobs run, they won't block events on the main thread.

In order to use node-schedule you may want to be familiar with the cron format. However, there are plenty of more semantic ways to schedule jobs though none are quite as concise.

Here is an example of a scheduled job that will run once every minute. Feel free to try it out.

```javascript
// Start by creating example.js and putting it
// in the backend/schedules directory. Here are the
// contents of that file...

import schedule from 'node-schedule';
import dbReady from '../backend/db-init';

// Establish a database connection
dbReady(({ Users }) => {

  // Schedule a job to run every minute
  schedule.scheduleJob('0 * * * * *', async() => {

    // Read the first user from the database and log it
    const user = await Users.get(1);
    console.log(user.raw());
  });
});
```

Note that the above script will only be able to log out data if you have already run the database seed script or you have put users into your database in some other way.

## Using the http API

Elmlandr starts you off with a minimally bootstrapped http API. If your app does not use a database, this will be both useless and unavailable to you.

To define your API, open the file backend/http-api-v1.js and locate the area labeled "Add more API routes here". Because Elmlandr uses [Express](https://expressjs.com/) for the http server, API routes will be added with calls to `app.get, app.post, etc`.

Notice that 3 routes have already been created for you: one for logging in, one for logging out (more on authentication later), and one for getting a user record. Follow the pattern seen in these functions to create routes of your own:

```javascript
// When a request attempts to get a user by id...
app.get('/api/v1/users/:id', async(req, res) => {

  // Find the user in the database
  const user = await Users.get(req.params.id);

  // Handle the case where we don't find the user
  if (user.isNull()) return res.sendStatus(404);

  // Be sure not to include sensitive data then
  // send back the user info.
  delete user.password;
  res.send(user.raw());

});
```

On the client side, Elmlandr comes packaged with [Axios](https://www.npmjs.com/package/axios), a promise-based library for quickly making ajax requests. For example:

```javascript
import axios from 'axios';

axios.get('/api/v1/users/1')
     .then(user => { console.log(user) })
     .catch(err => { console.log(err) });
```

## Using the websocket API

Elmlandr uses [Brightsocket.io](https://www.npmjs.com/package/brightsocket.io), a lesser-known but rather cool library that sits on top of Socket.io for managing websocket APIs.

If you open up backend/socket-api-v1.js, you'll find 2 areas prepared for you to start writing code. The first is labeled "Add additional action handlers here" and the second is labeled "Add additional websocket channels here".

The first area is where you can describe API events for authenticated users (more on authentication later). The second area is where you can start doing more advanced things with Brightsocket.io once you get how it works.

Within the first area, an example of how you might write an API call using websockets has been written for you. Here's a simplified version of what's going on there:

```javascript
// When an authenticated user sends the GET_USER action,
// we'll expect the payload to have a userId property.
connection.receive('GET_USER', async(payload) => {

  const user = await Users.get(payload.userId);

  if (user.isNull()) return connection.send('NOT_FOUND');

  delete user.password;
  return connection.send('USER_RECORD', user);
});
```


## Using authentication

Elmlandr comes with a built-in method for authentication using json web tokens. Here's how it works and how you'll use it:

### Database schema

In backend/db-models.js, a user model and a session model have already been created with Sequelize. Users are expected to have an email address and password to match against for authentication.

> Note that raw passwords are not saved in the database. Passwords are encrypted via PBKDF2 with HMAC-SHA-512 as a core hashing algorithm and using a randomly generated 16 byte salt at 100,000 iterations. Passwords are automatically limited to 1000 characters to avoid large password DDOS attacks.

When a user is authenticated, a session will be created in the sessions table.

By running the seed script (`$ yarn dev:seed`), you will have 2 users created in the database that you can experiment with.

### Http api

In backend/http-api-v1.js, two routes have been created for authentication, specifically `POST /api/v1/authentication/` and `POST /api/v1/authentication/logout`.

An example login would look like the following:

```javascript
import axios from 'axios';

// Post credentials to the api
axios.post('/api/v1/authentication', {
  email: 'fake@fake.com',
  password: 'asdf;laksjdf'
})

// If it worked, we'll get back a session token and a
// user record. Note that password fields are removed
// from this record.
.then(result => { console.log(result.token, result.user) })

// If not, we'll log the error.
.catch(err => { console.log(err) });
```

And an example logout would look like the following:

```javascript
import axios from 'axios';

// Post the token to the logout endpoint.
axios.post('/api/v1/authentication/logout', { token: sessionId })

// Log if it worked.
.then(() => { console.log('logged out') })

// Log if it didn't (this would be a server error)
.catch(err => { console.log(err) });
```

Once logged in, you'll need to pass in correct, standard ajax headers for any API route that requires authentication. For example:

```javascript
const token = // The token you got from logging in

axios.post('/api/v1/some-protected-route', dataToSend, {
  headers: { Authorization: `Basic ${token}` }
});
```

If you try to access a route that requires you to be authenticated and the `Authorization` header is not properly formed, you will get back a `401`.

### Protecting http routes

In backend/server-middlewares.js, you will notice this call: `app.use(checkAuth())`. This causes a function to run that checks authorization on every request. However, it will only _enforce_ authorization on routes you specify.

To that end, in backend/http-api-v1.js, you'll notice this call:

```javascript
app.use(applyAuth({
  requireFor: ['/api/v1/*'],
  bypassFor: [
    '/api/v1/authentication',
    '/api/v1/authentication/*'
  ]
}));
```

The `applyAuth` function is where you will specify which routes you would like to protect by enforcing authorization. By default, authorization is not enforced on any routes so, in the `requireFor` key, we've specified that authorization should be required for all routes beginning with `/api/v1/`. This lets us quickly protect the entire API. However, there are a few routes within that glob we'd like to let through. In particular, we can't enforce authorization on authentication end points because they are designed to be accessed by unauthenticated users. To fix this, we've added those routes to the `bypassFor` key. Anything listed here will be allowed through without requiring authentication.

### How authorization is checked

Whether it's via http or websockets (more on that in a minute), users will have to pass in the token they received when logging in to prove they are allowed to access protected routes.

In config.js you are allowed to specify how long a token is good for using the `sessionExpiry` key. By default, this key is set to 12, meaning 12 hours from the last time it was updated. A session is updated every time it successfully validates so, in effect, this would be 12 hours since a token was last used. You can adjust this at your leisure.

When a user is authenticated, a session is created in the database. Whenever a request comes in that needs to be authenticated, the token is used to retrieve the session from the database and validate it. If the session gets invalidated, the session is automatically removed from the database.

Simultaneously, while the app is running, there is a background process running a schedule that will clean expired sessions out of the database every 12 hours. See [scheduling jobs](#scheduling-jobs). You can adjust the schedule for this particular job in the config under the `sessionCleanFrequency` key.

For most apps this is good enough. But Elmlandr goes one step farther toward keeping your Sessions table clean. Imagine a scenario where the expiration job runs every day at noon and midnight. Now imagine that a user creates a new session at 12:01pm. When midnight rolls around, the session won't be deleted because it has a minute left before it can be considered invalid. Assuming the user doesn't attempt to use that token again until the following afternoon, that dead session record will be taking up space in the database for almost another 12 hours until the job runs again at noon.

To combat this pileup of useless records (especially if you want to reduce the frequency of the expiration job), you can set a value for `sessionSuppression` in the config. The default value is 2. What it means is that, for every new session created, Elmlandr will attempt to delete up to 2 expired session records from the database. If the value is set to 0, it won't try to do any session suppression. With session suppression, you can keep your old, dead session records to a minimum while still maintaining quick server responses.

### Websocket API

Because Elmlandr uses [Brightsocket.io](https://www.npmjs.com/package/brightsocket.io) for websocket handling (and due to the nature of websockets generally), authentication is a little looser.

In backend/socket-api-v1.js, two brightsocket channels have been created for you. A brightsocket channel is essentially a partition of your websocket API. Before an incoming connection can do anything, it has to identify a channel it wants to use. Once it does, it will only have access to the events described within that channel until it reconnects and chooses a different channel.

Here, the two channels we've created are called `AUTHENTICATION` and `AUTHENTICATED`.

The `AUTHENTICATION` channel uses the database API to try to authenticate users then sends back the result. An incoming connection to this channel should include an `email` and `password` key in its payload. If the credentials can be authenticated, the server will send an event called "AUTHENTICATED" back through the connection with the following data attached:

```
{
  reconnect: 'AUTHENTICATED', // The channel the user should reconnect to
  user: { ... }, // The user record of the authenticated user
  sessionId: 'qoiwuerakfjdh...' // The auth token
}
```

In any other case, the server will send back "UNAUTHORIZED" or "SERVER_ERROR" depending on what went wrong.

Once authenticated, it's time for the connection to reconnect to the `AUTHENTICATED` channel. You'll notice that this channel has a call to `addFilter` in it, which is essentially middleware for Brightsocket.io. Any connection that can pass the test imposed by the filter will be allowed access to the rest of the API defined within this channel. Otherwise, it will be sent "UNAUTHORIZED".

Specifically, this channel demands that every time data comes in through a connection (including when the actual connection occurs) that the payload should include a `sessionId` key containing a valid session token. If it does, it will be able to access the websocket events you have set up within this channel.

On the client side, you can authenticate using a method like this:

```javascript
import brightsocket from 'brightsocket.io-client';

const socket = brightsocket();
const credentials = {
  email: 'fake@fake.com',
  password: 'asdf;laksjdf'
};

let sessionId;

function defineApi() {

  socket.send('GET_USER', {
    sessionId: sessionId,
    userId: 1
  });

  socket.receive('USER_RECORD' payload => {
    console.log('Received user record', payload);
  });
}

socket.connect('AUTHENTICATION', credentials, () => {
  socket.receive('AUTHENTICATED', payload => {
    sessionId = payload.sessionId;
    socket.connect(payload.reconnect, { sessionId: sessionId }, defineApi);
  });
})
```

## Understanding the front end

Then entire front end of the application lives in the "frontend" directory. As you might expect, there are files in here you'll want to modify and also files you'll want to leave alone because they are generated by the build process.

### Which files should be left alone

You'll want to ignore the entire frontend/css directory. It is exclusively used by the build process and will get wiped clean with every build. To define your styles, you will use scss in the frontend/src/scss directory.

You'll also want to ignore frontend/index.html. This file is modified by the build process in that it changes depending upon whether you're in a development or production environment. If you want to modify this file, you'll need to edit frontend/src/templates/index.html instead.

Fonts and images are just static files and Elmlandr doesn't do anything with them. As such, feel free to put your fonts and images directly into frontend/fonts and frontend/img. You can also modify frontend/favicon.ico at will. Elmlandr won't mess with it.

Most of the files you'll be dealing with on a regular basis live in frontend/src/elm and frontend/src/scss.

### Scss structure

All of the project's source styles live in frontend/src/scss. Within this directory there is a subdirectory called "global" as well as 2 scss files:

- global - Contains all of your scss utility files: normalize, variables, fonts, mixins, classes, and universal styles.
- index.scss - imports all other scss files in the correct order
- \_application.scss - A starting point for styling your application.

### Elm structure

Your Elm app is initialized within a script tag that lives on frontend/src/templates/index.html. The rest of the app lives in frontend/src/elm. Within this directory there are a few files. Let's explore what's going on inside each of these pieces.

#### index.html

Near the close of the body tag in this file you will notice the following JavaScript code:

```javascript
window.addEventListener('load', function () {
  var saved = localStorage.getItem('elmlandr-app');
  var parsed = saved ? JSON.parse(saved) : null;

  var app = Elm.Main.fullscreen(parsed);

  app.ports.setStorage.subscribe(function (model) {
    localStorage.setItem('elmlandr-app', JSON.stringify(model));
  });
});
```

This script waits for other scripts to be loaded then spins up your Elm app. It begins by looking for a saved application model, then parses it, and passes it to the `fullscreen` function exposed by your Main module. If a saved model can be found, it will be used to perform an initial hydration of the model within the app on startup.

Next, the script subscribes to a port that has been created for you called `setStorage`. Any time the model is updated, it will be passed to this subscriber, stringified, and placed into local storage to be retrieved on the next startup.

#### Main.elm

This file defines the `main` function for your elm app and creates an instance of `Html.programWithFlags`. The ability to save your model in local storage is already set up for you so this file also defines the app's `init` function, taking in a possible model and returning a `(Model, Cmd Msg)` tuple. The app's `view`, `update`, and `subscriptions`, functions are defined within Views.elm, Updates.elm, and Subscriptions.elm, respectively.

#### Models.elm

This file exposes the type alias of your app's model as well as a `defaultModel` function that will be used in the event that a null flag comes in on startup.

#### Msgs.elm

This file defines all the possible messages that will need to be handled by your `update` function. Two have been defined for you, namely `NoOp` and `ChangeTitle String`. If you look at Updates.elm you will see that `NoOp` simply returns the model as-is whereas `ChangeTitle` is used to change a single property on the model.

#### Ports.elm

This file is a port module exposing a single port (`setStorage`) that has been created for you. This port is referenced within Updates.elm and is used to pass the model out to JavaScript on every model update with the intent that it should be persisted in local storage.

#### Subscriptions.elm

For the purposes of bootstrapping a basic app, no meaningful subscriptions have been created. This file exposes a single `subscriptions` function that simply returns `Sub.none` in order to match the type signature required for `Html.programWithFlags`.

#### Updates.elm

This file contains your app's core `update` function where you will handle all the possible message cases that can be used to update the model. What is more interesting about this file is that it establishes a system for attaching "middleware" to model updates. You will notice that the function used within `main` is the `updateWithMiddleware` function exposed by this module.

The `updateWithMiddleware` function calls `update` and then forward pipes the result to a chain of functions with type signature `(Model, Cmd Msg) -> (Model, Cmd Msg)`. The first example, `persistModel` has been defined for you and uses the `setStorage` port to persist the model in local storage after every update.

#### Views.elm

This file contains a starting point for building your virtual DOM. Currently it displays a title using text contained in the model and creates an input field allowing you to alter the title text.


## About auto refreshing

One thing to keep in mind is that Elmlandr sets up file watchers all over the place. Any time a source file changes within the frontend directory, the front end will re-build itself automatically.

There are also watchers set up to track changes to backend files. Changing one of those will trigger a full server refresh so that you don't manually have to restart things.

If you launch the app in dev mode, Elmlandr will inject some auto-refresh code into frontend/src/templates/index.html. This way, any time the app rebuilds or the server refreshes, your browser will automatically refresh as well.

## All the yarn commands

Everything you do when working with Elmlandr will be executed via Yarn commands. Here is a list of what's available:

- `$ yarn start` - Launch the app using environment variables not specified through `env-dev` or `env-prod` files. For example, on heroku.
- `$ yarn dev` - Launch the app using development variables
- `$ yarn prod` - Launch the app using production variables
- `$ yarn seed` - Clean and seed the database using environment variables not specified through `env-dev` or `env-prod` files
- `$ yarn dev:seed` - Clean and seed the development database
- `$ yarn prod:seed` - Clean and seed the production database
- `$ yarn dev:test` - Launches Elmlandr's unit tests using the development environment
- `$ yarn prod:test` - Launches Elmlandr's unit tests using the production environment
