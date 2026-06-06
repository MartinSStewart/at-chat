// Runs the compiled Elm benchmark in Node.
// Build first: npx lamdera make benchmarks/PhysicsBenchmark.elm --output=benchmarks/main.js
const { Elm } = require('./main.js');

const app = Elm.PhysicsBenchmark.init({});
app.ports.output.subscribe(msg => {
  console.log(msg);
  process.exit(0);
});

// Keep node alive while the Task chain (warmup + sample) runs.
setInterval(() => {}, 1000);
