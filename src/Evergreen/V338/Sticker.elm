module Evergreen.V338.Sticker exposing (..)

import Evergreen.V338.Coord
import Evergreen.V338.CssPixels
import Evergreen.V338.Discord
import Evergreen.V338.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V338.FileStatus.FileHash (Maybe (Evergreen.V338.Coord.Coord Evergreen.V338.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V338.Discord.Id Evergreen.V338.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V338.Discord.StickerFormatType
    }
