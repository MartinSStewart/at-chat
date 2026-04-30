module Evergreen.V211.Sticker exposing (..)

import Evergreen.V211.Coord
import Evergreen.V211.CssPixels
import Evergreen.V211.Discord
import Evergreen.V211.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V211.FileStatus.FileHash (Maybe (Evergreen.V211.Coord.Coord Evergreen.V211.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V211.Discord.Id Evergreen.V211.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V211.Discord.StickerFormatType
    }
