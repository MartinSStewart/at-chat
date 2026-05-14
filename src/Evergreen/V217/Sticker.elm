module Evergreen.V217.Sticker exposing (..)

import Evergreen.V217.Coord
import Evergreen.V217.CssPixels
import Evergreen.V217.Discord
import Evergreen.V217.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V217.FileStatus.FileHash (Maybe (Evergreen.V217.Coord.Coord Evergreen.V217.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V217.Discord.Id Evergreen.V217.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V217.Discord.StickerFormatType
    }
