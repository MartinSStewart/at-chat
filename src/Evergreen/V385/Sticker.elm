module Evergreen.V385.Sticker exposing (..)

import Evergreen.V385.Coord
import Evergreen.V385.CssPixels
import Evergreen.V385.Discord
import Evergreen.V385.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V385.FileStatus.FileHash (Maybe (Evergreen.V385.Coord.Coord Evergreen.V385.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V385.Discord.Id Evergreen.V385.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V385.Discord.StickerFormatType
    }
