port module Ports exposing
    ( CropImageDataResponse
    , copyToClipboard
    , cropImageFromJs
    , cropImageToJs
    , textInputSelectAll
    )

import Codec exposing (Codec)
import CodecExtra
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Subscription as Subscription exposing (Subscription)
import Json.Decode
import Json.Encode
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)


port copy_to_clipboard_to_js : Json.Encode.Value -> Cmd msg


port text_input_select_all_to_js : Json.Encode.Value -> Cmd msg


textInputSelectAll : HtmlId -> Command FrontendOnly toMsg msg
textInputSelectAll htmlId =
    Dom.idToString htmlId
        |> Json.Encode.string
        |> Command.sendToJs "text_input_select_all_to_js" text_input_select_all_to_js


copyToClipboard : String -> Command FrontendOnly toMsg msg
copyToClipboard text =
    Command.sendToJs "copy_to_clipboard_to_js" copy_to_clipboard_to_js (Json.Encode.string text)


port martinsstewart_crop_image_to_js : Json.Encode.Value -> Cmd msg


port martinsstewart_crop_image_from_js : (Json.Decode.Value -> msg) -> Sub msg


cropImageToJsName : String
cropImageToJsName =
    "martinsstewart_crop_image_to_js"


type alias CropImageData =
    { requestId : Int
    , imageUrl : String
    , cropX : Quantity Int Pixels
    , cropY : Quantity Int Pixels
    , cropWidth : Quantity Int Pixels
    , cropHeight : Quantity Int Pixels
    , width : Quantity Int Pixels
    , height : Quantity Int Pixels
    }


cropImageToJs : CropImageData -> Command FrontendOnly toBackend msg
cropImageToJs data =
    Codec.encodeToValue cropImageDataCodec data
        |> Command.sendToJs cropImageToJsName martinsstewart_crop_image_to_js


cropImageFromJsName : String
cropImageFromJsName =
    "martinsstewart_crop_image_from_js"


cropImageFromJs : (Result String CropImageDataResponse -> msg) -> Subscription FrontendOnly msg
cropImageFromJs msg =
    Subscription.fromJs
        cropImageFromJsName
        martinsstewart_crop_image_from_js
        (\a ->
            Codec.decodeValue cropImageDataResponseCodec a
                |> Result.mapError Json.Decode.errorToString
                |> msg
        )


type alias CropImageDataResponse =
    { requestId : Int, croppedImageUrl : String }


cropImageDataResponseCodec : Codec CropImageDataResponse
cropImageDataResponseCodec =
    Codec.object CropImageDataResponse
        |> Codec.field "requestId" .requestId Codec.int
        |> Codec.field "croppedImageUrl" .croppedImageUrl Codec.string
        |> Codec.buildObject


cropImageDataCodec : Codec CropImageData
cropImageDataCodec =
    Codec.object CropImageData
        |> Codec.field "requestId" .requestId Codec.int
        |> Codec.field "imageUrl" .imageUrl Codec.string
        |> Codec.field "cropX" .cropX CodecExtra.quantityInt
        |> Codec.field "cropY" .cropY CodecExtra.quantityInt
        |> Codec.field "cropWidth" .cropWidth CodecExtra.quantityInt
        |> Codec.field "cropHeight" .cropHeight CodecExtra.quantityInt
        |> Codec.field "width" .width CodecExtra.quantityInt
        |> Codec.field "height" .height CodecExtra.quantityInt
        |> Codec.buildObject
