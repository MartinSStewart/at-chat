* Fix ping user dropdown appearing too low on mobile
* Typing indicator not appearing for Discord guilds
* Changing tabs and then returning to a channel causes it to unload all old messages
* Two messages get sent if a linked Discord user starts a thread
* 4 Discord messages DM restriction is not being checked
* Finding an emoji via text search and then trying to click it fails on mobile
* Push notification sent even when viewing DM channel
* Login/signup button doesn't work if failed to link Discord message is visible
* Prevent files larger than 10mb being attached to Discord messages (unless it's a nitro user)
* Make it more clear when a message hasn't been sent yet
* Message stickers and message custom emojis gets added to a user's available emojis on the frontend when it shouldn't
  do that
* Video call preview not closed when leaving channel on mobile
* Messages disappear for one user (are still sent but vanishing locally). This is happening when backups are created.
  Need to make backups lock up server less
* Fix BrowserDomNotFound error in program-test that's breaking the zoom-in part of the "Draw on top of messages" test
* Some Discord stickers width /= height but the current sticker view assumes width == height
* Video nodes need to have a fixed height to prevent layout thrashing
* If someone links their Discord account, when the linking finishes, show all the accounts they are a part of, not just
  all the ones that loaded (some might already be loaded)
* Add support for Discord roles
* Unlinking a Discord account causes "Something went wrong" to appear in the direct message list
* Track frequent emojis in messages and sort :emoji: autocompletes based on frequency
* Show a Discord icon above guild and users

Requested features:

* Add one-time view images