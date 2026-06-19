module Evergreen.V290.Sticker exposing (..)

import Evergreen.V290.Coord
import Evergreen.V290.CssPixels
import Evergreen.V290.Discord
import Evergreen.V290.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V290.FileStatus.FileHash (Maybe (Evergreen.V290.Coord.Coord Evergreen.V290.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V290.Discord.Id Evergreen.V290.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V290.Discord.StickerFormatType
    }
