module Evergreen.V254.Sticker exposing (..)

import Evergreen.V254.Coord
import Evergreen.V254.CssPixels
import Evergreen.V254.Discord
import Evergreen.V254.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V254.FileStatus.FileHash (Maybe (Evergreen.V254.Coord.Coord Evergreen.V254.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V254.Discord.Id Evergreen.V254.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V254.Discord.StickerFormatType
    }
