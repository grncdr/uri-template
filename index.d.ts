declare module "uri-template" {
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

  export class Template {
    expand: (vars: object) => string
  }

  export function parse(input: string, startRule?: StartRule): Template
}
