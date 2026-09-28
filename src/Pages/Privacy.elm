module Pages.Privacy exposing (repoUrl, view)

import Array
import Effect.Browser.Dom as Dom
import Effect.Time as Time
import Env
import Html
import Html.Attributes
import RichText
import Route exposing (Overlay(..))
import SeqDict
import SeqSet
import Sticker exposing (AnimationMode(..))
import String.Nonempty exposing (NonemptyString(..))
import Ui
import User
import UserColor


repoUrl : String
repoUrl =
    "https://github.com/MartinSStewart/at-chat"


view : msg -> Ui.Element msg
view noOp =
    NonemptyString
        '#'
        (""" Privacy policy

## What is stored

at-chat stores the following sensitive data:
* Your email address
* Your name (should you choose to provide your real name)
* Any messages you write that contain sensitive data
* Any files you upload that contain sensitive data
* Should you choose to use the Discord integration:
      *-*  A session token with full access to your Discord account (the setup explains the risks in more detail)
      *-*  Your Discord account's email address
      *-*  Cached Discord messages and files

## What it is for

Sensitive data is stored in order to provide you chat app features. It is not used for marketing, advertising, AI training, and is not sold to 3rd parties.

Sensitive data may be used by an administrator for the sole purpose of fixing software issues within at-chat. If this is a concern, you can [enable end-to-end encryption]("""
            ++ Env.domain
            ++ Route.encode (Route.HomePageRoute (Just E2eeInfoOverlay))
            ++ """) on direct messages to restrict what is visible to an admin.

Sensitive data can be accessed by 3rd parties in the following ways:
* [Hetzner](https://www.hetzner.com/) owns the hardware at-chat runs on. The server being rented is located in Finland.
* If you use the Discord integration feature, then messages and files sent to a Discord guild or Discord user will of course be available to Discord.
* If someone you are writing to has enabled email notifications then your messages, profile image, and name will be sent to [Postmark](https://postmarkapp.com/) and that user's email provider.
* If you have message embeds enabled then the site serving that embedded image or video can potentially store your IP address

## When is it deleted

Your email address, name, messages, and Discord session tokens, will all be deleted when delete your account. Account deletion takes """
            ++ String.fromInt User.accountDeletionDelayInWeeks
            ++ """ weeks in order to give other users a chance to backup any conversations they want a personal copy of.

Uploaded files are deleted once they are no longer are attached to any messages. Note that this means if you attach a file to a message, and then someone duplicates your message, the file won't be deleted until both messages are deleted.

Backups of the server are generated regularly. These are stored for up to 30 days before being deleted.
"""
        )
        |> RichText.fromNonemptyString Time.utc SeqDict.empty SeqDict.empty
        |> RichText.view
            (Dom.id "privacy-page")
            1000
            (\_ -> noOp)
            (\_ -> noOp)
            (\_ -> noOp)
            { domainWhitelist = SeqSet.empty
            , revealedSpoilers = SeqSet.empty
            , users = SeqDict.empty
            , channels = SeqDict.empty
            , attachedFiles = SeqDict.empty
            , stickers = SeqDict.empty
            , customEmojis = SeqDict.empty
            , emojiData = Nothing
            , animationMode = LoopAFewTimesOnLoad
            , timezone = Time.utc
            , time = Time.millisToPosix 0
            , drawings = SeqDict.empty
            , embedDrawings = SeqDict.empty
            , drawingUserColor = \_ -> UserColor.default
            , isSelectingAnchor = False
            , devicePixelRatio = 1
            , isHovered = False
            }
            Array.empty
        |> Html.div [ Html.Attributes.style "white-space" "pre-wrap" ]
        |> Ui.html
