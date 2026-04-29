* Fix Discord messages getting double sent. Probably caused by channels containing more than one linked user
* Fix ping user dropdown appearing too low on mobile
* Typing indicator not appearing for Discord guilds
* Changing tabs and then returning to a channel causes it to unload all old messages
* Two messages get sent if a linked Discord user starts a thread
* 4 Discord messages DM restriction not removed until after the page is refreshed
* Prevent messages longer than 2000 chars from being sent
* Finding an emoji via text search and then trying to click it fails on mobile
* Push notification sent even when viewing DM channel
* Login/signup button doesn't work if failed to link Discord message is visible
* Prevent files larger than 10mb being attached to Discord messages (unless it's a nitro user)
* Make it more clear when a message hasn't been sent yet
* https://blog.x-way.org/Webdesign/2024/08/03/Increase-emoji-size-with-CSS-only.html Try this trick to make emojis
  larger
* Don't send message while attachments are still loading
* Undo is triggered as an intermediate step when removing a sticker. If a user was typing and then quickly backspaced
  the sticker then the undo undoes their typing as well

Requested features:

* Add one-time view images