# Benchmarks

[elm-bench](https://package.elm-lang.org/packages/gampleman/elm-bench/latest/) suites for
the parts of the app and its vendored packages that show up in a profile.

```
npm run benchmarks
```

Add `-t chromium`, `-t firefox` or `-t webkit` (each needs `npx playwright install`) to see
whether an optimization holds across engines, and `--filter <pattern>` to run one suite.

Every `Bench.rank`, `Bench.compare` and `Bench.scale` first checks that its implementations
agree, so a rewrite that changed the output fails before any numbers are printed. That check
runs through elm-test-rs and needs to reach package.elm-lang.org. Where it can't, pass
`--skip-test` for the numbers and run the check by hand against the project's own
elm-test-rs, which solves from the local package cache:

```
npx elm-bench run --project benchmarks --compiler "$(realpath node_modules/.bin/lamdera)" --skip-test
cd benchmarks/elm-stuff/node-benchmark-runner \
  && ../../../node_modules/.bin/elm-test-rs src/BenchmarkVerification.elm \
       --compiler ../../../node_modules/.bin/lamdera
```

Each optimization keeps the version it replaced next to it under `src/ToChildren/`, so the
benchmark still compares against what the code used to do after the change has been made.
