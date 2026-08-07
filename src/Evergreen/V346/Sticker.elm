module Evergreen.V346.Sticker exposing (..)

import Evergreen.V346.Coord
import Evergreen.V346.CssPixels
import Evergreen.V346.Discord
import Evergreen.V346.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V346.FileStatus.FileHash (Maybe (Evergreen.V346.Coord.Coord Evergreen.V346.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V346.Discord.Id Evergreen.V346.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V346.Discord.StickerFormatType
    }
