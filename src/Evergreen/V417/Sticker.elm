module Evergreen.V417.Sticker exposing (..)

import Evergreen.V417.Coord
import Evergreen.V417.CssPixels
import Evergreen.V417.Discord
import Evergreen.V417.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V417.FileStatus.FileHash (Maybe (Evergreen.V417.Coord.Coord Evergreen.V417.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V417.Discord.Id Evergreen.V417.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V417.Discord.StickerFormatType
    }
