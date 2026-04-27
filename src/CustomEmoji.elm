module CustomEmoji exposing (CustomEmojiData, CustomEmojiUrl(..), addUrl, idToString, view)

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
    , animated : Bool
    }


addUrl : FileStatus.UploadResponse -> CustomEmojiData -> Result () CustomEmojiData
addUrl uploadResponse customEmoji =
    case customEmoji.url of
        CustomEmojiLoading ->
            { customEmoji | url = CustomEmojiInternal uploadResponse.fileHash (Maybe.map .imageSize uploadResponse.imageSize) }
                |> Ok

        CustomEmojiInternal _ _ ->
            Err ()


view : String -> Id CustomEmojiId -> SeqDict (Id CustomEmojiId) CustomEmojiData -> Sticker.AnimationMode -> Html msg
view emojiSize2 customEmojiId customEmojis2 animationMode =
    case SeqDict.get customEmojiId customEmojis2 of
        Just customEmoji ->
            case customEmoji.url of
                CustomEmojiLoading ->
                    Html.div
                        [ Html.Attributes.style "width" emojiSize2
                        , Html.Attributes.style "height" emojiSize2
                        , Html.Attributes.style "background-color" "gray"
                        , Html.Attributes.style "display" "inline-block"
                        ]
                        []

                CustomEmojiInternal fileHash _ ->
                    if customEmoji.animated then
                        Sticker.animatedImageView
                            emojiSize2
                            emojiSize2
                            (FileStatus.fileUrl FileStatus.gifContent fileHash)
                            animationMode

                    else
                        Html.img
                            [ Html.Attributes.style "width" emojiSize2
                            , Html.Attributes.style "height" emojiSize2
                            , Html.Attributes.src (FileStatus.fileUrl FileStatus.pngContent fileHash)
                            , Html.Attributes.style "display" "inline-block"
                            ]
                            []

        Nothing ->
            Html.div
                [ Html.Attributes.style "width" emojiSize2
                , Html.Attributes.style "height" emojiSize2
                , Html.Attributes.style "background-color" "gray"
                ]
                [ Html.text "Custom emoji failed to load" ]


idToString : Id CustomEmojiId -> String
idToString _ =
    Debug.todo ""
