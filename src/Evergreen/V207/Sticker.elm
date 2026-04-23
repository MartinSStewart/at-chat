module Evergreen.V207.Sticker exposing (..)

import Evergreen.V207.Coord
import Evergreen.V207.CssPixels
import Evergreen.V207.Discord
import Evergreen.V207.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V207.FileStatus.FileHash (Maybe (Evergreen.V207.Coord.Coord Evergreen.V207.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V207.Discord.Id Evergreen.V207.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V207.Discord.StickerFormatType
    }
