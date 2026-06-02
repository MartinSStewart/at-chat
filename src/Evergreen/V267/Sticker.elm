module Evergreen.V267.Sticker exposing (..)

import Evergreen.V267.Coord
import Evergreen.V267.CssPixels
import Evergreen.V267.Discord
import Evergreen.V267.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V267.FileStatus.FileHash (Maybe (Evergreen.V267.Coord.Coord Evergreen.V267.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V267.Discord.Id Evergreen.V267.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V267.Discord.StickerFormatType
    }
