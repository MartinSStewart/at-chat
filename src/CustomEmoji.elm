module CustomEmoji exposing
    ( CustomEmojiData
    , CustomEmojiUrl(..)
    , EmojiName
    , addUrl
    , emojiNameFromString
    , emojiNameToString
    , idToString
    , view
    )

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
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
    , name : EmojiName
    , isAnimated : Bool
    }


{-| OpaqueVariants
-}
type EmojiName
    = EmojiName String


emojiNameFromString : String -> Result () EmojiName
emojiNameFromString text =
    if String.length text >= 2 && String.length text < 32 then
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
            { customEmoji | url = CustomEmojiInternal uploadResponse.fileHash (Maybe.map .imageSize uploadResponse.imageSize) }
                |> Ok

        CustomEmojiInternal _ _ ->
            Err ()


view : String -> String -> Id CustomEmojiId -> SeqDict (Id CustomEmojiId) CustomEmojiData -> Sticker.AnimationMode -> Html msg
view emojiSize yOffset customEmojiId customEmojis2 animationMode =
    case SeqDict.get customEmojiId customEmojis2 of
        Just customEmoji ->
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
                            , Html.Attributes.style "display" "inline-block"
                            , Html.Attributes.style "transform" ("translateY(" ++ yOffset ++ ")")
                            ]
                            []

        Nothing ->
            Html.div
                [ Html.Attributes.style "width" emojiSize
                , Html.Attributes.style "height" emojiSize
                , Html.Attributes.style "background-color" "gray"
                , Html.Attributes.style "transform" ("translate(" ++ yOffset ++ ")")
                ]
                [ Html.text "Custom emoji failed to load" ]


idToString : Id CustomEmojiId -> String
idToString id =
    "❓" ++ Sticker.toBase4 (Id.toInt id) ++ "\u{FEFF}"
