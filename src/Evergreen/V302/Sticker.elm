module Evergreen.V302.Sticker exposing (..)

import Evergreen.V302.Coord
import Evergreen.V302.CssPixels
import Evergreen.V302.Discord
import Evergreen.V302.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V302.FileStatus.FileHash (Maybe (Evergreen.V302.Coord.Coord Evergreen.V302.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V302.Discord.Id Evergreen.V302.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V302.Discord.StickerFormatType
    }
