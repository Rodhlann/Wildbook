import { resolve } from "path";
import { resolve as _resolve } from "path";
import TerserPlugin from "terser-webpack-plugin";
import { fileURLToPath } from "url";
import { dirname } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));

const rootDir = resolve(__dirname, "../../");
const dist = _resolve(rootDir, "dist");

export const mode = "production";
export const devtool = "source-map";
export const entry = {
  main: _resolve(rootDir, "src/index.jsx"),
};
export const output = {
  path: dist,
  filename: "[name].js",
  chunkFilename: "[name].chunk.js",
  publicPath: "/",
};
export const optimization = {
  minimizer: [new TerserPlugin()],
};
