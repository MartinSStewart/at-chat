module Evergreen.V253.Sticker exposing (..)

import Evergreen.V253.Coord
import Evergreen.V253.CssPixels
import Evergreen.V253.Discord
import Evergreen.V253.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V253.FileStatus.FileHash (Maybe (Evergreen.V253.Coord.Coord Evergreen.V253.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V253.Discord.Id Evergreen.V253.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V253.Discord.StickerFormatType
    }
