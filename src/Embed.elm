module Embed exposing (Embed(..), EmbedData, EmbedImageData, EmbedImageFormat(..), empty, request)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Command exposing (Command)
import Effect.Http as Http
import Effect.Time as Time
import FileStatus
import Json.Decode
import Json.Encode
import Url exposing (Url)


type Embed
    = EmbedLoading
    | EmbedLoaded EmbedData


empty : EmbedData
empty =
    { title = Nothing
    , image = Nothing
    , description = Nothing
    , createdAt = Nothing
    }


type alias EmbedData =
    { title : Maybe String
    , image : Maybe EmbedImageData
    , description : Maybe String
    , createdAt : Maybe Time.Posix
    }


type alias EmbedImageData =
    { url : String
    , imageSize : Coord CssPixels
    , format : Maybe EmbedImageFormat
    }


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


request : Url -> Command restriction toFrontend ( Url, Result Http.Error EmbedData )
request url =
    Http.post
        { url = FileStatus.domain ++ "/file/embed"
        , body = Json.Encode.object [ ( "url", Json.Encode.string (Url.toString url) ) ] |> Http.jsonBody
        , expect = Http.expectJson (Tuple.pair url) decodeEmbedData
        }


decodeEmbedData : Json.Decode.Decoder EmbedData
decodeEmbedData =
    Json.Decode.map4 EmbedData
        (Json.Decode.field "title" (Json.Decode.nullable Json.Decode.string))
        (Json.Decode.field "image" (Json.Decode.nullable decodeImageData))
        (Json.Decode.field "description" (Json.Decode.nullable Json.Decode.string))
        (Json.Decode.field "created_at" (Json.Decode.nullable decodeTime))


decodeTime : Json.Decode.Decoder Time.Posix
decodeTime =
    Json.Decode.map Time.millisToPosix Json.Decode.int


decodeImageData : Json.Decode.Decoder EmbedImageData
decodeImageData =
    Json.Decode.map4 (\url width height format -> EmbedImageData url (Coord.xy width height) format)
        (Json.Decode.field "url" Json.Decode.string)
        (Json.Decode.field "width" Json.Decode.int)
        (Json.Decode.field "height" Json.Decode.int)
        (Json.Decode.field "format" (Json.Decode.nullable decodeImageFormat))


decodeImageFormat : Json.Decode.Decoder EmbedImageFormat
decodeImageFormat =
    Json.Decode.string
        |> Json.Decode.andThen
            (\str ->
                case str of
                    "Png" ->
                        Json.Decode.succeed Png

                    "Jpeg" ->
                        Json.Decode.succeed Jpeg

                    "Gif" ->
                        Json.Decode.succeed Gif

                    "WebP" ->
                        Json.Decode.succeed WebP

                    "Pnm" ->
                        Json.Decode.succeed Pnm

                    "Tiff" ->
                        Json.Decode.succeed Tiff

                    "Tga" ->
                        Json.Decode.succeed Tga

                    "Dds" ->
                        Json.Decode.succeed Dds

                    "Bmp" ->
                        Json.Decode.succeed Bmp

                    "Ico" ->
                        Json.Decode.succeed Ico

                    "Hdr" ->
                        Json.Decode.succeed Hdr

                    "OpenExr" ->
                        Json.Decode.succeed OpenExr

                    "Farbfeld" ->
                        Json.Decode.succeed Farbfeld

                    "Avif" ->
                        Json.Decode.succeed Avif

                    "Qoi" ->
                        Json.Decode.succeed Qoi

                    _ ->
                        Json.Decode.fail ("Unknown image format: " ++ str)
            )
