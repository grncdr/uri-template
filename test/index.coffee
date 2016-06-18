#!/usr/bin/env coffee

fs = require 'fs'
assert = require 'assert'
parser = require '../index'
count =
  all: 0
  failures: 0
  failuresPEG: 0

runFile = (filename) ->
  currentCountFailures = count.failures
  suite = JSON.parse fs.readFileSync filename, 'utf-8'
  for section, {variables, testcases} of suite
    console.log "\n---\n#{section}"
    for [URI, expected] in testcases
      pass = true
      count.all += 1
      try
        tpl = parser.parse URI
      catch e
        pass = false
        if expected isnt false
          count.failuresPEG += 1
          count.failures += 1
          console.log "Parsing failed #{URI}\n- Expected #{expected}\n- #{e}"
      continue  unless pass and tpl.expressions.length

      try
        actual = tpl.expand variables
      catch e
        pass = false
        if expected isnt false
          count.failuresPEG += 1
          count.failures += 1
          console.log "Expansion failed #{URI}\n- Expected #{expected}\n- #{e}"
      continue  unless pass and tpl.expressions.length

      if Array.isArray(expected) and actual in expected
        expected = actual
      try
        assert.strictEqual actual, expected
      catch e
        count.failures += 1
        console.log "Expansion failed #{URI}\n- Actual #{actual}\n- Expected #{expected}\n- #{e}"
  if currentCountFailures is count.failures
    console.log '✔'

files = if process.argv.length > 2
  process.argv.slice(2)
else
  "#{__dirname}/uritemplate-test/#{file}" for file in fs.readdirSync("#{__dirname}/uritemplate-test").filter((x) -> /\.json$/.test(x))

files.map(runFile)

runFile(__dirname + '/issue-15.json')

if count.failures
  console.log "Failed #{count.failures} (#{count.failuresPEG} PEG) out of #{count.all} tests"
  process.exit 1
