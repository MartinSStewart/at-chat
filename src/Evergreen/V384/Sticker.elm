module Evergreen.V384.Sticker exposing (..)

import Evergreen.V384.Coord
import Evergreen.V384.CssPixels
import Evergreen.V384.Discord
import Evergreen.V384.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V384.FileStatus.FileHash (Maybe (Evergreen.V384.Coord.Coord Evergreen.V384.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V384.Discord.Id Evergreen.V384.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V384.Discord.StickerFormatType
    }
