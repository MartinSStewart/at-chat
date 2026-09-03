module Evergreen.V367.Sticker exposing (..)

import Evergreen.V367.Coord
import Evergreen.V367.CssPixels
import Evergreen.V367.Discord
import Evergreen.V367.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V367.FileStatus.FileHash (Maybe (Evergreen.V367.Coord.Coord Evergreen.V367.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V367.Discord.Id Evergreen.V367.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V367.Discord.StickerFormatType
    }
