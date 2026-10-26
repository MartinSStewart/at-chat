module Evergreen.V414.Sticker exposing (..)

import Evergreen.V414.Coord
import Evergreen.V414.CssPixels
import Evergreen.V414.Discord
import Evergreen.V414.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V414.FileStatus.FileHash (Maybe (Evergreen.V414.Coord.Coord Evergreen.V414.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V414.Discord.Id Evergreen.V414.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V414.Discord.StickerFormatType
    }
