module Evergreen.V312.Sticker exposing (..)

import Evergreen.V312.Coord
import Evergreen.V312.CssPixels
import Evergreen.V312.Discord
import Evergreen.V312.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V312.FileStatus.FileHash (Maybe (Evergreen.V312.Coord.Coord Evergreen.V312.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V312.Discord.Id Evergreen.V312.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V312.Discord.StickerFormatType
    }
