module Evergreen.V387.Sticker exposing (..)

import Evergreen.V387.Coord
import Evergreen.V387.CssPixels
import Evergreen.V387.Discord
import Evergreen.V387.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V387.FileStatus.FileHash (Maybe (Evergreen.V387.Coord.Coord Evergreen.V387.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V387.Discord.Id Evergreen.V387.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V387.Discord.StickerFormatType
    }
