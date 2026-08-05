module Evergreen.V345.Sticker exposing (..)

import Evergreen.V345.Coord
import Evergreen.V345.CssPixels
import Evergreen.V345.Discord
import Evergreen.V345.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V345.FileStatus.FileHash (Maybe (Evergreen.V345.Coord.Coord Evergreen.V345.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V345.Discord.Id Evergreen.V345.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V345.Discord.StickerFormatType
    }
