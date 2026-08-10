module Evergreen.V349.Sticker exposing (..)

import Evergreen.V349.Coord
import Evergreen.V349.CssPixels
import Evergreen.V349.Discord
import Evergreen.V349.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V349.FileStatus.FileHash (Maybe (Evergreen.V349.Coord.Coord Evergreen.V349.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V349.Discord.Id Evergreen.V349.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V349.Discord.StickerFormatType
    }
