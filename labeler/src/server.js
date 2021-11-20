/* 
an express app with a single POST endpoint for a filename, a chord string, a tablature array of integers, an inTransition boolean, and a capoPosition integer
it writes to a sqlite database with a table named "labels" with the following columns: filename, chord, tablature, inTransition, capoPosition
*/

const express = require("express");
const app = express();
const bodyParser = require("body-parser");
const sqlite3 = require("sqlite3").verbose();
const React = require("react");
const path = require("path");
const ReactDOMServer = require("react-dom/server");

require("node-jsx").install();

const App = require("./app.jsx");

const template = (app) => `
<html>
  <head>
    <title>Chordviz Labeler</title>
  </head>
  <body>
    <div id="app">${app}</div>
    <script src="app.js"></script>
  </body>
</html>
`;

const appFactory = ({ dbName, port }) => {
  const db = new sqlite3.Database(dbName);

  app.use(express.static(path.join(__dirname, "../public")));

  app.use(bodyParser.json());

  app.get("/", function (req, res) {
    const html = ReactDOMServer.renderToString(React.createElement(App, null));
    res.send(template(html));
  });

  app.post("/label", async function (req, res) {
    const { filename, chord, tablature, inTransition, capoPosition } = req.body;

    await db.serialize(async function () {
      await db.run(
        "CREATE TABLE IF NOT EXISTS labels (filename TEXT, chord TEXT, tablature TEXT, inTransition BOOLEAN, capoPosition INTEGER)"
      );
      const values = [filename, chord, tablature, inTransition, capoPosition];
      await db.run(
        "INSERT OR REPLACE INTO labels VALUES (?, ?, ?, ?, ?)",
        values
      );
    });

    res.json({ success: true });
  });

  const server = app.listen(port, function () {
    console.log(`Chordviz Labeler (${port})`);
  });

  async function close() {
    await server.close();
    await db.close();
  }

  return { app, close };
};

module.exports = appFactory;
