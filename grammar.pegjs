{
	cls = require('./classes')
	Template = cls.Template
	Expression = cls.Expression
}
uriTemplate 
  = pieces:(nonexpression / expression)* { return new Template(pieces); }

expression
  = "{" op:op params:paramList "}" { return new Expression(op, params); }

op
  = [/;:.?&+#] / ""

paramList
  = hd:param rst:("," p:param { return p; })* { rst.unshift(hd); return rst; }

param
  = chars:[a-zA-Z_]+ cut:substr? listMarker:"*"? 
    { return {
      name: chars.join(""),
      explode: listMarker,
      cut: cut
    } }

substr
  = ":" digits:[0-9]+ { return parseInt(digits.join('')) }

nonexpression
	= chars:[^{]+ { return chars.join(""); }
