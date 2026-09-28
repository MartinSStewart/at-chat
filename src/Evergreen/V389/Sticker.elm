module Evergreen.V389.Sticker exposing (..)

import Evergreen.V389.Coord
import Evergreen.V389.CssPixels
import Evergreen.V389.Discord
import Evergreen.V389.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V389.FileStatus.FileHash (Maybe (Evergreen.V389.Coord.Coord Evergreen.V389.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V389.Discord.Id Evergreen.V389.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V389.Discord.StickerFormatType
    }
