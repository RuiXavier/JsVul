import { ExecException, ChildProcess } from "child_process";

export interface SetUpOptions {
  format?: any;
  font?: any;
  fontSize?: any;
  width?: any;
  height?: any;
  locale?: any;
  xRange?: any;
  yRange?: any;
  margin?: any;
  time?: "hours" | "Hours" | "Days" | "days" | string;
  title?: any;
  titleSize?: any;
  logscale?: any;
  xlabel?: any;
  ylabel?: any;
  decimalsign?: any;
  xRotate?: any;
  yFormat?: any;
  nokey?: any;
}

export type FinishFunc = (
  error: ExecException | null,
  stdout: string | Buffer,
  stderr: string | Buffer
) => void;

export type DataType = Map<string | number, number>;
export type SeriesDataType = { [name: string]: DataType };
export type DataTypeInput =
  | number[]
  | { [name: string]: DataType | number[] }
  | DataType;
export interface PlotOptions extends SetUpOptions {
  data?: DataTypeInput;
  filename: string;
  style?:
    | "lines"
    | "impulses"
    | "points"
    | "linespoints"
    | "candlesticks"
    | string;
  moving_avg?: number;
  moving_max?: number;
  exec?: any;
  hideSeriesTitle?: boolean;
  finish?: FinishFunc;
  args?: string[]; // commands
}
