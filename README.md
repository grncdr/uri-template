# URI Template

This is a node.js implementation of the URI template draft standard
defined at http://tools.ietf.org/html/draft-gregorio-uritemplate-08

# Example

```javascript

parser = require('uri-template')

tpl = parser.parse('/{year}/{month}/{day}{?orderBy,direction}')

tpl.expand({ year: 2006, month: 6, day: 6 }) # /2006/6/6
tpl.expand({ year: 2006, month: 6, day: 6, orderBy: 'size' })
# /2006/6/6?orderBy=size
tpl.expand({ year: 2006, month: 6, day: 6, orderBy: 'time', direction: 'asc' })
# /2006/6/6?orderBy=time&direction=asc

tpl = parser.parse('/search{?q,*otherParams}')
tpl.expand({ q: 'Bigger office', otherParams: { prefer: "Sterling's office", accept: "Crane's office" }})
# /search?q=Bigger%20office&prefer=Sterling%27s%20office&accept=Crane%27s%20office
```

For more thorough coverage of the syntax, see `test.js` or the RFC.
