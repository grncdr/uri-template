import * as grammar from "./grammar.js";

export type StartRule =
  | "uriTemplate"
  | "expression"
  | "op"
  | "pathExpression"
  | "paramList"
  | "param"
  | "cut"
  | "listMarker"
  | "substr"
  | "nonexpression"
  | "extension";

import type { Template } from "./classes";

export function parse(input: string, startRule?: StartRule): Template {
  return grammar.parse(input, startRule);
}

export type {
  Template,
  SimpleExpression as TemplateExpression,
  Param as TemplateExpressionParam,
  Variables as Var,
} from "./classes";
