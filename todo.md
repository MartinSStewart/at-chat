* Fix ping user dropdown appearing too low on mobile
* Typing indicator not appearing for Discord guilds (won't do, due to server overhead or added complexity of
  managing individual Discord guild subscriptions)
* Login/signup button doesn't work if failed to link Discord message is visible
* Prevent files larger than 10mb being attached to Discord messages (unless it's a nitro user)
* Make it more clear when a message hasn't been sent yet
* Messages disappear for one user (are still sent but vanishing locally). This is happening when backups are created.
  Need to make backups lock up server less
* Some Discord stickers width /= height but the current sticker view assumes width == height
* If someone links their Discord account, when the linking finishes, show all the accounts they are a part of, not just
  all the ones that loaded (some might already be loaded)
* Unlinking a Discord account causes "Something went wrong" to appear in the direct message list
* I played a premove and it failed and when I looked at the board, the premoved letters had switched (the word itself
  was invalid so it's unclear if the letter switch is just a visual bug).
  Update: it seems like this might be caused by premoving, switching to another device and doing another turn, and then
  switching back, since the original device has it's own state that still has the tiles place on the board
* Installing app to macbook desktop and then clicking on a notification causes it to open a new tab in safari
* Adding images to an existing Discord message doesn't work
* A message in a Discord thread didn't show a white dot on the guild until after I refreshed the page
* Two messages get sent and it seems to happen for Discord and normal users. In the latest case, it was in a DM and the
  user saw duplicated messages for both themselves and the other user.
* Scroll down warning is shown on iphone in DMs when the user is already scrolled down and writes a message.
* Emoji in reaction emoji tooltip gets horizontally swished if there are many names (maybe MyUi.noShrinking is needed)
* Modify pushRoute to require the caller to specify if this was triggered by a user click (for purposes of set viewing)
* "add to home screen" is called "install and create shortcut" on Android (Chrome)
* Clicking/pressing outside of an image (when viewing it in the image viewer) should close it
* Add unread overview to mobile

Requested features:

* Add one-time view images