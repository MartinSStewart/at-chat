module Evergreen.V305.Sticker exposing (..)

import Evergreen.V305.Coord
import Evergreen.V305.CssPixels
import Evergreen.V305.Discord
import Evergreen.V305.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V305.FileStatus.FileHash (Maybe (Evergreen.V305.Coord.Coord Evergreen.V305.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V305.Discord.Id Evergreen.V305.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V305.Discord.StickerFormatType
    }
