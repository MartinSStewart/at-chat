module Evergreen.V343.Sticker exposing (..)

import Evergreen.V343.Coord
import Evergreen.V343.CssPixels
import Evergreen.V343.Discord
import Evergreen.V343.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V343.FileStatus.FileHash (Maybe (Evergreen.V343.Coord.Coord Evergreen.V343.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V343.Discord.Id Evergreen.V343.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V343.Discord.StickerFormatType
    }
