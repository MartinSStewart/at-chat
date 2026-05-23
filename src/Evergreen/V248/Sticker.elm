module Evergreen.V248.Sticker exposing (..)

import Evergreen.V248.Coord
import Evergreen.V248.CssPixels
import Evergreen.V248.Discord
import Evergreen.V248.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V248.FileStatus.FileHash (Maybe (Evergreen.V248.Coord.Coord Evergreen.V248.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V248.Discord.Id Evergreen.V248.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V248.Discord.StickerFormatType
    }
