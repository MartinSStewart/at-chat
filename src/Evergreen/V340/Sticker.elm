module Evergreen.V340.Sticker exposing (..)

import Evergreen.V340.Coord
import Evergreen.V340.CssPixels
import Evergreen.V340.Discord
import Evergreen.V340.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V340.FileStatus.FileHash (Maybe (Evergreen.V340.Coord.Coord Evergreen.V340.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V340.Discord.Id Evergreen.V340.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V340.Discord.StickerFormatType
    }
