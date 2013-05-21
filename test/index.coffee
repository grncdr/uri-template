#!/usr/bin/env coffee

fs = require 'fs'
assert = require 'assert'
parser = require '../index'
count =
  all: 0
  failures: 0
  failuresPEG: 0

runFile = (filename) ->
  suite = JSON.parse fs.readFileSync filename, 'utf-8'
  for section, {variables, testcases} of suite
    console.log section
    for [tpl, expected] in testcases
      count.all += 1
      try
        actual = parser.parse(tpl).expand variables
      catch e
        count.failuresPEG += 1
        count.failures += 1
        console.log "- Parsing failed #{tpl}\n#{e}"
        continue
      if Array.isArray(expected) and actual in expected
        expected = actual
      try
        assert.strictEqual actual, expected, tpl
      catch e
        count.failures += 1
        console.log "- Failed #{tpl}\n#{e}"

files = [
  'spec-examples.json'
  'spec-examples-by-section.json'
  'extended-tests.json'
  'negative-tests.json'
]

runFile "#{__dirname}/uritemplate-test/#{file}"  for file in files

console.log "Failed #{count.failures} (#{count.failuresPEG} PEG) out of #{count.all} tests"  if count.failures
