const appFactory = require("./server.js");
const dbName = "labels.db";
const port = 3000;
const app = appFactory({ dbName, port });