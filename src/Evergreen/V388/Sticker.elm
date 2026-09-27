module Evergreen.V388.Sticker exposing (..)

import Evergreen.V388.Coord
import Evergreen.V388.CssPixels
import Evergreen.V388.Discord
import Evergreen.V388.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V388.FileStatus.FileHash (Maybe (Evergreen.V388.Coord.Coord Evergreen.V388.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V388.Discord.Id Evergreen.V388.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V388.Discord.StickerFormatType
    }
