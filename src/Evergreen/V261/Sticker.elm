module Evergreen.V261.Sticker exposing (..)

import Evergreen.V261.Coord
import Evergreen.V261.CssPixels
import Evergreen.V261.Discord
import Evergreen.V261.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V261.FileStatus.FileHash (Maybe (Evergreen.V261.Coord.Coord Evergreen.V261.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V261.Discord.Id Evergreen.V261.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V261.Discord.StickerFormatType
    }
