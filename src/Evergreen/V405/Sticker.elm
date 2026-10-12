module Evergreen.V405.Sticker exposing (..)

import Evergreen.V405.Coord
import Evergreen.V405.CssPixels
import Evergreen.V405.Discord
import Evergreen.V405.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V405.FileStatus.FileHash (Maybe (Evergreen.V405.Coord.Coord Evergreen.V405.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V405.Discord.Id Evergreen.V405.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V405.Discord.StickerFormatType
    }
