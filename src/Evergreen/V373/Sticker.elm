module Evergreen.V373.Sticker exposing (..)

import Evergreen.V373.Coord
import Evergreen.V373.CssPixels
import Evergreen.V373.Discord
import Evergreen.V373.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V373.FileStatus.FileHash (Maybe (Evergreen.V373.Coord.Coord Evergreen.V373.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V373.Discord.Id Evergreen.V373.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V373.Discord.StickerFormatType
    }
