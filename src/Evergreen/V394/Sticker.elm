module Evergreen.V394.Sticker exposing (..)

import Evergreen.V394.Coord
import Evergreen.V394.CssPixels
import Evergreen.V394.Discord
import Evergreen.V394.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V394.FileStatus.FileHash (Maybe (Evergreen.V394.Coord.Coord Evergreen.V394.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V394.Discord.Id Evergreen.V394.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V394.Discord.StickerFormatType
    }
