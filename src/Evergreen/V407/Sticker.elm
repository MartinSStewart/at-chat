module Evergreen.V407.Sticker exposing (..)

import Evergreen.V407.Coord
import Evergreen.V407.CssPixels
import Evergreen.V407.Discord
import Evergreen.V407.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V407.FileStatus.FileHash (Maybe (Evergreen.V407.Coord.Coord Evergreen.V407.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V407.Discord.Id Evergreen.V407.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V407.Discord.StickerFormatType
    }
