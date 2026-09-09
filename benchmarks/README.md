# Benchmarks

[elm-explorations/benchmark](https://package.elm-lang.org/packages/elm-explorations/benchmark/latest/)
suites for the parts of the app and its vendored packages that show up in a profile.

```
npm run benchmarks
```

That compiles `benchmarks/benchmarks.js`. Open `benchmarks/index.html` straight off disk in
whichever browser you're trying to make faster, and leave it until every row has settled,
which takes a few minutes. The runner reports each comparison as a percentage, so a row
saying the tail recursive version is 180% faster means it did 2.8x the work in the same time.

The page is written by hand rather than compiled with `--output=some.html`, because the page
the compiler emits waits for a `lamdera live` dev server to tell it to start and stays blank
when opened on its own.

The suites live in `benchmarks/src`, which is one of the project's source directories, so
they compile with everything else and need no separate `elm.json`.

Each optimization keeps the version it replaced next to it under `src/ToChildren/`. That way
the comparison still runs after the change has been made, and `tests/ToChildrenTests.elm`
can check that the two build the same thing, which is what makes the numbers worth anything.
That test runs with the rest of the suite:

```
npx elm-test-rs --compiler "$(realpath node_modules/.bin/lamdera)"
```
