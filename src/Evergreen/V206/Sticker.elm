module Evergreen.V206.Sticker exposing (..)

import Evergreen.V206.Coord
import Evergreen.V206.CssPixels
import Evergreen.V206.Discord
import Evergreen.V206.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V206.FileStatus.FileHash (Maybe (Evergreen.V206.Coord.Coord Evergreen.V206.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V206.Discord.Id Evergreen.V206.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V206.Discord.StickerFormatType
    }
