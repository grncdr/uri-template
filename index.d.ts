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

  interface TemplateExpressionParam {
    explode: string
    name: string
  }

  interface TemplateExpression {
    params: TemplateExpressionParam[]
  }

  type Vars = Record<string, string | number | Record<string, string | number>>

  export class Template {
    expand: (vars: Vars) => string
    prefix: string
    expressions: TemplateExpression[]
    toJSON(): string
  }

  export function parse(input: string, startRule?: StartRule): Template
}
