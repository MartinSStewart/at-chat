module Evergreen.V383.Sticker exposing (..)

import Evergreen.V383.Coord
import Evergreen.V383.CssPixels
import Evergreen.V383.Discord
import Evergreen.V383.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V383.FileStatus.FileHash (Maybe (Evergreen.V383.Coord.Coord Evergreen.V383.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V383.Discord.Id Evergreen.V383.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V383.Discord.StickerFormatType
    }
