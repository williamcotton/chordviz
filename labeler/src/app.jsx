const React = require("react");
const hotkeys = require("hotkeys-js").default;

const { useState, useEffect } = React;

const chordShapes = ["g", "c", "d", "e", "a"];

const musicScale = [
  "c",
  "c#",
  "d",
  "d#",
  "e",
  "f",
  "f#",
  "g",
  "g#",
  "a",
  "a#",
  "b",
];

function positionOfChordShapeInMusicScale(chordShape) {
  return musicScale.indexOf(chordShape);
}

function chordFromCapoPositionAndChordShape(
  halfstepOffset,
  capoPosition,
  chordShape
) {
  const position = positionOfChordShapeInMusicScale(chordShape);
  const chord = musicScale[(halfstepOffset + position + capoPosition) % 12];
  return chord;
}

const onLabel = async ({
  filename,
  chord,
  tablature,
  inTransition,
  capoPosition,
}) => {
  const response = await fetch("/label", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      filename,
      chord,
      tablature,
      inTransition,
      capoPosition,
    }),
  });
  return response.json();
};

function MusicScaleDropdown({ musicScale, onChange, selected }) {
  return (
    <select value={selected} onChange={(e) => onChange(e.target.value)}>
      {musicScale.map((scale) => (
        <option key={scale} value={scale}>
          {scale}
        </option>
      ))}
    </select>
  );
}

function ChordShapesDropdown({ chordShapes, onChange, selected }) {
  return (
    <select value={selected} onChange={(e) => onChange(e.target.value)}>
      {chordShapes.map((shape) => (
        <option key={shape} value={shape}>
          {shape}
        </option>
      ))}
    </select>
  );
}

function Labeler({ onLabel }) {
  const [filename, setFilename] = useState("");
  const [chord, setChord] = useState("");
  const [chordShape, setChordShape] = useState("g");
  const [tablature, setTablature] = useState([]);
  const [inTransition, setInTransition] = useState(false);
  const [capoPosition, setCapoPosition] = useState(0);

  const handleSubmit = async (event) => {
    event.preventDefault();
    const response = await onLabel({
      filename,
      chord,
      tablature,
      inTransition,
      capoPosition,
    });
    console.log(response);
  };

  useEffect(() => {
    hotkeys.unbind();

    hotkeys("1", () =>
      setChord(chordFromCapoPositionAndChordShape(0, capoPosition, chordShape))
    );

    hotkeys("4", () =>
      setChord(chordFromCapoPositionAndChordShape(5, capoPosition, chordShape))
    );

    hotkeys("5", () =>
      setChord(chordFromCapoPositionAndChordShape(7, capoPosition, chordShape))
    );

    hotkeys("t", () =>
      setInTransition((prevInTransition) => !prevInTransition)
    );
  }, [chordShape, capoPosition, inTransition]);

  return (
    <form onSubmit={handleSubmit}>
      <label>
        Filename:
        <input
          type="text"
          value={filename}
          onChange={(event) => setFilename(event.target.value)}
        />
      </label>
      <label>
        Chord Shape:
        <ChordShapesDropdown
          chordShapes={chordShapes}
          onChange={(value) => setChordShape(value)}
          selected={chordShape}
        />
      </label>
      <label>
        Tablature:
        <input
          type="text"
          value={tablature}
          onChange={(event) => setTablature(event.target.value)}
        />
      </label>
      <label>
        In Transition:
        <input
          type="checkbox"
          checked={inTransition}
          onChange={(event) => setInTransition(event.target.checked)}
        />
      </label>
      <label>
        Capo Position:
        <input
          type="number"
          value={capoPosition}
          onChange={(event) =>
            setCapoPosition(parseInt(event.target.value, 10))
          }
        />
      </label>
      <div>
        Chord: <span>{chord}</span>
      </div>
      <button type="submit">Submit</button>
    </form>
  );
}

module.exports = () => {
  return <Labeler onLabel={onLabel} />;
};
