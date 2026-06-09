module Evergreen.V283.Sticker exposing (..)

import Evergreen.V283.Coord
import Evergreen.V283.CssPixels
import Evergreen.V283.Discord
import Evergreen.V283.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V283.FileStatus.FileHash (Maybe (Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V283.Discord.Id Evergreen.V283.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V283.Discord.StickerFormatType
    }
