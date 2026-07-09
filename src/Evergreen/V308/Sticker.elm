module Evergreen.V308.Sticker exposing (..)

import Evergreen.V308.Coord
import Evergreen.V308.CssPixels
import Evergreen.V308.Discord
import Evergreen.V308.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V308.FileStatus.FileHash (Maybe (Evergreen.V308.Coord.Coord Evergreen.V308.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V308.Discord.Id Evergreen.V308.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V308.Discord.StickerFormatType
    }
