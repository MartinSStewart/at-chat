module Evergreen.V228.Sticker exposing (..)

import Evergreen.V228.Coord
import Evergreen.V228.CssPixels
import Evergreen.V228.Discord
import Evergreen.V228.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V228.FileStatus.FileHash (Maybe (Evergreen.V228.Coord.Coord Evergreen.V228.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V228.Discord.Id Evergreen.V228.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V228.Discord.StickerFormatType
    }
