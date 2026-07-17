# At Chat

A text chat app similar to Discord

## How do I login in development?

1. Start `lamdera live`
2. Click the login button on the homepage
3. Enter the email address in `Backend.adminUser` (which is a@a.se)
4. Open your browser dev tools console. You should see an 8 digit login code. Type that in.
5. You're logged in!

After you've finished a feature, make sure to run elm-review and elm-test!

## How do I send ToBackend messages directly? (app-cli)

`app-cli` is a REPL that lets a user or bot send `Types.ToBackend` messages
straight to the backend, without going through the frontend UI.

1. Start `lamdera live` and open http://localhost:8000 in a browser tab (in
   `lamdera live` the backend runs inside the leader browser tab, so one must
   stay open).
2. In another terminal run `npm run app-cli`.
3. Type an Elm expression of type `Types.ToBackend` at the prompt, e.g.

   ```
   > CheckLoginRequest InitialLoadRequested_None
   ```

4. The expression is pasted into a temporary `Platform.worker` module which is
   compiled with `lamdera make`. The worker serializes the value with the
   generated `Types.w3_encode_ToBackend` wire encoder, and the CLI sends the
   bytes to the backend over the same websocket protocol the browser uses.
   `ToFrontend` responses are decoded with `Types.w3_decode_ToFrontend` and
   printed with `Debug.toString`:

   ```
   > CheckLoginRequest InitialLoadRequested_None
   CheckLoginResponse (Err ())
   ```

`Types` is imported with `exposing (..)` and every module in `src/` is imported
qualified (so you can write `Id.fromInt 1`, `InitialLoadRequested_None`, etc).
Type `help` in the REPL for the extra commands (adding imports, reprinting the
last response, choosing a session id, and so on). Useful flags:

- `--session <sid>` acts as a specific browser session. Copy the `sid` cookie
  from your browser's dev tools to reuse a logged-in session.
- `--url <url>` connects to a different websocket (default
  `ws://localhost:8000/_w`).

The temporary modules live in `elm-stuff/app-cli/` (gitignored).

## How do I run the rust server locally? (for file hosting and Discord integration)

Run `npm run rust-server` in the root folder

## How do I deploy the rust server? (this is just for me to remember, you don't have access to do this)

1. Push your changes to master
2. Make sure you're on the Linux computer, doesn't work on Mac for some reason
3. In the lamdera/runtime repo in the nixos folder run `nix flake lock --update-input at-chat`
4. In the lamdera/runtime repo in the scripts folder run `DEBUG=1 ./lxelm.sh updateServerEnterprise martin-s`