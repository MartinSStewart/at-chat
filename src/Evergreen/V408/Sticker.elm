module Evergreen.V408.Sticker exposing (..)

import Evergreen.V408.Coord
import Evergreen.V408.CssPixels
import Evergreen.V408.Discord
import Evergreen.V408.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V408.FileStatus.FileHash (Maybe (Evergreen.V408.Coord.Coord Evergreen.V408.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V408.Discord.Id Evergreen.V408.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V408.Discord.StickerFormatType
    }
