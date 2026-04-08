module Sticker exposing (AnimationMode(..), StickerData, StickerUrl(..), addUrl, animatedImageView, idToString, view)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord exposing (StickerFormatType)
import FileStatus exposing (FileHash)
import Html exposing (Html)
import Html.Attributes
import Id exposing (Id, StickerId)
import SeqDict exposing (SeqDict)


type StickerUrl
    = StickerInternal FileHash (Maybe (Coord CssPixels))
    | -- For copyright reasons we don't want to store the actual images for Discord's standard stickers on our server
      DiscordStandardSticker (Discord.Id Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : StickerFormatType
    }


type AnimationMode
    = LoopAFewTimesOnLoad
    | ResetAndLoopAFewTimes
    | LoopForever


addUrl : FileStatus.UploadResponse -> StickerData -> StickerData
addUrl uploadResponse sticker =
    case sticker.url of
        StickerLoading ->
            { sticker | url = StickerInternal uploadResponse.fileHash (Maybe.map .imageSize uploadResponse.imageSize) }

        StickerInternal _ _ ->
            sticker

        DiscordStandardSticker _ ->
            sticker


view : String -> Id StickerId -> SeqDict (Id StickerId) StickerData -> AnimationMode -> Html msg
view stickerSize2 stickerId stickers2 animationMode =
    case SeqDict.get stickerId stickers2 of
        Just sticker ->
            case sticker.url of
                StickerLoading ->
                    Html.div
                        [ Html.Attributes.style "width" stickerSize2
                        , Html.Attributes.style "height" stickerSize2
                        , Html.Attributes.style "background-color" "gray"
                        , Html.Attributes.style "display" "block"
                        ]
                        []

                StickerInternal fileHash _ ->
                    case sticker.format of
                        Discord.PngFormat ->
                            Html.img
                                [ Html.Attributes.style "width" stickerSize2
                                , Html.Attributes.style "height" stickerSize2
                                , Html.Attributes.src (FileStatus.fileUrl FileStatus.pngContent fileHash)
                                , Html.Attributes.style "display" "block"
                                ]
                                []

                        Discord.ApngFormat ->
                            animatedImageView
                                stickerSize2
                                stickerSize2
                                (FileStatus.fileUrl FileStatus.pngContent fileHash)
                                animationMode

                        Discord.LottieFormat ->
                            lottieView stickerSize2 (FileStatus.fileUrl FileStatus.jsonContent fileHash) animationMode

                        Discord.GifFormat ->
                            animatedImageView
                                stickerSize2
                                stickerSize2
                                (FileStatus.fileUrl FileStatus.gifContent fileHash)
                                animationMode

                DiscordStandardSticker discordStickerId ->
                    case sticker.format of
                        Discord.LottieFormat ->
                            lottieView stickerSize2 (FileStatus.discordStickerUrl discordStickerId) animationMode

                        _ ->
                            animatedImageView
                                stickerSize2
                                stickerSize2
                                (Discord.stickerUrl Discord.StandardSticker sticker.format discordStickerId)
                                animationMode

        Nothing ->
            Html.div
                [ Html.Attributes.style "width" stickerSize2
                , Html.Attributes.style "height" stickerSize2
                , Html.Attributes.style "background-color" "gray"
                ]
                [ Html.text "Sticker failed to load" ]


animationModeToInt : AnimationMode -> String
animationModeToInt animationMode =
    case animationMode of
        LoopAFewTimesOnLoad ->
            "0"

        ResetAndLoopAFewTimes ->
            "1"

        LoopForever ->
            "2"


animatedImageView : String -> String -> String -> AnimationMode -> Html msg
animatedImageView width height url animationMode =
    Html.node
        "animated-image-player"
        [ Html.Attributes.style "width" width
        , Html.Attributes.style "height" height
        , Html.Attributes.attribute "src" url
        , Html.Attributes.style "display" "block"
        , Html.Attributes.attribute "start-playing" (animationModeToInt animationMode)
        ]
        []


lottieView : String -> String -> AnimationMode -> Html msg
lottieView stickerSize2 url animationMode =
    Html.node
        "lottie-player"
        [ Html.Attributes.style "width" stickerSize2
        , Html.Attributes.style "height" stickerSize2
        , Html.Attributes.style "display" "inline-block"
        , Html.Attributes.attribute "src" url
        , Html.Attributes.attribute "start-playing" (animationModeToInt animationMode)
        ]
        []


idToString : Id StickerId -> String
idToString id =
    "\n" ++ toBase4 (Id.toInt id) ++ "\n\n"


toBase4 : Int -> String
toBase4 n =
    if n < 0 then
        "-" ++ toBase4 (abs n)

    else if n < 4 then
        toBase4Helper n

    else
        toBase4 (n // 4) ++ toBase4Helper (remainderBy 4 n)


toBase4Helper : Int -> String
toBase4Helper int =
    case int of
        0 ->
            "\u{200B}"

        1 ->
            "\u{200C}"

        2 ->
            "\u{200D}"

        _ ->
            "\u{2060}"
