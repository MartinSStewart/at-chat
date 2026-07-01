port module Ports exposing
    ( CropImageData
    , CropImageDataResponse
    , ExecCommand(..)
    , ExecCommandPort
    , NotificationPermission(..)
    , PwaStatus(..)
    , RegisterPushSubscription(..)
    , StartupData
    , SubscribeData
    , SubscribeKeys
    , audioPortFromJS
    , audioPortToJS
    , checkNotificationPermissionResponse
    , closeNotifications
    , copyImageToClipboard
    , copyToClipboard
    , cropImageFromJs
    , cropImageToJs
    , execCommand
    , fixCursorPosition
    , focusChanged
    , hapticFeedback
    , loadServiceWorkerData
    , loadSounds
    , loadStartupData
    , pageHasFocus
    , playSound
    , registerPushSubscription
    , registerPushSubscriptionToJs
    , registerServiceWorker
    , requestNotificationPermission
    , selectionChanged
    , serviceWorkerData
    , serviceWorkerMessage
    , setCursorPosition
    , setFavicon
    , shiftScrollByElementDelta
    , showNotification
    , smoothScrollBy
    , startupDataSub
    , subscribeDataCodec
    , textInputSelectAll
    , unregisterServiceWorker
    , visualViewportResized
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
import Range exposing (Range, SelectionDirection(..))
import Time
import Url exposing (Url)
import UserAgent exposing (UserAgent)


port audioPortToJS : Json.Encode.Value -> Cmd msg


port audioPortFromJS : (Json.Decode.Value -> msg) -> Sub msg


port exec_command_to_js : Json.Encode.Value -> Cmd msg


port load_sounds_to_js : Json.Encode.Value -> Cmd msg


port play_sound : Json.Encode.Value -> Cmd msg


port copy_to_clipboard_to_js : Json.Encode.Value -> Cmd msg


port copy_image_to_clipboard_to_js : Json.Encode.Value -> Cmd msg


port text_input_select_all_to_js : Json.Encode.Value -> Cmd msg


port show_notification : Json.Encode.Value -> Cmd msg


port check_notification_permission_from_js : (Json.Encode.Value -> msg) -> Sub msg


port request_notification_permission : Json.Encode.Value -> Cmd msg


port martinsstewart_set_favicon_to_js : Json.Encode.Value -> Cmd msg


port haptic_feedback : Json.Encode.Value -> Cmd msg


port load_startup_data_to_js : Json.Encode.Value -> Cmd msg


port load_startup_data_from_js : (Json.Decode.Value -> msg) -> Sub msg


port register_service_worker_to_js : Json.Encode.Value -> Cmd msg


port fix_cursor_position_to_js : Json.Encode.Value -> Cmd msg


port selection_changed_from_js : (Json.Encode.Value -> msg) -> Sub msg


port focus_changed_from_js : (Json.Encode.Value -> msg) -> Sub msg


focusChanged : (( Maybe HtmlId, Maybe ( Range, SelectionDirection ) ) -> msg) -> Subscription FrontendOnly msg
focusChanged msg =
    Subscription.fromJs
        "focus_changed_from_js"
        focus_changed_from_js
        (\json ->
            Json.Decode.decodeValue decodeHtmlIdAndSelection json |> Result.withDefault ( Nothing, Nothing ) |> msg
        )


selectionChanged : (( Maybe HtmlId, Maybe ( Range, SelectionDirection ) ) -> msg) -> Subscription FrontendOnly msg
selectionChanged msg =
    Subscription.fromJs
        "selection_changed_from_js"
        selection_changed_from_js
        (\json ->
            Json.Decode.decodeValue decodeHtmlIdAndSelection json |> Result.withDefault ( Nothing, Nothing ) |> msg
        )


decodeHtmlIdAndSelection : Json.Decode.Decoder ( Maybe HtmlId, Maybe ( Range, SelectionDirection ) )
decodeHtmlIdAndSelection =
    Json.Decode.oneOf
        [ Json.Decode.map4
            (\id start end direction ->
                ( id
                , Just
                    ( { start = start, end = end }
                    , if direction == "forward" then
                        SelectForward

                      else
                        SelectBackward
                    )
                )
            )
            (Json.Decode.field "id" (Json.Decode.nullable decodeDomId))
            (Json.Decode.field "selectionStart" Json.Decode.int)
            (Json.Decode.field "selectionEnd" Json.Decode.int)
            (Json.Decode.field "selectionDirection" Json.Decode.string)
        , Json.Decode.map
            (\id -> ( id, Nothing ))
            (Json.Decode.field "id" (Json.Decode.nullable decodeDomId))
        ]


decodeDomId : Json.Decode.Decoder HtmlId
decodeDomId =
    Json.Decode.map Dom.id Json.Decode.string


execCommand : ExecCommandPort -> Command FrontendOnly toMsg msg
execCommand data =
    Command.sendToJs "exec_command_to_js" exec_command_to_js (Codec.encodeToValue execCommandPortCodec data)


type alias ExecCommandPort =
    { htmlId : HtmlId
    , commands : List ExecCommand
    }


type ExecCommand
    = InsertText String Range
    | Undo
    | SelectRange Range SelectionDirection


execCommandPortCodec : Codec ExecCommandPort
execCommandPortCodec =
    Codec.object ExecCommandPort
        |> Codec.field "htmlId" .htmlId CodecExtra.htmlId
        |> Codec.field "commands" .commands (Codec.list execCommandCodec)
        |> Codec.buildObject


execCommandCodec : Codec ExecCommand
execCommandCodec =
    Codec.custom
        (\insertTextEncoder undoEncoder selectRangeEncoder value ->
            case value of
                InsertText argA argB ->
                    insertTextEncoder argA argB

                Undo ->
                    undoEncoder

                SelectRange argA argB ->
                    selectRangeEncoder argA argB
        )
        |> Codec.variant2 "insertText" InsertText Codec.string Range.codec
        |> Codec.variant0 "undo" Undo
        |> Codec.variant2 "selectRange" SelectRange Range.codec Range.selectionDirectionCodec
        |> Codec.buildCustom


fixCursorPosition : HtmlId -> Command FrontendOnly toMsg msg
fixCursorPosition htmlId =
    Command.sendToJs "fix_cursor_position_to_js" fix_cursor_position_to_js (Json.Encode.string (Dom.idToString htmlId))


registerServiceWorker : Command FrontendOnly toMsg msg
registerServiceWorker =
    Command.sendToJs "register_service_worker_to_js" register_service_worker_to_js Json.Encode.null


port unregister_service_worker_to_js : Json.Encode.Value -> Cmd msg


unregisterServiceWorker : Command FrontendOnly toMsg msg
unregisterServiceWorker =
    Command.sendToJs "unregister_service_worker_to_js" unregister_service_worker_to_js Json.Encode.null


port load_service_worker_data_to_js : Json.Encode.Value -> Cmd msg


port load_service_worker_data_from_js : (Json.Decode.Value -> msg) -> Sub msg


loadServiceWorkerData : Command FrontendOnly toMsg msg
loadServiceWorkerData =
    Command.sendToJs "load_service_worker_data_to_js" load_service_worker_data_to_js Json.Encode.null


serviceWorkerData : (String -> msg) -> Subscription FrontendOnly msg
serviceWorkerData msg =
    Subscription.fromJs
        "load_service_worker_data_from_js"
        load_service_worker_data_from_js
        (\json ->
            Json.Decode.decodeValue Json.Decode.string json
                |> Result.withDefault ""
                |> msg
        )


{-| Data loaded from JS once at app startup. `timeOrigin` is `performance.timeOrigin`, needed to convert event timeStamps (which are milliseconds since timeOrigin) into a Time.Posix.
-}
type alias StartupData =
    { timeOrigin : Time.Posix
    , userAgent : UserAgent
    , scrollbarWidth : Int
    , pwaStatus : PwaStatus
    , notificationPermission : NotificationPermission
    }


loadStartupData : Command FrontendOnly toMsg msg
loadStartupData =
    Command.sendToJs "load_startup_data_to_js" load_startup_data_to_js Json.Encode.null


startupDataSub : (StartupData -> value) -> Subscription FrontendOnly value
startupDataSub msg =
    Subscription.fromJs
        "load_startup_data_from_js"
        load_startup_data_from_js
        (\json ->
            Json.Decode.decodeValue decodeStartupData json
                |> Result.withDefault
                    { timeOrigin = Time.millisToPosix 0
                    , userAgent = UserAgent.init
                    , scrollbarWidth = 0
                    , pwaStatus = BrowserView
                    , notificationPermission = NotAsked
                    }
                |> msg
        )


decodeStartupData : Json.Decode.Decoder StartupData
decodeStartupData =
    Json.Decode.map5 StartupData
        (Json.Decode.field "timeOrigin" (Json.Decode.map (\ms -> Time.millisToPosix (round ms)) Json.Decode.float))
        (Json.Decode.field "userAgent" (Json.Decode.map UserAgent.parseUserAgent Json.Decode.string))
        (Json.Decode.field "scrollbarWidth" Json.Decode.int)
        (Json.Decode.field "isPwa" (Json.Decode.map pwaStatusFromBool Json.Decode.bool))
        (Json.Decode.field "notificationPermission" (Json.Decode.map notificationPermissionFromString Json.Decode.string))


pwaStatusFromBool : Bool -> PwaStatus
pwaStatusFromBool isPwa =
    if isPwa then
        InstalledPwa

    else
        BrowserView


notificationPermissionFromString : String -> NotificationPermission
notificationPermissionFromString text =
    case text of
        "granted" ->
            Granted

        "denied" ->
            Denied

        "unsupported" ->
            Unsupported

        _ ->
            NotAsked


setFavicon : String -> Command FrontendOnly toMsg msg
setFavicon faviconPath =
    Command.sendToJs
        "martinsstewart_set_favicon_to_js"
        martinsstewart_set_favicon_to_js
        (Json.Encode.string faviconPath)


hapticFeedback : Command FrontendOnly toMsg msg
hapticFeedback =
    Command.sendToJs "haptic_feedback" haptic_feedback Json.Encode.null


port register_push_subscription_from_js : (Json.Decode.Value -> msg) -> Sub msg


port register_push_subscription_to_js : Json.Encode.Value -> Cmd msg


port window_has_focus_from_js : (Json.Decode.Value -> msg) -> Sub msg


port service_worker_message_from_js : (Json.Decode.Value -> msg) -> Sub msg


port close_notifications_to_js : Json.Encode.Value -> Cmd msg


port visual_viewport_resized_from_js : (Json.Decode.Value -> msg) -> Sub msg


port shift_scroll_by_element_delta_to_js : Json.Encode.Value -> Cmd msg


shiftScrollByElementDelta : HtmlId -> HtmlId -> Command FrontendOnly toMsg msg
shiftScrollByElementDelta containerId elementId =
    Command.sendToJs
        "shift_scroll_by_element_delta_to_js"
        shift_scroll_by_element_delta_to_js
        (Json.Encode.object
            [ ( "containerId", Json.Encode.string (Dom.idToString containerId) )
            , ( "elementId", Json.Encode.string (Dom.idToString elementId) )
            ]
        )


port smooth_scroll_by_to_js : Json.Encode.Value -> Cmd msg


smoothScrollBy : HtmlId -> Float -> Command FrontendOnly toMsg msg
smoothScrollBy containerId scrollY =
    Command.sendToJs
        "smooth_scroll_by_to_js"
        smooth_scroll_by_to_js
        (Json.Encode.object
            [ ( "containerId", Json.Encode.string (Dom.idToString containerId) )
            , ( "scrollY", Json.Encode.float scrollY )
            ]
        )


port set_cursor_position_to_js : Json.Encode.Value -> Cmd msg


setCursorPosition : HtmlId -> Range -> Command FrontendOnly toMsg msg
setCursorPosition htmlId range =
    Command.sendToJs
        "set_cursor_position_to_js"
        set_cursor_position_to_js
        (Json.Encode.object
            [ ( "htmlId", Json.Encode.string (Dom.idToString htmlId) )
            , ( "start", Json.Encode.int range.start )
            , ( "end", Json.Encode.int range.end )
            ]
        )


visualViewportResized : (Float -> msg) -> Subscription FrontendOnly msg
visualViewportResized msg =
    Subscription.fromJs
        "visual_viewport_resized_from_js"
        visual_viewport_resized_from_js
        (\json -> Json.Decode.decodeValue Json.Decode.float json |> Result.withDefault 0 |> msg)


closeNotifications : Command FrontendOnly toMsg msg
closeNotifications =
    Command.sendToJs "close_notifications_to_js" close_notifications_to_js Json.Encode.null


serviceWorkerMessage : (String -> msg) -> Subscription FrontendOnly msg
serviceWorkerMessage msg =
    Subscription.fromJs
        "service_worker_message_from_js"
        service_worker_message_from_js
        (\json ->
            Json.Decode.decodeValue Json.Decode.string json
                |> Result.withDefault ""
                |> msg
        )


pageHasFocus : (Bool -> msg) -> Subscription FrontendOnly msg
pageHasFocus msg =
    Subscription.fromJs
        "window_has_focus_from_js"
        window_has_focus_from_js
        (\json ->
            Json.Decode.decodeValue Json.Decode.bool json
                |> Result.withDefault True
                |> msg
        )


registerPushSubscriptionToJs : String -> Command FrontendOnly toMsg msg
registerPushSubscriptionToJs publicKey =
    Command.sendToJs
        "register_push_subscription_to_js"
        register_push_subscription_to_js
        (Json.Encode.string publicKey)


type RegisterPushSubscription
    = GotSubscribeData SubscribeData
    | SubscribeJsException String


registerPushSubscriptionCodec : Codec RegisterPushSubscription
registerPushSubscriptionCodec =
    Codec.custom
        (\a c encoder ->
            case encoder of
                GotSubscribeData a0 ->
                    a a0

                SubscribeJsException c0 ->
                    c c0
        )
        |> Codec.variant1 "GotSubscribeData" GotSubscribeData subscribeDataCodec
        |> Codec.variant1 "SubscribeJsException" SubscribeJsException Codec.string
        |> Codec.buildCustom


type alias SubscribeData =
    { endpoint : Url
    , expirationTime : Maybe Time.Posix
    , keys : SubscribeKeys
    }


type alias SubscribeKeys =
    { auth : String, p256dh : String }


subscribeDataCodec : Codec SubscribeData
subscribeDataCodec =
    Codec.object SubscribeData
        |> Codec.field "endpoint" .endpoint CodecExtra.url
        |> Codec.optionalNullableField "expirationTime" .expirationTime expirationTimeCodec
        |> Codec.field "keys" .keys subscribeKeysCodec
        |> Codec.buildObject


{-| The Push API reports `expirationTime` as a DOMHighResTimeStamp (milliseconds since the epoch).
-}
expirationTimeCodec : Codec Time.Posix
expirationTimeCodec =
    Codec.map
        (\ms -> Time.millisToPosix (round ms))
        (\posix -> toFloat (Time.posixToMillis posix))
        Codec.float


subscribeKeysCodec : Codec SubscribeKeys
subscribeKeysCodec =
    Codec.object SubscribeKeys
        |> Codec.field "auth" .auth Codec.string
        |> Codec.field "p256dh" .p256dh Codec.string
        |> Codec.buildObject


registerPushSubscription : (RegisterPushSubscription -> msg) -> Subscription FrontendOnly msg
registerPushSubscription msg =
    Subscription.fromJs
        "register_push_subscription_from_js"
        register_push_subscription_from_js
        (\json ->
            case Codec.decodeValue registerPushSubscriptionCodec json of
                Ok ok ->
                    msg ok

                Err error ->
                    Json.Decode.errorToString error |> SubscribeJsException |> msg
        )


requestNotificationPermission : Command FrontendOnly toMsg msg
requestNotificationPermission =
    Command.sendToJs "request_notification_permission" request_notification_permission Json.Encode.null


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
                (Json.Decode.map notificationPermissionFromString Json.Decode.string)
                json
                |> Result.withDefault NotAsked
                |> msg
        )


