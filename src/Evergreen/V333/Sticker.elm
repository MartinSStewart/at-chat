module Evergreen.V333.Sticker exposing (..)

import Evergreen.V333.Coord
import Evergreen.V333.CssPixels
import Evergreen.V333.Discord
import Evergreen.V333.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V333.FileStatus.FileHash (Maybe (Evergreen.V333.Coord.Coord Evergreen.V333.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V333.Discord.Id Evergreen.V333.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V333.Discord.StickerFormatType
    }
