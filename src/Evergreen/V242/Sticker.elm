module Evergreen.V242.Sticker exposing (..)

import Evergreen.V242.Coord
import Evergreen.V242.CssPixels
import Evergreen.V242.Discord
import Evergreen.V242.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V242.FileStatus.FileHash (Maybe (Evergreen.V242.Coord.Coord Evergreen.V242.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V242.Discord.Id Evergreen.V242.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V242.Discord.StickerFormatType
    }
