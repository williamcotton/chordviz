/* 
an express app with a single POST endpoint for a filename, a chord string, a tablature array of integers, an inTransition boolean, and a capoPosition integer
it writes to a sqlite database with a table named "labels" with the following columns: filename, chord, tablature, inTransition, capoPosition
*/

const express = require("express");
const app = express();
const bodyParser = require("body-parser");
const sqlite3 = require("sqlite3").verbose();

const appFactory = ({ dbName }) => {
  const db = new sqlite3.Database(dbName);

  app.use(bodyParser.json());

  app.post("/", async function (req, res) {
    const filename = req.body.filename;
    const chord = req.body.chord;
    const tablature = req.body.tablature;
    const inTransition = req.body.inTransition;
    const capoPosition = req.body.capoPosition;

    await db.serialize(async function () {
      await db.run(
        "CREATE TABLE IF NOT EXISTS labels (filename TEXT, chord TEXT, tablature TEXT, inTransition BOOLEAN, capoPosition INTEGER)"
      );
      await db.run("INSERT OR REPLACE INTO labels VALUES (?, ?, ?, ?, ?)", [
        filename,
        chord,
        tablature,
        inTransition,
        capoPosition,
      ]);
    });

    res.send("ok");
  });

  const server = app.listen(3000, function () {
    console.log("Labels server listening on port 3000");
  });

  async function close() {
    await server.close();
    await db.close();
  }

  return { app, close };
};

module.exports = appFactory;
