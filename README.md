# Template project

This is a template designed to get you started more quickly with your Lamdera app. It is a stripped down version of the code used for [Ambue](https://ambue.com/) (speaking of which, thank you Ambue for letting me share this code!)

The template includes:
* A single sign-on based login system
* Optional authenticator based 2FA
* An admin page for adding new users or modifying existing users (there is no sign-up UI for now)
* A user overview page where a user can change how often they get notifications (which doesn't do anything as there are no notifications) and UI for setting up 2FA
* An end-to-end test suite (to view it, start `lamdera live` and then go to `http://localhost:8000/end-to-end-tests/EndToEndTests.elm`)
* Email system for login emails and email sent to the admin if a serious error is logged. This uses Postmark but you don't need to worry about setting it up while running this website locally.

There's also code in this template that probably doesn't make sense for your project (or make sense in general) such as `Local.elm` and `LocalState.elm`*

*They let me manage shared state between multiple clients without having to worry about race conditions, but it probably isn't obvious how to use them.

## How do I login in development?

1. Start `lamdera live`
2. Click the login button on the homepage
3. Enter the email address in `Backend.adminUser` (which is sven@email.com)
4. Open your browser dev tools console. You should see an 8 digit login code. Type that in.
5. You're logged in!