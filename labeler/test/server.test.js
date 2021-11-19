/*
a test for the server.js file
it POSTs to / with a json object of the form: { filename: string, chord: string, tablature: array of integers, inTransition: boolean, capoPosition: integer }
it checks that a row was added to the labels table with the correct values
*/

const assert = require("assert");
const request = require("supertest");
const appFactory = require("../src/server.js");
const dbName = "test.db";
const port = 3120;
const { app, close } = appFactory({ dbName, port });
const sqlite3 = require("sqlite3").verbose();
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

describe("server.js", function () {
  after(async function () {
    try {
      await query("DELETE FROM labels");
      await close();
    } catch (err) {}
  });

  describe("POST /", () => {
    it("should add a row to the labels table", async () => {
      const label = {
        filename: "video_0_frame_232.jpg",
        chord: "G",
        tablature: [3, 2, 0, 0, 3, 3],
        inTransition: false,
        capoPosition: 0,
      };
      const response = await request(app).post("/").send(label).expect(200);
      const result = await query("SELECT * FROM labels");
      assert.equal(result[0].filename, label.filename);
      assert.equal(result[0].chord, label.chord);
      assert.equal(result[0].tablature, label.tablature);
      assert.equal(result[0].inTransition, label.inTransition);
      assert.equal(result[0].capoPosition, label.capoPosition);
    });
  });
});
