module Evergreen.V342.Sticker exposing (..)

import Evergreen.V342.Coord
import Evergreen.V342.CssPixels
import Evergreen.V342.Discord
import Evergreen.V342.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V342.FileStatus.FileHash (Maybe (Evergreen.V342.Coord.Coord Evergreen.V342.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V342.Discord.Id Evergreen.V342.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V342.Discord.StickerFormatType
    }
