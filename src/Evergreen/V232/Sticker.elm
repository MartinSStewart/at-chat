module Evergreen.V232.Sticker exposing (..)

import Evergreen.V232.Coord
import Evergreen.V232.CssPixels
import Evergreen.V232.Discord
import Evergreen.V232.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V232.FileStatus.FileHash (Maybe (Evergreen.V232.Coord.Coord Evergreen.V232.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V232.Discord.Id Evergreen.V232.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V232.Discord.StickerFormatType
    }
