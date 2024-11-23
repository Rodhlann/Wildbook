import { join } from "path";
import { HotModuleReplacementPlugin } from "webpack";
import UnusedWebpackPlugin from "unused-webpack-plugin";
import { fileURLToPath } from "url";
import { dirname } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));

export const mode = "development";
export const devtool = "source-map";
export const devServer = {
  disableHostCheck: true,
  headers: {
    "Access-Control-Allow-Origin": "*",
  },
  historyApiFallback: true,
  hot: true,
  port: 3000,
  writeToDisk: true,
};
export const plugins = [
  new HotModuleReplacementPlugin(),
  new UnusedWebpackPlugin({
    directories: [join(__dirname, "../../src")],
  }),
];
