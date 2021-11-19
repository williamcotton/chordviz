const path = require("path");
const webpack = require("webpack");

module.exports = {
  mode: "development",
  entry: "./browser.js",
  module: {
    rules: [
      {
        test: /\.jsx?$/,
        use: "jsx-loader",
        exclude: /node_modules/,
      },
    ],
  },
  resolve: {
    extensions: [".js", ".jsx"],
    fallback: {
      util: require.resolve("util/"),
    },
  },
  output: {
    filename: "app.js",
    path: path.resolve(__dirname, "public"),
  },
  plugins: [
    new webpack.ProvidePlugin({
      process: "process/browser",
    }),
  ],
};
