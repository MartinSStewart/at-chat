module CustomEmoji exposing
    ( CustomEmojiData
    , CustomEmojiUrl(..)
    , EmojiName(..)
    , addUrl
    , copyableView
    , copyableViewWithTooltip
    , emojiNameFromString
    , emojiNameToString
    , idToString
    , view
    , viewHelper
    )

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import FileStatus exposing (FileHash)
import Html exposing (Html)
import Html.Attributes
import Id exposing (CustomEmojiId, Id)
import MyUi
import SeqDict exposing (SeqDict)
import Sticker


type CustomEmojiUrl
    = CustomEmojiInternal FileHash (Maybe (Coord CssPixels))
    | CustomEmojiLoading


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : EmojiName
    , isAnimated : Bool
    }


{-| OpaqueVariants
-}
type EmojiName
    = EmojiName String


emojiNameFromString : String -> Result () EmojiName
emojiNameFromString text =
    if String.length text >= 2 && String.length text <= 32 && String.all (\char -> Char.isAlphaNum char || char == '_') text then
        Ok (EmojiName text)

    else
        Err ()


emojiNameToString : EmojiName -> String
emojiNameToString (EmojiName a) =
    a


addUrl : FileStatus.UploadResponse -> CustomEmojiData -> Result () CustomEmojiData
addUrl uploadResponse customEmoji =
    case customEmoji.url of
        CustomEmojiLoading ->
            { customEmoji | url = CustomEmojiInternal uploadResponse.fileHash (Maybe.map .imageSize uploadResponse.imageMetadata) }
                |> Ok

        CustomEmojiInternal _ _ ->
            Err ()


view : String -> String -> Id CustomEmojiId -> SeqDict (Id CustomEmojiId) CustomEmojiData -> Sticker.AnimationMode -> Html msg
view emojiSize yOffset customEmojiId customEmojis2 animationMode =
    case SeqDict.get customEmojiId customEmojis2 of
        Just customEmoji ->
            viewHelper emojiSize yOffset customEmoji animationMode

        Nothing ->
            placeholder emojiSize yOffset


placeholder : String -> String -> Html msg
placeholder emojiSize yOffset =
    Html.div
        [ Html.Attributes.style "width" emojiSize
        , Html.Attributes.style "height" emojiSize
        , Html.Attributes.style "display" "inline-block"
        , Html.Attributes.style "background-color" "gray"
        , Html.Attributes.style "transform" ("translate(" ++ yOffset ++ ")")
        ]
        []


{-| Same as `view`, but the emoji's characters sit under the image, filling the room it
takes, so that dragging across it in a message selects them and copying gives them back.
Pasting them into a message turns them into the emoji again. Works like
`Twemoji.spriteView`, and shares its `emoji-characters` rules in `MyUi.css`.
-}
copyableView : String -> String -> Id CustomEmojiId -> SeqDict (Id CustomEmojiId) CustomEmojiData -> Sticker.AnimationMode -> Html msg
copyableView emojiSize yOffset customEmojiId customEmojis2 animationMode =
    Html.span
        [ Html.Attributes.style "position" "relative"
        , Html.Attributes.style "display" "inline-block"
        ]
        [ copyableCharacters emojiSize customEmojiId
        , imageOverCharacters (view emojiSize yOffset customEmojiId customEmojis2 animationMode)
        ]


{-| Same as `copyableView` but hovering over the emoji reveals a popup containing a large
version of the emoji and its name. This is the same idea as the popup shown when
hovering over a reaction emoji, and shares the `emoji-popup` rules in `MyUi.css`
that do the hovering.
-}
copyableViewWithTooltip : String -> String -> Id CustomEmojiId -> SeqDict (Id CustomEmojiId) CustomEmojiData -> Sticker.AnimationMode -> Html msg
copyableViewWithTooltip emojiSize yOffset customEmojiId customEmojis2 animationMode =
    case SeqDict.get customEmojiId customEmojis2 of
        Just customEmoji ->
            Html.span
                [ Html.Attributes.class "emoji-popup-container"
                , Html.Attributes.style "position" "relative"
                , Html.Attributes.style "display" "inline-block"
                ]
                [ copyableCharacters emojiSize customEmojiId
                , imageOverCharacters (viewHelper emojiSize yOffset customEmoji animationMode)
                , tooltipView customEmoji
                , tooltipArrow
                ]

        Nothing ->
            copyableView emojiSize yOffset customEmojiId customEmojis2 animationMode


