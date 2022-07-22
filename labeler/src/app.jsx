const React = require("react");
const hotkeys = require("hotkeys-js").default;

const { useState, useEffect } = React;

const chordShapes = ["g", "c", "d", "e", "a"];

const X = "X";

const chordShapeTablature = {
  g: {
    1: [3, 2, 0, 0, 3, 3], // G
    4: [X, 3, 2, 0, 1, 0], // C
    5: [X, 0, 0, 2, 3, 2], // D
  },
  c: {
    1: [X, 3, 2, 0, 1, 0], // C
    4: [1, 3, 3, 2, 1, 1], // F
    5: [3, 2, 0, 0, 3, 3], // G
  },
  d: {
    1: [X, 0, 0, 2, 3, 2], // D
    4: [3, 2, 0, 0, 3, 3], // G
    5: [0, 0, 2, 2, 2, 0], // A
  },
  e: {
    1: [0, 2, 2, 1, 0, 0], // E
    4: [0, 0, 2, 2, 2, X], // A
    5: [2, 2, 4, 4, 4, X], // B
  },
  a: {
    1: [0, 0, 2, 2, 2, 0], // A
    4: [X, 0, 0, 2, 3, 2], // D
    5: [0, 2, 2, 1, 0, 0], // E
  },
};

function tablatureInCapoPosition(tablature, capoPosition) {
  return tablature.map((note) => (note === X ? note : note + capoPosition));
}

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

function fetchImages() {
  return fetch("/images").then((response) => response.json());
}

function fetchLabeledImageByFilename(filename) {
  return fetch(`/label/${filename}`).then((response) => response.json());
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

function setCookie(name, value) {
  document.cookie = `${name}=${value}; path=/`;
}

function getCookie(name) {
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) {
    return parts.pop().split(";").shift();
  }
}

function Labeler({ onLabel }) {
  const [chord, setChord] = useState("");
  const [chordShape, setChordShape] = useState("g");
  const [tablature, setTablature] = useState([]);
  const [inTransition, setInTransition] = useState(false);
  const [capoPosition, setCapoPosition] = useState(0);
  const [images, setImages] = useState([]);
  const [currentImage, setCurrentImage] = useState(0);
  const [currentLabeledImage, setCurrentLabeledImage] = useState(null);

  const currentImageFilename = images[currentImage] || "";

  const handleSubmit = async (event) => {
    if (event) {
      event.preventDefault();
    }
    const labeledImage = {
      filename: currentImageFilename,
      chord,
      tablature,
      inTransition,
      capoPosition,
    };
    const response = await onLabel(labeledImage);
    if (response.success) {
      setCurrentLabeledImage([labeledImage]);
    }
  };

  function nextCurrentImage() {
    const nextCurrentImage = (currentImage + 1) % images.length;
    setCookie("currentImage", nextCurrentImage);
    setCurrentImage(nextCurrentImage);
  }

  function previousCurrentImage() {
    const previousCurrentImage =
      (currentImage - 1 + images.length) % images.length;
    setCookie("currentImage", previousCurrentImage);
    setCurrentImage(previousCurrentImage);
  }

  function toggleInTransition() {
    setInTransition(!inTransition);
  }

  function setChordI() {
    const tablature = tablatureInCapoPosition(
      chordShapeTablature[chordShape][1],
      capoPosition
    );
    setChord(chordFromCapoPositionAndChordShape(0, capoPosition, chordShape));
    setTablature(tablature);
  }

  function setChordIV() {
    const tablature = tablatureInCapoPosition(
      chordShapeTablature[chordShape][4],
      capoPosition
    );
    setChord(chordFromCapoPositionAndChordShape(5, capoPosition, chordShape));
    setTablature(tablature);
  }

  function setChordV() {
    const tablature = tablatureInCapoPosition(
      chordShapeTablature[chordShape][5],
      capoPosition
    );
    setChord(chordFromCapoPositionAndChordShape(7, capoPosition, chordShape));
    setTablature(tablature);
  }

  useEffect(() => {
    hotkeys.unbind();
    hotkeys("1", setChordI);
    hotkeys("4", setChordIV);
    hotkeys("5", setChordV);
    hotkeys("t", toggleInTransition);
    hotkeys("left", previousCurrentImage);
    hotkeys("right", nextCurrentImage);
    hotkeys("enter", handleSubmit);
  }, [
    chordShape,
    capoPosition,
    inTransition,
    currentImage,
    images,
    chord,
    tablature,
  ]);

  useEffect(() => {
    fetchImages().then((images) => setImages(images));
  }, []);

  useEffect(() => {
    if (!currentImageFilename) {
      return;
    }
    fetchLabeledImageByFilename(currentImageFilename).then((labeledImage) =>
      setCurrentLabeledImage(labeledImage)
    );
  }, [currentImageFilename]);

  useEffect(() => {
    // a regular expression to match capo_0_shape_A_1_frame_0.jpg
    const regex = /capo_(\d+)_shape_([A-G])_.*.jpg/;
    const match = regex.exec(currentImageFilename);

    if (match) {
      const [, capoPositionString, chordShape] = match;
      setCapoPosition(parseInt(capoPositionString));
      setChordShape(chordShape.toLowerCase());
    }
  }, [currentImageFilename]);

  useEffect(
    () => setCurrentImage(parseInt(getCookie("currentImage")) || 0),
    []
  );

  const labeledImage = currentLabeledImage ? currentLabeledImage[0] : false;

  return (
    <div>
      <div style={{ display: "flex" }}>
        <img
          src={currentImageFilename}
          style={{
            borderWidth: "5px",
            borderStyle: "solid",
            borderColor: labeledImage
              ? labeledImage.inTransition
                ? "yellow"
                : "green"
              : "black",
          }}
        />
        <div>
          {labeledImage && (
            <div style={{ marginLeft: 30 }}>
              <div style={{ fontSize: 40 }}>
                Capo: {labeledImage.capoPosition}
              </div>
              <div style={{ fontSize: 40 }}>
                {labeledImage.chord.toUpperCase()}
              </div>
              <div style={{ fontSize: 40 }}>{labeledImage.tablature}</div>
            </div>
          )}
        </div>
      </div>
      <form onSubmit={handleSubmit}>
        <label>
          Filename:
          <input
            type="text"
            defaultValue={currentImageFilename}
            style={{ width: "300px" }}
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
      <table>
        <thead>
          <tr>
            <th>Key</th>
            <th>Command</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>1</td>
            <td>Set chord I</td>
          </tr>
          <tr>
            <td>4</td>
            <td>Set chord IV</td>
          </tr>
          <tr>
            <td>5</td>
            <td>Set chord V</td>
          </tr>
          <tr>
            <td>t</td>
            <td>Toggle in transition</td>
          </tr>
          <tr>
            <td>left</td>
            <td>Previous image</td>
          </tr>
          <tr>
            <td>right</td>
            <td>Next image</td>
          </tr>
          <tr>
            <td>enter</td>
            <td>Submit</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}

module.exports = () => {
  return <Labeler onLabel={onLabel} />;
};
