module Evergreen.V382.Sticker exposing (..)

import Evergreen.V382.Coord
import Evergreen.V382.CssPixels
import Evergreen.V382.Discord
import Evergreen.V382.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V382.FileStatus.FileHash (Maybe (Evergreen.V382.Coord.Coord Evergreen.V382.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V382.Discord.Id Evergreen.V382.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V382.Discord.StickerFormatType
    }
