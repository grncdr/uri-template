{
	var cls = require('./lib/classes')
	var Template = cls.Template
	var expression = cls.expression
}
uriTemplate
  = pieces:(nonexpression / expression)* { return new Template(pieces) }

expression
  = '{' op:op params:paramList '}' { return expression(op, params) }

op
  = [/;:.?&+#] / ''

pathExpression
  = "{/"

paramList
  = hd:param rst:(',' p:param { return p; })* { rst.unshift(hd); return rst; }

param
  = chars:[a-zA-Z0-9_]* cut:substr? listMarker:'*'? e:extension?
    { return {
      name: chars.join(''),
      explode: listMarker,
      cut: cut,
			extended: e
    } }

substr
  = ':' digits:[0-9]+ { return parseInt(digits.join('')) }

nonexpression
	= chars:[^{]+ { return chars.join(''); }

extension
  = '(' chars:[^)]+ ')' { return chars.join('') }