{-| Clipped on their own rather than by the emoji's container, which would clip the
tooltip too.
-}
copyableCharacters : String -> Id CustomEmojiId -> Html msg
copyableCharacters emojiSize customEmojiId =
    Html.span
        [ Html.Attributes.class "emoji-characters"
        , Html.Attributes.style "display" "inline-block"
        , Html.Attributes.style "width" emojiSize
        , Html.Attributes.style "height" emojiSize
        , Html.Attributes.style "line-height" emojiSize
        , Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "overflow" "hidden"
        ]
        [ Html.text (idToString customEmojiId) ]


{-| Lets the mouse through to the characters underneath, since a drag that starts on an
image selects nothing.
-}
imageOverCharacters : Html msg -> Html msg
imageOverCharacters image =
    Html.span
        [ Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "left" "0"
        , Html.Attributes.style "top" "0"
        , Html.Attributes.style "pointer-events" "none"
        ]
        [ image ]


{-| Where the tooltip sits, and whether it is shown at all, is left to the
`emoji-popup` and `custom-emoji-popup` rules in `MyUi.css`. Placement has to live
there because an inline style would beat the stylesheet, and the stylesheet is what
slides the tooltip back on screen when the emoji is near the edge of the window.
-}
tooltipView : CustomEmojiData -> Html msg
tooltipView customEmoji =
    Html.div
        [ Html.Attributes.class "emoji-popup custom-emoji-popup"
        , Html.Attributes.style "align-items" "center"
        , Html.Attributes.style "gap" "8px"
        , Html.Attributes.style "padding" "8px"
        , Html.Attributes.style "border-radius" "8px"
        , Html.Attributes.style "border" ("1px solid " ++ MyUi.colorToStyle MyUi.border1)
        , Html.Attributes.style "background-color" (MyUi.colorToStyle MyUi.background1)
        , Html.Attributes.style "box-shadow" "0 2px 8px rgba(0,0,0,0.3)"
        , Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font1)
        , Html.Attributes.style "font-size" "14px"
        , Html.Attributes.style "font-weight" "700"
        , Html.Attributes.style "line-height" "normal"
        , Html.Attributes.style "white-space" "nowrap"
        , Html.Attributes.style "pointer-events" "none"

        -- Same z-index elm-ui gives to `Ui.above`, which is what the reaction emoji popup uses
        , Html.Attributes.style "z-index" "20"
        ]
        [ viewHelper "40px" "0" customEmoji Sticker.LoopForever
        , Html.text (":" ++ emojiNameToString customEmoji.name ++ ":")
        ]


{-| A sibling of the tooltip rather than a child of it, so that it stays pointing at
the emoji when the tooltip slides sideways to stay on screen. It sits one pixel into
the tooltip to cover the piece of border it points at.
-}
tooltipArrow : Html msg
tooltipArrow =
    Html.div
        [ Html.Attributes.class "custom-emoji-popup-arrow"
        , Html.Attributes.style "border-left" "8px solid transparent"
        , Html.Attributes.style "border-right" "8px solid transparent"
        , Html.Attributes.style "border-top" ("8px solid " ++ MyUi.colorToStyle MyUi.background1)
        , -- One above the tooltip's own z-index, so it covers that border rather than
          -- being painted under it
          Html.Attributes.style "z-index" "21"
        ]
        []


viewHelper : String -> String -> { a | url : CustomEmojiUrl, isAnimated : Bool } -> Sticker.AnimationMode -> Html msg
viewHelper emojiSize yOffset customEmoji animationMode =
    case customEmoji.url of
        CustomEmojiLoading ->
            Html.div
                [ Html.Attributes.style "width" emojiSize
                , Html.Attributes.style "height" emojiSize
                , Html.Attributes.style "background-color" "gray"
                , Html.Attributes.style "display" "inline-block"
                , Html.Attributes.style "transform" ("translate(" ++ yOffset ++ ")")
                ]
                []

        CustomEmojiInternal fileHash _ ->
            if customEmoji.isAnimated then
                Sticker.animatedImageView
                    True
                    emojiSize
                    emojiSize
                    (Just yOffset)
                    (FileStatus.fileUrl FileStatus.gifContent fileHash)
                    animationMode

            else
                Html.img
                    [ Html.Attributes.style "width" emojiSize
                    , Html.Attributes.style "height" emojiSize
                    , Html.Attributes.src (FileStatus.fileUrl FileStatus.pngContent fileHash)
                    , MyUi.lazyLoading
                    , Html.Attributes.style "display" "inline-block"
                    , Html.Attributes.style "transform" ("translateY(" ++ yOffset ++ ")")
                    ]
                    []


idToString : Id CustomEmojiId -> String
idToString id =
    "❓" ++ Sticker.toBase4 (Id.toInt id) ++ "\u{FEFF}"
