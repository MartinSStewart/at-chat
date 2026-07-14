module Evergreen.V319.Sticker exposing (..)

import Evergreen.V319.Coord
import Evergreen.V319.CssPixels
import Evergreen.V319.Discord
import Evergreen.V319.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V319.FileStatus.FileHash (Maybe (Evergreen.V319.Coord.Coord Evergreen.V319.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V319.Discord.Id Evergreen.V319.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V319.Discord.StickerFormatType
    }
