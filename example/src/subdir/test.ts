import { Moment } from "moment";
// intentionally out-of-order import
import { IncomingHttpHeaders } from "http";

// typescript-eslint should error with
// 'any' overrides all other types in this union type
export type MomentOrNull = Moment | null;
