module Evergreen.V363.Sticker exposing (..)

import Evergreen.V363.Coord
import Evergreen.V363.CssPixels
import Evergreen.V363.Discord
import Evergreen.V363.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V363.FileStatus.FileHash (Maybe (Evergreen.V363.Coord.Coord Evergreen.V363.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V363.Discord.Id Evergreen.V363.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V363.Discord.StickerFormatType
    }
