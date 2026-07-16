module Evergreen.V326.Sticker exposing (..)

import Evergreen.V326.Coord
import Evergreen.V326.CssPixels
import Evergreen.V326.Discord
import Evergreen.V326.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V326.FileStatus.FileHash (Maybe (Evergreen.V326.Coord.Coord Evergreen.V326.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V326.Discord.Id Evergreen.V326.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V326.Discord.StickerFormatType
    }
