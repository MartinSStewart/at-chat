module RecordedTests exposing (fileRequests, main, setup, tests)

import Backend
import Bytes exposing (Bytes)
import Dict exposing (Dict)
import Effect.Browser.Dom as Dom
import Effect.Lamdera
import Effect.Test as T exposing (FileUpload(..), HttpRequest, HttpResponse(..), MultipleFilesUpload(..), PointerOptions(..))
import Frontend
import Json.Decode
import Json.Encode
import Test.Html.Query
import Test.Html.Selector as Selector
import Time
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import Url exposing (Url)


setup : T.ViewerWith (List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel))
setup =
    T.viewerWith tests
        |> T.addBytesFiles (Dict.values fileRequests)


main : Program () (T.Model ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel) (T.Msg ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
main =
    T.startViewer setup


domain : Url
domain =
    { protocol = Url.Http, host = "localhost", port_ = Just 8000, path = "", query = Nothing, fragment = Nothing }


{-| Please don't modify or rename this function
-}
fileRequests : Dict String String
fileRequests =
    [ ( "GET_http://localhost:3000/file/vapid", "/tests/data/1b846b6a39f0b828.txt" )
    , ( "POST_https://api.postmarkapp.com/email", "/tests/data/2911db1dd6723eb4.txt" )
    ]
        |> Dict.fromList


handleHttpRequests : Dict String String -> Dict String Bytes -> { currentRequest : HttpRequest, data : T.Data FrontendModel BackendModel } -> HttpResponse
handleHttpRequests overrides fileData { currentRequest } =
    let
        key : String
        key =
            currentRequest.method ++ "_" ++ currentRequest.url

        getData : String -> HttpResponse
        getData path =
            case Dict.get path fileData of
                Just data ->
                    BytesHttpResponse { url = currentRequest.url, statusCode = 200, statusText = "OK", headers = Dict.empty } data

                Nothing ->
                    UnhandledHttpRequest
    in
    case ( Dict.get key overrides, Dict.get key fileRequests ) of
        ( Just path, _ ) ->
            getData path

        ( Nothing, Just path ) ->
            getData path

        _ ->
            UnhandledHttpRequest


{-| You can change parts of this function represented with `...`.
The rest needs to remain unchanged in order for the test generator to be able to add new tests.

    tests : ... -> List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
    tests ... =
        let
            config = ...

            ...
        in
        [ ...
        ]

-}
tests : Dict String Bytes -> List (T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
tests fileData =
    let
        config =
            T.Config
                Frontend.app_
                Backend.app_
                (handleHttpRequests Dict.empty fileData)
                (\_ -> Nothing)
                (\_ -> UnhandledFileUpload)
                (\_ -> UnhandledMultiFileUpload)
                domain
    in
    [ T.start
        "new test"
        (Time.millisToPosix 1756680301958)
        config
        [ T.connectFrontend
            0
            (Effect.Lamdera.sessionIdFromString "439199c04b8f7b594cdeedebc2a8029b82943b0a")
            "/"
            { width = 825, height = 1312 }
            (\tab1 ->
                [ tab1.portEvent 21 "check_notification_permission_from_js" (Json.Encode.string "granted")
                , tab1.portEvent 2 "check_pwa_status_from_js" (stringToJson "false")
                , tab1.portEvent 13 "is_push_subscription_registered_from_js" (stringToJson "true")
                , tab1.portEvent 26 "load_user_settings_from_js" (Json.Encode.string "")
                , tab1.click 3290 (Dom.id "homePage_loginButton")
                , tab1.click 864 (Dom.id "please-add-an-id")
                , tab1.input 1227 (Dom.id "loginForm_emailInput") "a@a.se"
                , tab1.keyUp 933 (Dom.id "loginForm_emailInput") "Enter" []
                , tab1.click 3544 (Dom.id "please-add-an-id")
                , tab1.input 189 (Dom.id "loginForm_loginCodeInput") "22923193"
                , tab1.input 3 (Dom.id "loginForm_loginCodeInput") "22923193"
                , tab1.click 1384 (Dom.id "guild_openGuild_0")
                , tab1.focus 19 (Dom.id "channel_textinput")
                , tab1.click 941 (Dom.id "channel_textinput")
                , tab1.input 468 (Dom.id "channel_textinput") "Test"
                , tab1.blur 734 (Dom.id "channel_textinput")
                , tab1.click 62 (Dom.id "messageMenu_channelInput_sendMessage")
                ]
            )
        ]
    ]


stringToJson : String -> Json.Encode.Value
stringToJson json =
    Result.withDefault Json.Encode.null (Json.Decode.decodeString Json.Decode.value json)
