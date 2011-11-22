opTable = require './optable'
encoders = require './encoders'
{unescape} = require 'querystring' # TODO move this inio the encoders

queryStringOps = ['?', '&']

exports.Template = class Template
  constructor: (pieces) ->
    @expressions = []
    @prefix = if 'string' == typeof pieces[0] then pieces.shift() else ''
    i = 0
    pieces.forEach (p) =>
      switch (typeof p)
        when 'object' then @expressions[i++] = p
        when 'string' then @expressions[i-1].suffix = p

  expand: (vars) ->
    @prefix + @expressions.map((expr) -> expr.expand vars).join ''

  toString: -> @prefix + @expressions.join ''

exports.Expression = class Expression
  constructor: (op, @params) ->
    @op = opTable[op or 'none']
    @params ?= []
    @suffix = '' # Can be clobbered by `new Template`

  expand: (vars) ->
    encode = encoders[@op.allow]
    defined = @params.map((p) => [p, vars[p.name]]).filter((pair) ->
      v = pair[1]
      switch typeof v
        when "undefined" then false
        when "object"
          if Array.isArray v then v.length > 0
          for k, vv of v
            return true if vv
          false
        else true
    )
    expanded = defined.map((pair) =>
      [param, val] = pair

      if param.explode
        if Array.isArray(val) then return val.map(encode).join(@op.sep)
        pairs = []
        for k, v of val
          if Array.isArray(v)
            pairs.push(([k, encode(vv)] for vv in v)...)
          else pairs.push [k, encode(v)]
        pairs.map((p) -> p.join '=').join @op.sep
      else
        s = if typeof val == 'string'
          val = val.substring(0, param.cut) if param.cut
          encode val
        else
          stringify val, encode
        switch true
          when s and @op.named then param.name + '=' + s
          when @op.named then param.name + @op.ifemp
          else s
    ).join(@op.sep)

    if (not expanded) and @op.emptyExpansion and defined.length
      return @op.emptyExpansion + @suffix
    return @suffix unless expanded
    @op.first + expanded + @suffix

  toString: ->
    "{#{@op.first + @params.map((p) -> p.name + p.explode).join ','}}" + @suffix

stringify = (val, encode) ->
  if typeof val == 'string' then return encode(val)
  if Array.isArray val then return val.map(encode).join(',')
  (for k, v of val
    [k,v].map(encode).join ',').join ','
