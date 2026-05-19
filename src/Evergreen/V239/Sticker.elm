module Evergreen.V239.Sticker exposing (..)

import Evergreen.V239.Coord
import Evergreen.V239.CssPixels
import Evergreen.V239.Discord
import Evergreen.V239.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V239.FileStatus.FileHash (Maybe (Evergreen.V239.Coord.Coord Evergreen.V239.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V239.Discord.Id Evergreen.V239.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V239.Discord.StickerFormatType
    }
