module Evergreen.V295.Sticker exposing (..)

import Evergreen.V295.Coord
import Evergreen.V295.CssPixels
import Evergreen.V295.Discord
import Evergreen.V295.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V295.FileStatus.FileHash (Maybe (Evergreen.V295.Coord.Coord Evergreen.V295.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V295.Discord.Id Evergreen.V295.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V295.Discord.StickerFormatType
    }
