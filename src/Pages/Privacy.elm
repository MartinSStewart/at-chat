module Pages.Privacy exposing (repoUrl, view)

import Array
import Effect.Browser.Dom as Dom
import Effect.Time as Time
import Html
import Html.Attributes
import RichText
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
        """ Privacy
"""
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
