module Evergreen.V236.Sticker exposing (..)

import Evergreen.V236.Coord
import Evergreen.V236.CssPixels
import Evergreen.V236.Discord
import Evergreen.V236.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V236.FileStatus.FileHash (Maybe (Evergreen.V236.Coord.Coord Evergreen.V236.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V236.Discord.Id Evergreen.V236.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V236.Discord.StickerFormatType
    }
