module Evergreen.V294.Sticker exposing (..)

import Evergreen.V294.Coord
import Evergreen.V294.CssPixels
import Evergreen.V294.Discord
import Evergreen.V294.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V294.FileStatus.FileHash (Maybe (Evergreen.V294.Coord.Coord Evergreen.V294.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V294.Discord.Id Evergreen.V294.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V294.Discord.StickerFormatType
    }
