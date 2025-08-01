port module Ports exposing
    ( CropImageData
    , CropImageDataResponse
    , NotificationPermission(..)
    , PwaStatus(..)
    , checkNotificationPermission
    , checkNotificationPermissionResponse
    , checkPwaStatus
    , checkPwaStatusResponse
    , copyToClipboard
    , cropImageFromJs
    , cropImageToJs
    , hapticFeedback
    , loadSounds
    , playSound
    , requestNotificationPermission
    , setFavicon
    , showNotification
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


port load_sounds_to_js : Json.Encode.Value -> Cmd msg


port play_sound : Json.Encode.Value -> Cmd msg


port copy_to_clipboard_to_js : Json.Encode.Value -> Cmd msg


port text_input_select_all_to_js : Json.Encode.Value -> Cmd msg


port show_notification : Json.Encode.Value -> Cmd msg


port check_notification_permission_to_js : Json.Encode.Value -> Cmd msg


port check_notification_permission_from_js : (Json.Encode.Value -> msg) -> Sub msg


port request_notification_permission : Json.Encode.Value -> Cmd msg


port check_pwa_status_to_js : Json.Encode.Value -> Cmd msg


port check_pwa_status_from_js : (Json.Encode.Value -> msg) -> Sub msg


port martinsstewart_set_favicon_to_js : Json.Encode.Value -> Cmd msg


port haptic_feedback : Json.Encode.Value -> Cmd msg


setFavicon : String -> Command FrontendOnly toMsg msg
setFavicon faviconPath =
    Command.sendToJs
        "martinsstewart_set_favicon_to_js"
        martinsstewart_set_favicon_to_js
        (Json.Encode.string faviconPath)


hapticFeedback : Command FrontendOnly toMsg msg
hapticFeedback =
    Command.sendToJs "haptic_feedback" haptic_feedback Json.Encode.null


requestNotificationPermission : Command FrontendOnly toMsg msg
requestNotificationPermission =
    Command.sendToJs "request_notification_permission" request_notification_permission Json.Encode.null


checkNotificationPermission : Command FrontendOnly toMsg msg
checkNotificationPermission =
    Command.sendToJs "check_notification_permission_to_js" check_notification_permission_to_js Json.Encode.null


type NotificationPermission
    = NotAsked
    | Denied
    | Granted
    | Unsupported


checkNotificationPermissionResponse : (NotificationPermission -> msg) -> Subscription FrontendOnly msg
checkNotificationPermissionResponse msg =
    Subscription.fromJs
        "check_notification_permission_from_js"
        check_notification_permission_from_js
        (\json ->
            Json.Decode.decodeValue
                (Json.Decode.map
                    (\text ->
                        case text of
                            "granted" ->
                                Granted

                            "denied" ->
                                Denied

                            "unsupported" ->
                                Unsupported

                            _ ->
                                NotAsked
                    )
                    Json.Decode.string
                )
                json
                |> Result.withDefault NotAsked
                |> msg
        )


type PwaStatus
    = InstalledPwa
    | BrowserView


checkPwaStatus : Command FrontendOnly toMsg msg
checkPwaStatus =
    Command.sendToJs "check_pwa_status_to_js" check_pwa_status_to_js Json.Encode.null


checkPwaStatusResponse : (PwaStatus -> msg) -> Subscription FrontendOnly msg
checkPwaStatusResponse msg =
    Subscription.fromJs
        "check_pwa_status_from_js"
        check_pwa_status_from_js
        (\json ->
            Json.Decode.decodeValue
                (Json.Decode.map
                    (\isPwa ->
                        if isPwa then
                            InstalledPwa

                        else
                            BrowserView
                    )
                    Json.Decode.bool
                )
                json
                |> Result.withDefault BrowserView
                |> msg
        )


showNotification : String -> String -> Command FrontendOnly toMsg msg
showNotification title body =
    Command.sendToJs
        "show_notification"
        show_notification
        (Json.Encode.object
            [ ( "title", Json.Encode.string title )
            , ( "body", Json.Encode.string body )
            ]
        )


loadSounds : Command FrontendOnly toMsg msg
loadSounds =
    Command.sendToJs "load_sounds_to_js" load_sounds_to_js Json.Encode.null


playSound : String -> Command FrontendOnly toMsg msg
playSound name =
    Command.sendToJs "play_sound" play_sound (Json.Encode.string name)


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
