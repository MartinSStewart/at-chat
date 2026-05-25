## Before starting
Install node modules

## While coding

Run `npx lamdera make src/Frontend.elm src/Backend.elm` to check that the code compiles
Run `npx elm-format src/ --yes` to format the code

The following will run tests
```
npx elm-test-rs --compiler `which lamdera`
```

If `elm-test-rs` fails with "failed to fetch ... package.elm-lang.org" (happens in some sandboxed environments due to TLS interception), fall back to:
```
npx --yes elm-test --compiler=`which lamdera`
```