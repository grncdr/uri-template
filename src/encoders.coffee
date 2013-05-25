pctEncode = require 'pct-encode'

exports["U"]   = pctEncode /[^\w~.-]/g
exports["U+R"] = pctEncode /[^\w.~:\/\?#\[\]@!\$&'()*+,;=-]/g
