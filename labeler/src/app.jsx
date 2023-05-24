const React = require("react");
const hotkeys = require("hotkeys-js").default;

const { useState, useEffect } = React;

const chordShapes = ["g", "c", "d", "e", "a"];

const X = "X";

const chordShapeTablature = {
  g: {
    1: [3, 2, 0, 0, 3, 3], // G
    2: [0, 0, 2, 2, 1, 0], // Am
    4: [X, 3, 2, 0, 1, 0], // C
    5: [X, 0, 0, 2, 3, 2], // D
    6: [0, 2, 2, 0, 0, 0], // Em
  },
  c: {
    1: [X, 3, 2, 0, 1, 0], // C
    2: [X, 0, 0, 2, 3, 1], // Dm
    4: [1, 3, 3, 2, 1, 1], // F
    5: [3, 2, 0, 0, 3, 3], // G
    6: [0, 0, 2, 2, 1, 0], // Am
  },
  d: {
    1: [X, 0, 0, 2, 3, 2], // D
    2: [0, 2, 2, 0, 0, 0], // Em
    4: [3, 2, 0, 0, 3, 3], // G
    5: [0, 0, 2, 2, 2, 0], // A
    6: [X, 2, 4, 4, 3, 2], // Bm
  },
  e: {
    1: [0, 2, 2, 1, 0, 0], // E
    2: [2, 4, 4, 2, 2, 2], // F#m
    4: [0, 0, 2, 2, 2, X], // A
    5: [2, 2, 4, 4, 4, X], // B
    6: [X, 4, 6, 6, 5, 4], // C#m
  },
  a: {
    1: [0, 0, 2, 2, 2, 0], // A
    2: [X, 2, 4, 4, 3, 2], // Bm
    4: [X, 0, 0, 2, 3, 2], // D
    5: [0, 2, 2, 1, 0, 0], // E
    6: [2, 4, 4, 2, 2, 2], // F#m
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

function fetchPredictionByFilename(filename) {
  return fetch(`http://localhost:3034/predict/${filename}`)
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.json();
    })
    .catch((e) => {
      console.error(
        `There was a problem with the fetch operation: ${e.message}`
      );
    });
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
  const [imageInput, setImageInput] = useState("");

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

  function setChordii() {
    const tablature = tablatureInCapoPosition(
      chordShapeTablature[chordShape][2],
      capoPosition
    );
    setChord(chordFromCapoPositionAndChordShape(2, capoPosition, chordShape));
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

  function setChordvi() {
    const tablature = tablatureInCapoPosition(
      chordShapeTablature[chordShape][6],
      capoPosition
    );
    setChord(chordFromCapoPositionAndChordShape(9, capoPosition, chordShape));
    setTablature(tablature);
  }

  useEffect(() => {
    hotkeys.unbind();
    hotkeys("1", setChordI);
    hotkeys("2", setChordii);
    hotkeys("4", setChordIV);
    hotkeys("5", setChordV);
    hotkeys("6", setChordvi);
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

  const [currentPrediction, setCurrentPrediction] = useState(null);

  useEffect(() => {
    if (!currentImageFilename) {
      return;
    }
    fetchPredictionByFilename(currentImageFilename).then((prediction) => {
      return setCurrentPrediction(prediction);
    });
  }, [currentImageFilename]);

  const labeledImage = currentLabeledImage ? currentLabeledImage[0] : false;

  const handleSetImage = () => {
    const imageIndex = images.indexOf(imageInput);
    if (imageIndex >= 0) {
      setCookie("currentImage", imageIndex);
      setCurrentImage(imageIndex);
    } else {
      alert(`Image with filename "${imageInput}" not found.`);
    }
  };

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
              <h2>Label</h2>
              <div style={{ fontSize: 40 }}>
                Capo: {labeledImage.capoPosition}
              </div>
              <div style={{ fontSize: 40 }}>{labeledImage.tablature}</div>
              <div style={{ fontSize: 40 }}>
                {labeledImage.chord.toUpperCase()}
              </div>
            </div>
          )}
        </div>
        <div>
          {currentPrediction && (
            <div style={{ marginLeft: 30 }}>
              <h2>Prediction</h2>
              <div style={{ fontSize: 40 }}>
                Capo: {currentPrediction.capoPosition}
              </div>
              <div style={{ fontSize: 40 }}>
                {currentPrediction.tablature.join(",")}
              </div>
              <div style={{ fontSize: 40 }}>
                {currentPrediction.inTransition ? "In Transition" : ""}
              </div>
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
            <td>2</td>
            <td>Set chord ii</td>
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
            <td>6</td>
            <td>Set chord vi</td>
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
      <div>
        <label>
          Jump to Image Filename:
          <input
            type="text"
            value={imageInput}
            onChange={(event) => setImageInput(event.target.value)}
            style={{ width: "300px" }}
          />
          <button type="button" onClick={handleSetImage}>
            Set Image
          </button>
        </label>
      </div>
    </div>
  );
}

module.exports = () => {
  return <Labeler onLabel={onLabel} />;
};
