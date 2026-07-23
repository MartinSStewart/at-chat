module Evergreen.V334.Sticker exposing (..)

import Evergreen.V334.Coord
import Evergreen.V334.CssPixels
import Evergreen.V334.Discord
import Evergreen.V334.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V334.FileStatus.FileHash (Maybe (Evergreen.V334.Coord.Coord Evergreen.V334.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V334.Discord.Id Evergreen.V334.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V334.Discord.StickerFormatType
    }
