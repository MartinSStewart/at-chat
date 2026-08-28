module Evergreen.V364.Sticker exposing (..)

import Evergreen.V364.Coord
import Evergreen.V364.CssPixels
import Evergreen.V364.Discord
import Evergreen.V364.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V364.FileStatus.FileHash (Maybe (Evergreen.V364.Coord.Coord Evergreen.V364.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V364.Discord.Id Evergreen.V364.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V364.Discord.StickerFormatType
    }
