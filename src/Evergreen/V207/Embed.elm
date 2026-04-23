module Evergreen.V207.Embed exposing (..)

import Effect.Time
import Evergreen.V207.Coord
import Evergreen.V207.CssPixels


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
    , imageSize : Evergreen.V207.Coord.Coord Evergreen.V207.CssPixels.CssPixels
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
