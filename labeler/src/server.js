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
const child_process = require("child_process");
const cors = require('cors');

require("node-jsx").install();

const App = require("./app.jsx");

function listOfFilesInDirectory(dir) {
  return new Promise((resolve, reject) => {
    const fs = require("fs");
    fs.readdir(dir, (err, files) => {
      if (err) {
        reject(err);
      }
      resolve(files);
    });
  });
}

const images = listOfFilesInDirectory(path.join(__dirname, "../../image_data"));

const template = async (app) => `
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

  const query = async (query) => {
    return new Promise((resolve, reject) => {
      db.all(query, (err, rows) => {
        if (err) {
          reject(err);
        }
        resolve(rows);
      });
    });
  };

  app.use(express.static(path.join(__dirname, "../public")));

  app.use(express.static(path.join(__dirname, "../../image_data")));

  app.use(bodyParser.json());

  app.use(cors());

  app.get("/", async function (req, res) {
    const html = ReactDOMServer.renderToString(React.createElement(App, null));
    res.send(await template(html));
  });

  app.get("/images", async function (req, res) {
    res.send(JSON.stringify(await images));
  });

  app.get("/label/:filename", async function (req, res) {
    const filename = req.params.filename;
    const labeledImage = await query(
      `SELECT * FROM labels WHERE filename = "${filename}"`
    );
    res.send(JSON.stringify(labeledImage));
  });

  app.post("/label", async function (req, res) {
    const { filename, chord, tablature, inTransition, capoPosition } = req.body;

    await db.serialize(async function () {
      await db.run(
        "CREATE TABLE IF NOT EXISTS labels (filename TEXT, chord TEXT, tablature TEXT, inTransition BOOLEAN, capoPosition INTEGER)"
      );
      const values = [filename, chord, tablature, inTransition, capoPosition];
      await query(`DELETE FROM labels WHERE filename = "${filename}"`);
      await db.run(
        "INSERT OR REPLACE INTO labels VALUES (?, ?, ?, ?, ?)",
        values
      );
    });

    res.json({ success: true });
  });

  app.get("/predict/:filename", async function (req, res) {
    const filename = req.params.filename;
    child_process.exec(`python3 ../pytorch_model/predict.py ../image_data/${filename}`, function (err, stdout, stderr) {
      if (err) {
          console.log('err:', err); // log the error
          res.json({ success: false, error: err });
      } else {
          let prediction = stdout.split('\n'); // splitting stdout by newline
          let tablature = prediction[0].split(': ')[1];
          let inTransition = prediction[1].split(': ')[1] === 'True' ? true : false; // Converting string to boolean
          let capoPosition = parseInt(prediction[2].split(': ')[1]); // Converting string to int
          res.json({ success: true, tablature: tablature, inTransition: inTransition, capoPosition: capoPosition });
      }
    });
  });

  const server = app.listen(port, function () {
    console.log(`Chordviz Labeler (http://localhost:${port})`);
  });

  async function close() {
    await server.close();
    await db.close();
  }

  return { app, close };
};

module.exports = appFactory;
