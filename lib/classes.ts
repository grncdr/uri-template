import pctEncode from "pct-encode";

const encoders = {
  U: pctEncode(/[^\w~.-]/g),
  "U+R": pctEncode(/[^\w.~:\/\?#\[\]@!\$&'()*+,;=%-]|%(?!\d\d)/g),
};

export interface Param {
  name: string;
  cut?: number;
  explode?: "*";
  extended?: string;
}

export type Operator = "/" | ";" | "." | "?" | "&" | "+" | "#" | "";
export type Variables = Record<string, unknown>;

export class Template {
  public prefix: string;
  public expressions: SimpleExpression[];

  constructor(pieces: (string | SimpleExpression)[]) {
    /*
    :param pieces: An array of strings and expressions in the order they appear in the template.
    */

    this.expressions = [];
    this.prefix =
      "string" === typeof pieces[0] ? (pieces.shift() as string) : "";
    pieces.forEach((p, i) => {
      switch (typeof p) {
        case "object":
          return (this.expressions[i++] = p);
        case "string":
          return (this.expressions[i - 1].suffix = p);
      }
    });
  }

  expand(vars: Variables) {
    return (
      this.prefix +
      this.expressions
        .map(function (expr) {
          return expr.expand(vars);
        })
        .join("")
    );
  }

  toString() {
    return this.prefix + this.expressions.join("");
  }

  toJSON() {
    return this.toString();
  }
}

export function expression(
  op: Operator,
  params: Param[] = []
): SimpleExpression {
  switch (op) {
    case "":
      return new SimpleExpression(params);
    case "+":
      return new ReservedExpression(params);
    case "#":
      return new FragmentExpression(params);
    case ".":
      return new LabelExpression(params);
    case "/":
      return new PathSegmentExpression(params);
    case ";":
      return new PathParamExpression(params);
    case "?":
      return new FormStartExpression(params);
    case "&":
      return new FormContinuationExpression(params);
  }
}

class SimpleExpression {
  params: Param[];
  encode: (s: string) => string = encoders.U;
  suffix: string = "";
  first = "";
  sep = ",";
  named = false;
  empty = "";

  constructor(variables: Param[]) {
    this.params = variables;
  }

  expand(vars: Variables) {
    const defined = definedPairs(this.params, vars);
    const expanded = defined
      .map(([param, value]) => this.expandValue(param, value))
      .join(this.sep);
    if (expanded) {
      return this.first + expanded + this.suffix;
    } else {
      if (this.empty && defined.length) {
        return this.empty + this.suffix;
      } else {
        return this.suffix;
      }
    }
  }

  /*
  Return the expanded string form of `pair`.
  */
  expandValue(param: Param, value: unknown): string {
    if (param.explode) {
      if (Array.isArray(value)) {
        return this.explodeArray(param, value);
      } else if (typeof value === "object") {
        return this.explodeObject(param, value as object);
      } else {
        return this.stringifySingle(param, value);
      }
    } else {
      return this.stringifySingle(param, value);
    }
  }

  /*
  Encode a single value as a string
  */
  stringifySingle(param: Param, value: unknown) {
    if (Array.isArray(value)) {
      if (param.cut) {
        throw new Error(
          "Prefixed Values do not support lists. Check " + param.name
        );
      }
      return value.map(this.encode).join(",");
    } else if (typeof value === "object") {
      if (value == null) {
        return "";
      }
      if (param.cut) {
        throw new Error(
          "Prefixed Values do not support maps. Check " + param.name
        );
      }
      return Object.entries(value)
        .map((entry) => entry.map(this.encode).join(","))
        .join(",");
    } else {
      let s = (value as string).toString();
      if (param.cut) {
        s = s.substring(0, param.cut);
      }
      return this.encode(s);
    }
  }

  explodeArray(_param: Param, array: string[]) {
    return array.map(this.encode).join(this.sep);
  }

  explodeObject(_param: Param, object: object) {
    const pairs: string[] = [];
    Object.entries(object).forEach(([k, v]) => {
      k = this.encode(k);
      if (Array.isArray(v)) {
        v.forEach((item) => {
          pairs.push(`${k}=${this.encode(item)}`);
        });
      } else {
        pairs.push(`${k}=${this.encode(v)}`);
      }
    });
    return pairs.join(this.sep);
  }

  toString() {
    const params = this.params.map((p) => `${p.name}${p.explode}`).join(",");
    return "{" + this.first + params + "}" + this.suffix;
  }

  toJSON() {
    return this.toString();
  }
}

class NamedExpression extends SimpleExpression {
  override stringifySingle(param: Param, value: unknown) {
    value = super.stringifySingle(param, value);
    value = value ? "=" + value : this.empty;
    return "" + param.name + value;
  }

  override explodeArray(param: Param, array: string[]) {
    var _this = this;
    return array
      .map(function (v) {
        return "" + param.name + "=" + _this.encode(v);
      })
      .join(this.sep);
  }
}

class ReservedExpression extends SimpleExpression {
  override encode = encoders["U+R"];

  override toString() {
    return "{+" + super.toString().substring(1);
  }
}

class FragmentExpression extends SimpleExpression {
  override first = "#";
  override empty = "#";
  override encode = encoders["U+R"];
}

class LabelExpression extends SimpleExpression {
  override first = ".";
  override sep = ".";
  override empty = ".";
}

class PathSegmentExpression extends SimpleExpression {
  override first = "/";
  override sep = "/";
}

class PathParamExpression extends NamedExpression {
  override first = ";";
  override sep = ";";
}

class FormStartExpression extends NamedExpression {
  override first = "?";
  override sep = "&";
  override empty = "=";
}

class FormContinuationExpression extends FormStartExpression {
  override first = "&";
}

export type {
  SimpleExpression,
  NamedExpression,
  ReservedExpression,
  FragmentExpression,
  LabelExpression,
  PathSegmentExpression,
  PathParamExpression,
  FormStartExpression,
  FormContinuationExpression,
};

/* Return an array of `[param, value]` arrays where `value` is a defined, non-empty value from`vars` */
function definedPairs(params: Param[], vars: Variables): [Param, unknown][] {
  return params
    .map((p) => [p, vars[p.name]] as [Param, unknown])
    .filter(([_p, v]) => {
      switch (typeof v) {
        case "undefined":
          return false;
        case "object":
          if (v == null) {
            return false;
          }
          if (Array.isArray(v)) {
            return v.length > 0;
          }
          return Object.values(v).some((vv) => vv != null);
        default:
          return true;
      }
    });
}
