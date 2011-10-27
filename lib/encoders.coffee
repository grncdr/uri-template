module.exports =
	"U":   (string) -> encode /[^\w~.-]/g, string
	"U+R": (string) -> encode /[^\w.~:\/\?#\[\]@!\$&'()*+,;=-]/g, string

encode = (regexp, string) ->
  next = (start) ->
    m = regexp.exec string
    if m
      string.slice(start, m.index) +
        '%' + m[0].charCodeAt(0).toString(16).toUpperCase() +
        next(m.index+1)
    else
      string.substring(start)
  next(0)
