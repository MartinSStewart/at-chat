module Evergreen.V347.Sticker exposing (..)

import Evergreen.V347.Coord
import Evergreen.V347.CssPixels
import Evergreen.V347.Discord
import Evergreen.V347.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V347.FileStatus.FileHash (Maybe (Evergreen.V347.Coord.Coord Evergreen.V347.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V347.Discord.Id Evergreen.V347.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V347.Discord.StickerFormatType
    }
