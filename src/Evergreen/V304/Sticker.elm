module Evergreen.V304.Sticker exposing (..)

import Evergreen.V304.Coord
import Evergreen.V304.CssPixels
import Evergreen.V304.Discord
import Evergreen.V304.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V304.FileStatus.FileHash (Maybe (Evergreen.V304.Coord.Coord Evergreen.V304.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V304.Discord.Id Evergreen.V304.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V304.Discord.StickerFormatType
    }
