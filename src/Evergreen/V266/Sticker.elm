module Evergreen.V266.Sticker exposing (..)

import Evergreen.V266.Coord
import Evergreen.V266.CssPixels
import Evergreen.V266.Discord
import Evergreen.V266.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V266.FileStatus.FileHash (Maybe (Evergreen.V266.Coord.Coord Evergreen.V266.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V266.Discord.Id Evergreen.V266.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V266.Discord.StickerFormatType
    }
