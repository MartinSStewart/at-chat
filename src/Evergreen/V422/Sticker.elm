module Evergreen.V422.Sticker exposing (..)

import Evergreen.V422.Coord
import Evergreen.V422.CssPixels
import Evergreen.V422.Discord
import Evergreen.V422.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V422.FileStatus.FileHash (Maybe (Evergreen.V422.Coord.Coord Evergreen.V422.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V422.Discord.Id Evergreen.V422.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V422.Discord.StickerFormatType
    }
