const appFactory = require("./server.js");
const dbName = "labels.db";
const port = 3023;
const { app, close } = appFactory({ dbName, port });
