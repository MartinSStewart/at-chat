module Evergreen.V379.Sticker exposing (..)

import Evergreen.V379.Coord
import Evergreen.V379.CssPixels
import Evergreen.V379.Discord
import Evergreen.V379.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V379.FileStatus.FileHash (Maybe (Evergreen.V379.Coord.Coord Evergreen.V379.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V379.Discord.Id Evergreen.V379.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V379.Discord.StickerFormatType
    }