type PwaStatus
    = InstalledPwa
    | BrowserView


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


{-| Play a sound. `Nothing` plays it immediately; `Just time` schedules it to play at the given
time.
-}
playSound : Maybe Time.Posix -> String -> Command FrontendOnly toMsg msg
playSound maybeTime name =
    Command.sendToJs "play_sound"
        play_sound
        (Json.Encode.object
            [ ( "name", Json.Encode.string name )
            , ( "time"
              , case maybeTime of
                    Just time ->
                        Json.Encode.int (Time.posixToMillis time)

                    Nothing ->
                        Json.Encode.null
              )
            ]
        )


textInputSelectAll : HtmlId -> Command FrontendOnly toMsg msg
textInputSelectAll htmlId =
    Dom.idToString htmlId
        |> Json.Encode.string
        |> Command.sendToJs "text_input_select_all_to_js" text_input_select_all_to_js


copyToClipboard : String -> Command FrontendOnly toMsg msg
copyToClipboard text =
    Command.sendToJs "copy_to_clipboard_to_js" copy_to_clipboard_to_js (Json.Encode.string text)


copyImageToClipboard : String -> Command FrontendOnly toMsg msg
copyImageToClipboard imageUrl =
    Command.sendToJs "copy_image_to_clipboard_to_js" copy_image_to_clipboard_to_js (Json.Encode.string imageUrl)


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
