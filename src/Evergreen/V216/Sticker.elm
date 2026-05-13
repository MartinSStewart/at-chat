module Evergreen.V216.Sticker exposing (..)

import Evergreen.V216.Coord
import Evergreen.V216.CssPixels
import Evergreen.V216.Discord
import Evergreen.V216.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V216.FileStatus.FileHash (Maybe (Evergreen.V216.Coord.Coord Evergreen.V216.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V216.Discord.Id Evergreen.V216.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V216.Discord.StickerFormatType
    }
