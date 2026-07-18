module Evergreen.V328.Sticker exposing (..)

import Evergreen.V328.Coord
import Evergreen.V328.CssPixels
import Evergreen.V328.Discord
import Evergreen.V328.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V328.FileStatus.FileHash (Maybe (Evergreen.V328.Coord.Coord Evergreen.V328.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V328.Discord.Id Evergreen.V328.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V328.Discord.StickerFormatType
    }
