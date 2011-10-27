#  .------------------------------------------------------------------.
#  |          NUL     +      .       /       ;      ?      &      #   |
#  |------------------------------------------------------------------|
#  | first |  ""     ""     "."     "/"     ";"    "?"    "&"    "#"  |
#  | sep   |  ","    ","    "."     "/"     ";"    "&"    "&"    ","  |
#  | named | false  false  false   false   true   true   true   false |
#  | ifemp |  ""     ""     ""      ""      ""     "="    "="    ""   |
#  | allow |   U     U+R     U       U       U      U      U     U+R  |
#  `------------------------------------------------------------------'

module.exports =
  "none":
    first:  ""
    sep:    ","
    named: false
    ifemp:  ""
    allow:   "U"
  "+":
    first:  ""
    sep:    ","
    named: false
    ifemp:  ""
    allow:  "U+R"
  ".":
    first:  "."
    sep:    "."
    named: false
    ifemp:  ""
    allow:   "U"
    emptyExpansion: '.'
  "/":
    first:  "/"
    sep:    "/"
    named: false
    ifemp:  ""
    allow:   "U"
  ";":
    first:  ";"
    sep:    ";"
    named: true
    ifemp:  ""
    allow:   "U"
  "?":
    first:  "?"
    sep:    "&"
    named: true
    ifemp:  "="
    allow:   "U"
  "&":
    first:  "&"
    sep:    "&"
    named: true
    ifemp:  "="
    allow:   "U"
  "#":
    first:  "#"
    sep:    ","
    named: false
    ifemp:  ""
    allow:  "U+R"
    emptyExpansion: '#'
