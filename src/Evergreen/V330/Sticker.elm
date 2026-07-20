module Evergreen.V330.Sticker exposing (..)

import Evergreen.V330.Coord
import Evergreen.V330.CssPixels
import Evergreen.V330.Discord
import Evergreen.V330.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V330.FileStatus.FileHash (Maybe (Evergreen.V330.Coord.Coord Evergreen.V330.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V330.Discord.Id Evergreen.V330.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V330.Discord.StickerFormatType
    }
