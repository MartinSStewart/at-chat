module Evergreen.V289.Sticker exposing (..)

import Evergreen.V289.Coord
import Evergreen.V289.CssPixels
import Evergreen.V289.Discord
import Evergreen.V289.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V289.FileStatus.FileHash (Maybe (Evergreen.V289.Coord.Coord Evergreen.V289.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V289.Discord.Id Evergreen.V289.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V289.Discord.StickerFormatType
    }
