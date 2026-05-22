module Evergreen.V247.Sticker exposing (..)

import Evergreen.V247.Coord
import Evergreen.V247.CssPixels
import Evergreen.V247.Discord
import Evergreen.V247.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V247.FileStatus.FileHash (Maybe (Evergreen.V247.Coord.Coord Evergreen.V247.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V247.Discord.Id Evergreen.V247.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V247.Discord.StickerFormatType
    }
