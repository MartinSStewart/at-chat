module Evergreen.V229.Sticker exposing (..)

import Evergreen.V229.Coord
import Evergreen.V229.CssPixels
import Evergreen.V229.Discord
import Evergreen.V229.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V229.FileStatus.FileHash (Maybe (Evergreen.V229.Coord.Coord Evergreen.V229.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V229.Discord.Id Evergreen.V229.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V229.Discord.StickerFormatType
    }
