module Evergreen.V273.Sticker exposing (..)

import Evergreen.V273.Coord
import Evergreen.V273.CssPixels
import Evergreen.V273.Discord
import Evergreen.V273.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V273.FileStatus.FileHash (Maybe (Evergreen.V273.Coord.Coord Evergreen.V273.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V273.Discord.Id Evergreen.V273.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V273.Discord.StickerFormatType
    }
