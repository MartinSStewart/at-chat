module Evergreen.V336.Sticker exposing (..)

import Evergreen.V336.Coord
import Evergreen.V336.CssPixels
import Evergreen.V336.Discord
import Evergreen.V336.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V336.FileStatus.FileHash (Maybe (Evergreen.V336.Coord.Coord Evergreen.V336.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V336.Discord.Id Evergreen.V336.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V336.Discord.StickerFormatType
    }
