module Evergreen.V375.Sticker exposing (..)

import Evergreen.V375.Coord
import Evergreen.V375.CssPixels
import Evergreen.V375.Discord
import Evergreen.V375.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V375.FileStatus.FileHash (Maybe (Evergreen.V375.Coord.Coord Evergreen.V375.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V375.Discord.Id Evergreen.V375.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V375.Discord.StickerFormatType
    }
