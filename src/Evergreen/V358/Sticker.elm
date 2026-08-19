module Evergreen.V358.Sticker exposing (..)

import Evergreen.V358.Coord
import Evergreen.V358.CssPixels
import Evergreen.V358.Discord
import Evergreen.V358.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V358.FileStatus.FileHash (Maybe (Evergreen.V358.Coord.Coord Evergreen.V358.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V358.Discord.Id Evergreen.V358.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V358.Discord.StickerFormatType
    }
