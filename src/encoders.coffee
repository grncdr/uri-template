module.exports =
  "U":   (string) -> encode /[^\w~.-]/g, string
  "U+R": (string) -> encode /[^\w.~:\/\?#\[\]@!\$&'()*+,;=-]/g, string

encode = (regexp, string) ->
  string = String string
  next = (start) ->
    encoded = []
    m = regexp.exec string
    if m
      c = m[0].charCodeAt 0

      if c < 128
        encoded.push c
      else if 128 <= c < 2048
        encoded.push (c >> 6) | 192
        encoded.push (c & 63) | 128
      else
        encoded.push (c >> 12) | 224
        encoded.push ((c >> 6) & 63) | 128
        encoded.push (c & 63) | 128

      encoded = encoded.map (c) -> '%' + c.toString(16).toUpperCase()
      string.slice(start, m.index) + encoded.join('') + next(m.index + 1)
    else
      string.substring(start)
  next(0)
