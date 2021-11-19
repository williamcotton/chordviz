const React = require("react");
const ReactDOM = require("react-dom");
const App = require("./app.jsx");

ReactDOM.hydrate(App(), document.querySelector("#app"));
