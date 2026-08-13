module Evergreen.V351.Sticker exposing (..)

import Evergreen.V351.Coord
import Evergreen.V351.CssPixels
import Evergreen.V351.Discord
import Evergreen.V351.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V351.FileStatus.FileHash (Maybe (Evergreen.V351.Coord.Coord Evergreen.V351.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V351.Discord.Id Evergreen.V351.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V351.Discord.StickerFormatType
    }
