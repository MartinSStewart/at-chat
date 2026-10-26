module Evergreen.V412.Sticker exposing (..)

import Evergreen.V412.Coord
import Evergreen.V412.CssPixels
import Evergreen.V412.Discord
import Evergreen.V412.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V412.FileStatus.FileHash (Maybe (Evergreen.V412.Coord.Coord Evergreen.V412.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V412.Discord.Id Evergreen.V412.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V412.Discord.StickerFormatType
    }
