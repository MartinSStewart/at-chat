module Evergreen.V250.Sticker exposing (..)

import Evergreen.V250.Coord
import Evergreen.V250.CssPixels
import Evergreen.V250.Discord
import Evergreen.V250.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V250.FileStatus.FileHash (Maybe (Evergreen.V250.Coord.Coord Evergreen.V250.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V250.Discord.Id Evergreen.V250.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V250.Discord.StickerFormatType
    }
