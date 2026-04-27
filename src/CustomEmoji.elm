module CustomEmoji exposing
    ( CustomEmojiData
    , CustomEmojiUrl(..)
    , addUrl
    , emojiSize
    , idToString
    , view
    )

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord
import FileStatus exposing (FileHash)
import Html exposing (Html)
import Html.Attributes
import Id exposing (CustomEmojiId, Id)
import SeqDict exposing (SeqDict)
import Sticker


type CustomEmojiUrl
    = CustomEmojiInternal FileHash (Maybe (Coord CssPixels))
    | CustomEmojiLoading


type alias CustomEmojiData =
    { url : CustomEmojiUrl
    , name : String
    , isAnimated : Bool
    }


addUrl : FileStatus.UploadResponse -> CustomEmojiData -> Result () CustomEmojiData
addUrl uploadResponse customEmoji =
    case customEmoji.url of
        CustomEmojiLoading ->
            { customEmoji | url = CustomEmojiInternal uploadResponse.fileHash (Maybe.map .imageSize uploadResponse.imageSize) }
                |> Ok

        CustomEmojiInternal _ _ ->
            Err ()


emojiSize : String
emojiSize =
    "1em"


view : Id CustomEmojiId -> SeqDict (Id CustomEmojiId) CustomEmojiData -> Sticker.AnimationMode -> Html msg
view customEmojiId customEmojis2 animationMode =
    case SeqDict.get customEmojiId customEmojis2 of
        Just customEmoji ->
            case customEmoji.url of
                CustomEmojiLoading ->
                    Html.div
                        [ Html.Attributes.style "width" emojiSize
                        , Html.Attributes.style "height" emojiSize
                        , Html.Attributes.style "background-color" "gray"
                        , Html.Attributes.style "display" "inline-block"
                        ]
                        []

                CustomEmojiInternal fileHash _ ->
                    if customEmoji.isAnimated then
                        Sticker.animatedImageView
                            emojiSize
                            emojiSize
                            (FileStatus.fileUrl FileStatus.gifContent fileHash)
                            animationMode

                    else
                        Html.img
                            [ Html.Attributes.style "width" emojiSize
                            , Html.Attributes.style "height" emojiSize
                            , Html.Attributes.src (FileStatus.fileUrl FileStatus.pngContent fileHash)
                            , Html.Attributes.style "display" "inline-block"
                            ]
                            []

        Nothing ->
            Html.div
                [ Html.Attributes.style "width" emojiSize
                , Html.Attributes.style "height" emojiSize
                , Html.Attributes.style "background-color" "gray"
                ]
                [ Html.text "Custom emoji failed to load" ]


idToString : Id CustomEmojiId -> String
idToString id =
    "❓" ++ Sticker.toBase4 (Id.toInt id)
