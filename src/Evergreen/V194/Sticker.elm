module Evergreen.V194.Sticker exposing (..)

import Evergreen.V194.Coord
import Evergreen.V194.CssPixels
import Evergreen.V194.Discord
import Evergreen.V194.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V194.FileStatus.FileHash (Maybe (Evergreen.V194.Coord.Coord Evergreen.V194.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V194.Discord.Id Evergreen.V194.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V194.Discord.StickerFormatType
    }
