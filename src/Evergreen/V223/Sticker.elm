module Evergreen.V223.Sticker exposing (..)

import Evergreen.V223.Coord
import Evergreen.V223.CssPixels
import Evergreen.V223.Discord
import Evergreen.V223.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V223.FileStatus.FileHash (Maybe (Evergreen.V223.Coord.Coord Evergreen.V223.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V223.Discord.Id Evergreen.V223.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V223.Discord.StickerFormatType
    }
