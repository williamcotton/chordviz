const appFactory = require("./server.js");
const dbName = "labels.db";
const app = appFactory({ dbName });
