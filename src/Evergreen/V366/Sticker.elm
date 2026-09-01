module Evergreen.V366.Sticker exposing (..)

import Evergreen.V366.Coord
import Evergreen.V366.CssPixels
import Evergreen.V366.Discord
import Evergreen.V366.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V366.FileStatus.FileHash (Maybe (Evergreen.V366.Coord.Coord Evergreen.V366.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V366.Discord.Id Evergreen.V366.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V366.Discord.StickerFormatType
    }
