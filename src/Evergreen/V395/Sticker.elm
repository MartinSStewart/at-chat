module Evergreen.V395.Sticker exposing (..)

import Evergreen.V395.Coord
import Evergreen.V395.CssPixels
import Evergreen.V395.Discord
import Evergreen.V395.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V395.FileStatus.FileHash (Maybe (Evergreen.V395.Coord.Coord Evergreen.V395.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V395.Discord.Id Evergreen.V395.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V395.Discord.StickerFormatType
    }
