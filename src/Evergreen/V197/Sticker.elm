module Evergreen.V197.Sticker exposing (..)

import Evergreen.V197.Coord
import Evergreen.V197.CssPixels
import Evergreen.V197.Discord
import Evergreen.V197.FileStatus


type StickerUrl
    = StickerInternal Evergreen.V197.FileStatus.FileHash (Maybe (Evergreen.V197.Coord.Coord Evergreen.V197.CssPixels.CssPixels))
    | DiscordStandardSticker (Evergreen.V197.Discord.Id Evergreen.V197.Discord.StickerId)
    | StickerLoading


type alias StickerData =
    { url : StickerUrl
    , name : String
    , format : Evergreen.V197.Discord.StickerFormatType
    }
