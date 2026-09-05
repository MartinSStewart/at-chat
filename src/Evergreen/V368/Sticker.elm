module Evergreen.V368.Sticker exposing (..)

import Evergreen.V368.Coord
import Evergreen.V368.CssPixels
import Evergreen.V368.Discord
import Evergreen.V368.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V368.FileStatus.FileHash (Maybe (Evergreen.V368.Coord.Coord Evergreen.V368.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V368.Discord.Id Evergreen.V368.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V368.Discord.StickerFormatType
    }
