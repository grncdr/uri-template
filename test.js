assert = require('assert')

parser = require('./parser')

vars = {
  count : ["one", "two", "three"],
  dom   : ["example", "com"],
  dub   : "me/too",
  hello : "Hello World!",
  half  : "50%",
  "var" : "value",
  who   : "fred",
  base  : "http://example.com/home/",
  path  : "/foo/bar",
  list  : ["red", "green", "blue"],
  keys  : {"semi":";", "dot":".", "comma":","},
  v     : "6",
  x     : "1024",
  y     : "768",
  empty : "",
  empty_keys  : [],
  undef : null,
}

testCases = {}
testCases["3.2.2.  Simple String Expansion"] = {
  "{var}": "value",
  "{hello}": "Hello%20World%21",
  "{half}": "50%25",
  "O{empty}X": "OX",
  "O{undef}X": "OX",
  "{x,y}": "1024,768",
  "{x,hello,y}": "1024,Hello%20World%21,768",
  "?{x,empty}": "?1024,",
  "?{x,undef}": "?1024",
  "?{undef,y}": "?768",
  "{var:3}": "val",
  "{var:30}": "value",
  "{list}": "red,green,blue",
  "{list*}": "red,green,blue",
  "{keys}": "semi,%3B,dot,.,comma,%2C",
  "{keys*}": "semi=%3B,dot=.,comma=%2C",
}

testCases["3.2.3.  Reserved expansion"] = {
  "{+var}": "value",
  "{+hello}": "Hello%20World!",
  "{+half}": "50%25",

  "{base}index": "http%3A%2F%2Fexample.com%2Fhome%2Findex",
  "{+base}index": "http://example.com/home/index",
  "O{+empty}X": "OX",
  "O{+undef}X": "OX",

  "{+path}/here": "/foo/bar/here",
  "here?ref={+path}": "here?ref=/foo/bar",
  "up{+path}{var}/here": "up/foo/barvalue/here",
  "{+x,hello,y}": "1024,Hello%20World!,768",
  "{+path,x}/here": "/foo/bar,1024/here",

  "{+path:6}/here": "/foo/b/here",
  "{+list}": "red,green,blue",
  "{+list*}": "red,green,blue",
  "{+keys}": "semi,;,dot,.,comma,,",
  "{+keys*}": "semi=;,dot=.,comma=,",
}

testCases["3.2.4.  Fragment expansion"] = {
  "{#var}": "#value",
  "{#hello}": "#Hello%20World!",
  "{#half}": "#50%25",
  "foo{#empty}": "foo#",
  "foo{#undef}": "foo",
  "{#x,hello,y}": "#1024,Hello%20World!,768",
  "{#path,x}/here": "#/foo/bar,1024/here",
  "{#path:6}/here": "#/foo/b/here",
  "{#list}": "#red,green,blue",
  "{#list*}": "#red,green,blue",
  "{#keys}": "#semi,;,dot,.,comma,,",
  "{#keys*}": "#semi=;,dot=.,comma=,",
}

testCases["3.2.5.  Label expansion with dot-prefix"] = {
  "{.who}": ".fred",
  "{.who,who}": ".fred.fred",
  "{.half,who}": ".50%25.fred",
  "www{.dom*}": "www.example.com",
  "X{.var}": "X.value",
  "X{.empty}": "X.",
  "X{.undef}": "X",
  "X{.var:3}": "X.val",
  "X{.list}": "X.red,green,blue",
  "X{.list*}": "X.red.green.blue",
  "X{.keys}": "X.semi,%3B,dot,.,comma,%2C",
  "X{.keys*}": "X.semi=%3B.dot=..comma=%2C",
  "X{.empty_keys}": "X",
  "X{.empty_keys*}": "X",
}

testCases["3.2.6.  Path segment expansion"] = {
  "{/who}": "/fred",
  "{/who,who}": "/fred/fred",
  "{/half,who}": "/50%25/fred",
  "{/who,dub}": "/fred/me%2Ftoo",
  "{/var}": "/value",
  "{/var,empty}": "/value/",
  "{/var,undef}": "/value",
  "{/var,x}/here": "/value/1024/here",
  "{/var:1,var}": "/v/value",
  "{/list}": "/red,green,blue",
  "{/list*}": "/red/green/blue",
  "{/list*,path:4}": "/red/green/blue/%2Ffoo",
  "{/keys}": "/semi,%3B,dot,.,comma,%2C",
  "{/keys*}": "/semi=%3B/dot=./comma=%2C",
}

testCases["3.2.7.  Path-style parameter expansion"] = {
  "{;who}": ";who=fred",
  "{;half}": ";half=50%25",
  "{;empty}": ";empty",
  "{;v,empty,who}": ";v=6;empty;who=fred",
  "{;v,bar,who}": ";v=6;who=fred",
  "{;x,y}": ";x=1024;y=768",
  "{;x,y,empty}": ";x=1024;y=768;empty",
  "{;x,y,undef}": ";x=1024;y=768",
  "{;hello:5}": ";hello=Hello",
  "{;list}": ";list=red,green,blue",
  "{;list*}": ";list=red;list=green;list=blue",
  "{;keys}": ";keys=semi,%3B,dot,.,comma,%2C",
}

testCases["3.2.8.  Form-style query expansion"] = {
  "{?who}": "?who=fred",
  "{?half}": "?half=50%25",
  "{?x,y}": "?x=1024&y=768",
  "{?x,y,empty}": "?x=1024&y=768&empty=",
  "{?x,y,undef}": "?x=1024&y=768",
  "{?var:3}": "?var=val",
  "{?list}": "?list=red,green,blue",
  "{?list*}": "?list=red&list=green&list=blue",
  "{?keys}": "?keys=semi,%3B,dot,.,comma,%2C",
  "{?keys*}": "?semi=%3B&dot=.&comma=%2C",
}

testCases["3.2.9.  Form-style query continuation"] = {
  "{&who}": "&who=fred",
  "{&half}": "&half=50%25",
  "?fixed=yes{&x}": "?fixed=yes&x=1024",
  "{&x,y,empty}": "&x=1024&y=768&empty=",
  "{&x,y,undef}": "&x=1024&y=768",

  "{&var:3}": "&var=val",
  "{&list}": "&list=red,green,blue",
  "{&list*}": "&list=red&list=green&list=blue",
  "{&keys}": "&keys=semi,%3B,dot,.,comma,%2C",
  "{&keys*}": "&semi=%3B&dot=.&comma=%2C",
}

for (var section in testCases) {
  console.log(section);
  var passed = true;
  for (var tpl in testCases[section]) {
    var expected = testCases[section][tpl]
    var got;
    got = parser.parse(tpl).expand(vars)
    if (got != expected) {
      passed = false
      console.log("Expected "+expected+" but got "+got+" [ "+tpl+" ]")
    }
  }
  if (!passed) break;
}

// Test .toString and .toJSON
tpl = '/{simple}/{+reserved}e{/path}{.label}{;path,param}{#fragment}{?query}{&continuation}'
assert.equal(tpl, String(parser.parse(tpl)))
assert.equal('"' + tpl + '"', JSON.stringify(parser.parse(tpl)))
if (!passed) process.exit(1);
