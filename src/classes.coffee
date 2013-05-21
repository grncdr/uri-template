encoders = require './encoders'

Template = class Template
  constructor: (pieces) ->
    ###
    :param pieces: An array of strings and expressions in the order they appear in the template.
    ###
    @expressions = []
    @prefix = if 'string' == typeof pieces[0] then pieces.shift() else ''
    i = 0
    pieces.forEach (p) =>
      switch (typeof p)
        when 'object' then @expressions[i++] = p
        when 'string' then @expressions[i - 1].suffix = p

  expand: (vars) ->
    @prefix + @expressions.map((expr) -> expr.expand vars).join ''

  toString: -> @prefix + @expressions.join ''

  toJSON: -> @toString()


class SimpleExpression
  first:  ""
  sep:    ","
  named:  false
  empty:  ""
  allow:  "U"

  constructor: (@params) ->
    @params ?= []
    @suffix = '' # Can be clobbered by `new Template`

  encode: (string) =>
    ### Encode a string value for the URI ###
    encoders[@allow](string)

  stringifySingle: (param, value) =>
    ### Encode a single value as a string ###
    type = typeof value
    if type in ['string', 'boolean', 'number']
      value = value.toString()
      @encode value.substring(0, param.cut or value.length)
    else if Array.isArray value
      value.map(@encode).join(',')
    else
      (for k, v of value
        [k,v].map(@encode).join ',').join ','

  expand: (vars) ->
    defined = definedPairs(@params, vars)
    expanded = defined.map((pair) => @_expandPair pair...).join(@sep)

    if expanded
      @first + expanded + @suffix
    else
      if @empty and defined.length
        @empty + @suffix
      else
        @suffix

  definedPairs = (params, vars) ->
    ###
    Return an array of [key, value] arrays where ``key`` is a parameter name
    from ``@params`` and ``value`` is the value from vars, when ``value`` is
    neither undefined nor an empty collection.
    ###
    params.map((p) => [p, vars[p.name]]).filter (pair) ->
      v = pair[1]
      switch typeof v
        when "undefined" then false
        when "object"
          if Array.isArray v then v.length > 0
          for k, vv of v
            return true if vv
          false
        else true

  _expandPair: (param, value) =>
    ###
    Return the expanded string form of ``pair``.

    :param pair: A ``[param, value]`` tuple.
    ###
    name = param.name
    if param.explode
      if Array.isArray(value)
        @explodeArray param, value
      else if typeof value is 'string'
        @stringifySingle param, value
      else
        @explodeObject value
    else
      string = @stringifySingle(param, value)
      string

  explodeArray: (param, array) =>
    array.map(@encode).join(@sep)

  explodeObject: (object) =>
    pairs = []
    for k, v of object
      if Array.isArray(v)
        pairs.push([k, @encode vv]) for vv in v
      else
        pairs.push [k, @encode v]
    pairs.map((pair) -> pair.join '=').join(@sep)

  toString: ->
    "{#{@first + @params.map((p) -> p.name + p.explode).join(',')}}" + @suffix

  toJSON: -> @toString()

class NamedExpression extends SimpleExpression
  ###
  A NamedExpression uses name=value expansions in most cases
  ###
  stringifySingle: (param, value) =>
    value = if value = super
      "=#{value}"
    else
      @empty
    "#{param.name}#{value}"

  explodeArray: (param, array) =>
    array.map((v) => "#{param.name}=#{@encode v}").join(@sep)

class ReservedExpression extends SimpleExpression
  encode: (string) -> encoders['U+R'](string)
  toString: -> '{+' + (super).substring(1)

class FragmentExpression extends SimpleExpression
  first: '#'
  empty: '#'
  encode: (string) -> encoders['U+R'](string)

class LabelExpression extends SimpleExpression
  first: '.'
  sep: '.'
  empty: '.'

class PathSegmentExpression extends SimpleExpression
  first: '/'
  sep: '/'

class PathParamExpression extends NamedExpression
  first: ';'
  sep: ';'

class FormStartExpression extends NamedExpression
  first: '?'
  sep: '&'
  empty: '='

class FormContinuationExpression extends FormStartExpression
  first: '&'

module.exports = {
  Template
  SimpleExpression
  NamedExpression
  ReservedExpression
  FragmentExpression
  LabelExpression
  PathSegmentExpression
  PathParamExpression
  FormStartExpression
  FormContinuationExpression
  expression: (op, params) ->
    cls = switch op
      when ''  then SimpleExpression
      when '+' then ReservedExpression
      when '#' then FragmentExpression
      when '.' then LabelExpression
      when '/' then PathSegmentExpression
      when ';' then PathParamExpression
      when '?' then FormStartExpression
      when '&' then FormContinuationExpression
    new cls params
}
