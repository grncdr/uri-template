const fs = require("fs");
const assert = require("assert");
const parser = require("../");
const counters = {
  all: 0,
  failures: 0,
  failuresPEG: 0,
};

const runFile = (filename) => {
  let currentCountFailures = counters.failures;

  const suite = JSON.parse(fs.readFileSync(filename, "utf-8"));

  Object.entries(suite).forEach(([section, { variables, testcases }]) => {
    if (testNamePattern && !testNamePattern.test(section)) {
      return;
    }
    console.log(`\n---\n${section}`);
    testcases.forEach(([URI, expected]) => {
      counters.all += 1;
      let tpl;
      try {
        tpl = parser.parse(URI);
      } catch (e) {
        if (expected != false) {
          counters.failuresPEG += 1;
          counters.failures += 1;
          console.log(`Parsing failed ${URI}\n- Expected ${expected}\n- ${e}`);
        }
        return;
      }

      try {
        assert.equal(tpl.toString(), URI);
      } catch (e) {
        counters.failures += 1;
        console.log(`Round-trip failed ${URI}\n- ${e}`);
        return;
      }

      if (tpl.ast.parts.every((node) => node.type === "literal")) {
        return;
      }

      let actual;
      try {
        actual = tpl.expand(variables);
      } catch (e) {
        if (expected) {
          counters.failuresPEG += 1;
          counters.failures += 1;
          console.log(
            `Expansion failed ${URI}\n- Expected ${expected}\n- ${e}`
          );
        }
        return;
      }
      if (Array.isArray(expected) && expected.includes(actual)) {
        return;
      }
      try {
        assert.strictEqual(actual, expected);
      } catch (e) {
        counters.failures += 1;
        console.log(
          `Expansion failed ${URI}\n- Actual ${actual}\n- Expected ${expected}\n- ${e}`
        );
      }
    });
  });

  if (currentCountFailures == counters.failures) {
    console.log("✔");
  }
};

let testNamePattern =
  process.argv.length > 2 && new RegExp(process.argv[2], "i");

fs.readdirSync(`${__dirname}/uritemplate-test`)
  .filter((fn) => fn.endsWith(".json"))
  .map((fn) => `${__dirname}/uritemplate-test/${fn}`)
  .forEach(runFile);

runFile(__dirname + "/issue-15.json");

if (counters.failures) {
  console.log(
    `Failed ${counters.failures} out of ${counters.all} tests (${counters.failuresPEG} parse errors) `
  );
  process.exit(1);
}
