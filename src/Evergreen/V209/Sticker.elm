module Evergreen.V209.Sticker exposing (..)

import Evergreen.V209.Coord
import Evergreen.V209.CssPixels
import Evergreen.V209.Discord
import Evergreen.V209.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V209.FileStatus.FileHash (Maybe (Evergreen.V209.Coord.Coord Evergreen.V209.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V209.Discord.Id Evergreen.V209.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V209.Discord.StickerFormatType
    }
