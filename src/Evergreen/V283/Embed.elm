module Evergreen.V283.Embed exposing (..)

import Effect.Time
import Evergreen.V283.Coord
import Evergreen.V283.CssPixels


type EmbedImageFormat
    = Png
    | Jpeg
    | Gif
    | WebP
    | Pnm
    | Tiff
    | Tga
    | Dds
    | Bmp
    | Ico
    | Hdr
    | OpenExr
    | Farbfeld
    | Avif
    | Qoi


type alias EmbedImageData =
    { url : String
    , imageSize : Evergreen.V283.Coord.Coord Evergreen.V283.CssPixels.CssPixels
    , format : Maybe EmbedImageFormat
    }


type alias EmbedData =
    { title : Maybe String
    , image : Maybe EmbedImageData
    , description : Maybe String
    , createdAt : Maybe Effect.Time.Posix
    }


type Embed
    = EmbedLoading
    | EmbedLoaded EmbedData
