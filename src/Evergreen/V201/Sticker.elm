module Evergreen.V201.Sticker exposing (..)

import Evergreen.V201.Coord
import Evergreen.V201.CssPixels
import Evergreen.V201.Discord
import Evergreen.V201.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V201.FileStatus.FileHash (Maybe (Evergreen.V201.Coord.Coord Evergreen.V201.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V201.Discord.Id Evergreen.V201.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V201.Discord.StickerFormatType
    }
