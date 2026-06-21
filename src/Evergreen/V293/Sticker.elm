module Evergreen.V293.Sticker exposing (..)

import Evergreen.V293.Coord
import Evergreen.V293.CssPixels
import Evergreen.V293.Discord
import Evergreen.V293.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V293.FileStatus.FileHash (Maybe (Evergreen.V293.Coord.Coord Evergreen.V293.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V293.Discord.Id Evergreen.V293.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V293.Discord.StickerFormatType
    }
