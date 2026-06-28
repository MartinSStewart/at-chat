module Evergreen.V296.Sticker exposing (..)

import Evergreen.V296.Coord
import Evergreen.V296.CssPixels
import Evergreen.V296.Discord
import Evergreen.V296.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V296.FileStatus.FileHash (Maybe (Evergreen.V296.Coord.Coord Evergreen.V296.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V296.Discord.Id Evergreen.V296.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V296.Discord.StickerFormatType
    }
