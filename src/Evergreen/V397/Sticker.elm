module Evergreen.V397.Sticker exposing (..)

import Evergreen.V397.Coord
import Evergreen.V397.CssPixels
import Evergreen.V397.Discord
import Evergreen.V397.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V397.FileStatus.FileHash (Maybe (Evergreen.V397.Coord.Coord Evergreen.V397.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V397.Discord.Id Evergreen.V397.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V397.Discord.StickerFormatType
    }
