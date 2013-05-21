module.exports =
  "U":   (string) -> encode /[^\w~.-]/g, string
  "U+R": (string) -> encode /[^\w.~:\/\?#\[\]@!\$&'()*+,;=-]/g, string

encode = (regexp, string) ->
  string = String string
  next = (start) ->
    m = regexp.exec string
    if m
      c = m[0].charCodeAt 0

      if c < 128
        utftext = '%' + c.toString(16).toUpperCase()
      else if 128 <= c < 2048
        utftext = '%' + ((c >> 6) | 192).toString(16).toUpperCase()
        utftext += '%' + ((c & 63) | 128).toString(16).toUpperCase()
      else
        utftext = '%' + ((c >> 12) | 224).toString(16).toUpperCase()
        utftext += '%' + (((c >> 6) & 63) | 128).toString(16).toUpperCase()
        utftext += '%' + ((c & 63) | 128).toString(16).toUpperCase()
      string.slice(start, m.index) + utftext + next(m.index + 1)
    else
      string.substring(start)
  next(0)
