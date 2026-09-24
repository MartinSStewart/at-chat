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
import UserColor


repoUrl : String
repoUrl =
    "https://github.com/MartinSStewart/at-chat"


view : msg -> Ui.Element msg
view noOp =
    NonemptyString
        '#'
        (""" Privacy

## What is stored

at-chat stores or has access to the following sensitive data:
* Your email address
* Your name (should you choose to provide your real name)
* Any messages you write that contain sensitive data
* Any files you upload that contain sensitive data
* A session token with full access to your Discord account should you choose to use the Discord integration (a comprehensive warning is shown before a user can link a Discord account so they understand the implications)

## What it is for

Sensitive data is stored in order to provide you features. It is not used for marketing, advertising, AI training, or sold to 3rd parties.

Sensitive data may be used by an administrator for the sole purpose of fixing software issues within at-chat. If this is a concern, you can [enable end-to-end encryption]("""
            ++ Env.domain
            ++ Route.encode (Route.HomePageRoute (Just E2eeInfoOverlay))
            ++ """) on direct messages to restrict what is visible to an admin.


Sensitive data is not accessible to any 3rd parties with 3 exceptions:
* [Hetzner](https://www.hetzner.com/) which owns the hardware at-chat runs on. The server being rented is located in Finland.
* If you use the Discord integration, then messages and files sent to a Discord guild or Discord user will of course be available to Discord.
* If someone you are writing to has enabled email notifications then your messages, profile image, and name will be sent to their email provider.

## When is it deleted

<WIP>
"""
        )
        |> RichText.fromNonemptyString Time.utc SeqDict.empty
        |> RichText.view
            (Dom.id "privacy-page")
            1000
            (\_ -> noOp)
            (\_ -> noOp)
            (\_ -> noOp)
            { domainWhitelist = SeqSet.empty
            , revealedSpoilers = SeqSet.empty
            , users = SeqDict.empty
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
        |> Ui.el [ Ui.centerX, Ui.widthMax 1000, Ui.paddingXY 16 32 ]
