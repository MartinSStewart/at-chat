module Evergreen.V301.Sticker exposing (..)

import Evergreen.V301.Coord
import Evergreen.V301.CssPixels
import Evergreen.V301.Discord
import Evergreen.V301.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V301.FileStatus.FileHash (Maybe (Evergreen.V301.Coord.Coord Evergreen.V301.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V301.Discord.Id Evergreen.V301.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V301.Discord.StickerFormatType
    }
