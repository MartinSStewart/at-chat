module Evergreen.V298.Embed exposing (..)

import Effect.Time
import Evergreen.V298.Coord
import Evergreen.V298.CssPixels


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
    , imageSize : Evergreen.V298.Coord.Coord Evergreen.V298.CssPixels.CssPixels
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
