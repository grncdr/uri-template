opTable = require './optable'
encoders = require './encoders'

exports.Template = class Template
  constructor: (pieces) ->
    @expressions = []
    @prefix = if 'string' == typeof pieces[0] then pieces.shift() else ''
    i = 0
    pieces.forEach (p) =>
      switch (typeof p)
        when 'object' then @expressions[i++] = p
        when 'string' then @expressions[i-1].suffix = p

  match: (string) ->
    if @prefix
      return false unless m = string.match '^' + @prefix
      string = string.substring m[0].length
    vars = {}
    for expr in @expressions
      return false unless len = expr.match(string, vars)
      string = string.substring(len)
    return false if string
    return vars

  expand: (vars) ->
    @prefix + @expressions.map((expr) -> expr.expand vars).join ''

  toString: -> @prefix + @expressions.join ''

stringify = (val, encode) ->
  if typeof val == 'string' then return encode(val)
  if Array.isArray val then return val.map(encode).join(',')
  (for k, v of val
    [k,v].map(encode).join ',').join ','

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

  match: (input, vars) ->
    string = input
    len = 0
    if @op.first isnt '?'
      [string] = string.split '?'
      pathPart = string

    if @op.first
      return false unless string.match '^\\' + @op.first
      string = string.substring ++len

    if @suffix
      return false unless m = string.match @suffix
      len += @suffix.length
      string = string.substring 0, m.index
    
    len += string.length
    i = 0
    named = {}
    ordered = []
    for part in string.split @op.sep
      [n, v] = part.split '='
      if not v?
        ordered.push n
      else if named[n]?
        named[n].push v
      else
        named[n] = [v]
    
    for p in @params
      unless named and (v = named[p.name])?
        if p.explode
          if ordered.length then v = ordered; ordered = null
          else v = named; named = null
        else
          v = ordered.shift()
      return false unless v? # Not enough values
      vars[p.name] = v
    return len

  toString: ->
    "{#{@op.first + @params.map((p) -> p.name + p.explode).join ','}}" + @suffix
