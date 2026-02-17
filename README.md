# At Chat

A text chat app similar to Discord

## How do I login in development?

1. Start `lamdera live`
2. Click the login button on the homepage
3. Enter the email address in `Env.adminUser` (which is a@a.se)
4. Open your browser dev tools console. You should see an 8 digit login code. Type that in.
5. You're logged in!

After you've finished a feature, make sure to run elm-review and elm-test!

## How do I run the rust server locally? (for file hosting and Discord integration)

Run `npm run rust-server` in the root folder

## How do I deploy the rust server? (this is just for me to remember, you don't have access to do this)

1. Push your changes to master
2. Make sure you're on the Linux computer, doesn't work on Mac for some reason
3. In the lamdera/runtime repo in the nixos folder run `nix flake lock --update-input at-chat`
4. In the lamdera/runtime repo in the scripts folder run `DEBUG=1 ./lxelm.sh updateServerEnterprise martin-s`