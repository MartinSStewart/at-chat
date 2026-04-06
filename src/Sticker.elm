module Sticker exposing (StickerData, StickerUrl(..), addUrl)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord exposing (StickerFormatType)
import Effect.Command exposing (BackendOnly)
import Effect.Http as Http
import Effect.Task as Task exposing (Task)
import FileStatus exposing (FileHash)
import Id exposing (Id, StickerId)
import OneToOne exposing (OneToOne)
import SeqDict exposing (SeqDict)
import Url exposing (Url)


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


addUrl : FileStatus.UploadResponse -> StickerData -> StickerData
addUrl uploadResponse sticker =
    case sticker.url of
        StickerLoading ->
            { sticker
                | url =
                    StickerInternal
                        uploadResponse.fileHash
                        (Maybe.map .imageSize uploadResponse.imageSize)
            }

        StickerInternal fileHash _ ->
            sticker

        DiscordStandardSticker _ ->
            sticker
