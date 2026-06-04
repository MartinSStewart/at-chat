module Evergreen.V271.Sticker exposing (..)

import Evergreen.V271.Coord
import Evergreen.V271.CssPixels
import Evergreen.V271.Discord
import Evergreen.V271.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V271.FileStatus.FileHash (Maybe (Evergreen.V271.Coord.Coord Evergreen.V271.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V271.Discord.Id Evergreen.V271.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V271.Discord.StickerFormatType
    }
