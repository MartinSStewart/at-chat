module Evergreen.V193.Sticker exposing (..)

import Evergreen.V193.Coord
import Evergreen.V193.CssPixels
import Evergreen.V193.Discord
import Evergreen.V193.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V193.FileStatus.FileHash (Maybe (Evergreen.V193.Coord.Coord Evergreen.V193.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V193.Discord.Id Evergreen.V193.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V193.Discord.StickerFormatType
    }
