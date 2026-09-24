# [at-chat](https://at-chat.app/)

A text chat app similar to Discord

## How do I login in development?

1. Download the lamdera executable here https://dashboard.lamdera.app/docs/download and place it on your PATH
2. Start `lamdera live`
3. Click the login button on the homepage
4. Enter the email address in `Backend.adminUser` (which is a@a.aa)
5. Open your browser dev tools console. You should see an 8 digit login code (the console might be a bit noisy, filter
   for "login" and you should see it). Type that in.
6. You're logged in!

## How do I run the rust server locally? (for file hosting and Discord integration)

Run `npm run rust-server` in the root folder. Make sure you
have [Rust installed first](https://rust-lang.org/tools/install/)

## How do I deploy the rust server? (this is just for me to remember, you don't have access to do this)

1. Push your changes to master
2. Make sure you're on the Linux computer, doesn't work on Mac for some reason
3. In the lamdera/runtime repo in the nixos folder run `nix flake lock --update-input at-chat`
4. In the lamdera/runtime repo in the scripts folder run `DEBUG=1 ./lxelm.sh updateServerEnterprise martin-s`