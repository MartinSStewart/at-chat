module Evergreen.V315.Sticker exposing (..)

import Evergreen.V315.Coord
import Evergreen.V315.CssPixels
import Evergreen.V315.Discord
import Evergreen.V315.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V315.FileStatus.FileHash (Maybe (Evergreen.V315.Coord.Coord Evergreen.V315.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V315.Discord.Id Evergreen.V315.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V315.Discord.StickerFormatType
    }
