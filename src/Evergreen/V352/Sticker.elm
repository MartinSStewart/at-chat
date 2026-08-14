module Evergreen.V352.Sticker exposing (..)

import Evergreen.V352.Coord
import Evergreen.V352.CssPixels
import Evergreen.V352.Discord
import Evergreen.V352.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V352.FileStatus.FileHash (Maybe (Evergreen.V352.Coord.Coord Evergreen.V352.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V352.Discord.Id Evergreen.V352.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V352.Discord.StickerFormatType
    }
