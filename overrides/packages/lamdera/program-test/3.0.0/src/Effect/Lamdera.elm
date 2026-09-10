module Effect.Lamdera exposing
    ( frontend, backend, sendToBackend, sendToFrontend, sendToFrontends, broadcast, onConnect, onDisconnect, ClientId, clientIdToString, clientIdFromString, SessionId, sessionIdToString, sessionIdFromString
    , toCmd
    )

{-| backend

@docs frontend, backend, sendToBackend, sendToFrontend, sendToFrontends, broadcast, onConnect, onDisconnect, ClientId, clientIdToString, clientIdFromString, SessionId, sessionIdToString, sessionIdFromString


# Temporary integration

@docs toCmd

-}

import Base64
import Browser
import Browser.Dom
import Browser.Events
import Browser.Navigation
import Bytes
import Bytes.Decode
import Bytes.Encode
import Crypto
import Duration
import Effect.Browser.Navigation
import Effect.Command exposing (BackendOnly, Command, FrontendOnly)
import Effect.Internal exposing (File(..), NavigationKey(..), Subscription(..), Visibility(..))
import Effect.Subscription exposing (Subscription)
import File
import File.Download
import File.Select
import Http
import Json.Encode
import Lamdera
import Process
import Task
import Time
import Url
import WebGLFix
import WebGLFix.Texture
import Websocket


{-| Create a Lamdera frontend application
-}
frontend :
    (toBackend -> Cmd frontendMsg)
    ->
        { init : Url.Url -> Effect.Browser.Navigation.Key -> ( model, Command FrontendOnly toBackend frontendMsg )
        , view : model -> Browser.Document frontendMsg
        , update : frontendMsg -> model -> ( model, Command FrontendOnly toBackend frontendMsg )
        , updateFromBackend : toFrontend -> model -> ( model, Command FrontendOnly toBackend frontendMsg )
        , subscriptions : model -> Subscription FrontendOnly frontendMsg
        , onUrlRequest : Browser.UrlRequest -> frontendMsg
        , onUrlChange : Url.Url -> frontendMsg
        }
    ->
        { init : Url.Url -> Browser.Navigation.Key -> ( model, Cmd frontendMsg )
        , view : model -> Browser.Document frontendMsg
        , update : frontendMsg -> model -> ( model, Cmd frontendMsg )
        , updateFromBackend : toFrontend -> model -> ( model, Cmd frontendMsg )
        , subscriptions : model -> Sub frontendMsg
        , onUrlRequest : Browser.UrlRequest -> frontendMsg
        , onUrlChange : Url.Url -> frontendMsg
        }
frontend toBackend userApp =
    { init =
        \url navigationKey ->
            userApp.init url (Effect.Internal.RealNavigationKey navigationKey |> Effect.Browser.Navigation.fromInternalKey)
                |> Tuple.mapSecond (toCmd (\_ -> Cmd.none) (\_ _ -> Cmd.none) toBackend)
    , view = userApp.view
    , update =
        \msg model ->
            userApp.update msg model
                |> Tuple.mapSecond (toCmd (\_ -> Cmd.none) (\_ _ -> Cmd.none) toBackend)
    , updateFromBackend =
        \msg model ->
            userApp.updateFromBackend msg model
                |> Tuple.mapSecond (toCmd (\_ -> Cmd.none) (\_ _ -> Cmd.none) toBackend)
    , subscriptions = userApp.subscriptions >> toSub
    , onUrlRequest = userApp.onUrlRequest
    , onUrlChange = userApp.onUrlChange
    }


{-| Create a Lamdera backend application
-}
backend :
    (toFrontend -> Cmd backendMsg)
    -> (String -> toFrontend -> Cmd backendMsg)
    ->
        { init : ( backendModel, Command BackendOnly toFrontend backendMsg )
        , update : backendMsg -> backendModel -> ( backendModel, Command BackendOnly toFrontend backendMsg )
        , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Command BackendOnly toFrontend backendMsg )
        , subscriptions : backendModel -> Subscription BackendOnly backendMsg
        }
    ->
        { init : ( backendModel, Cmd backendMsg )
        , update : backendMsg -> backendModel -> ( backendModel, Cmd backendMsg )
        , updateFromFrontend : String -> String -> toBackend -> backendModel -> ( backendModel, Cmd backendMsg )
        , subscriptions : backendModel -> Sub backendMsg
        }
backend broadcastCmd toFrontend userApp =
    { init = userApp.init |> Tuple.mapSecond (toCmd broadcastCmd toFrontend (\_ -> Cmd.none))
    , update = \msg model -> userApp.update msg model |> Tuple.mapSecond (toCmd broadcastCmd toFrontend (\_ -> Cmd.none))
    , updateFromFrontend =
        \sessionId clientId msg model ->
            userApp.updateFromFrontend
                (sessionIdFromString sessionId)
                (clientIdFromString clientId)
                msg
                model
                |> Tuple.mapSecond (toCmd broadcastCmd toFrontend (\_ -> Cmd.none))
    , subscriptions = userApp.subscriptions >> toSub
    }


{-| Send a toBackend msg to the Backend
-}
sendToBackend : toBackend -> Command FrontendOnly toBackend frontendMsg
sendToBackend =
    Effect.Internal.SendToBackend


{-| Send a toFrontend msg to the Frontend
-}
sendToFrontend : ClientId -> toFrontend -> Command BackendOnly toFrontend backendMsg
sendToFrontend client toFrontend =
    Effect.Internal.SendToFrontend (clientIdToString client |> Effect.Internal.ClientId) toFrontend


{-| Send a toFrontend msg to all the frontends that have a given SessionId.
-}
sendToFrontends : SessionId -> toFrontend -> Command BackendOnly toFrontend backendMsg
sendToFrontends sessionId toFrontend =
    Effect.Internal.SendToFrontends (sessionIdToString sessionId |> Effect.Internal.SessionId) toFrontend


{-| Send a toFrontend msg to all currently connected clients
-}
broadcast : toFrontend -> Command BackendOnly toFrontend backendMsg
broadcast =
    Effect.Internal.Broadcast


{-| Subscribe to Frontend client connected events
-}
onConnect : (SessionId -> ClientId -> backendMsg) -> Subscription BackendOnly backendMsg
onConnect msg =
    Effect.Internal.OnConnect
        (\(Effect.Internal.SessionId sessionId) (Effect.Internal.ClientId clientId) ->
            msg (sessionIdFromString sessionId) (clientIdFromString clientId)
        )


{-| Subscribe to Frontend client disconnected events
-}
onDisconnect : (SessionId -> ClientId -> backendMsg) -> Subscription BackendOnly backendMsg
onDisconnect msg =
    Effect.Internal.OnDisconnect
        (\(Effect.Internal.SessionId sessionId) (Effect.Internal.ClientId clientId) ->
            msg (sessionIdFromString sessionId) (clientIdFromString clientId)
        )


{-| -}
type ClientId
    = ClientId String


{-| -}
type SessionId
    = SessionId String


{-| -}
sessionIdFromString : String -> SessionId
sessionIdFromString =
    SessionId


{-| -}
sessionIdToString : SessionId -> String
sessionIdToString (SessionId sessionId) =
    sessionId


{-| -}
clientIdFromString : String -> ClientId
clientIdFromString =
    ClientId


{-| -}
clientIdToString : ClientId -> String
clientIdToString (ClientId clientId) =
    clientId


{-| Escape hatch for converting a `Command` to a regular `Cmd` in non-test code.
-}
toCmd : (toMsg -> Cmd msg) -> (String -> toMsg -> Cmd msg) -> (toMsg -> Cmd msg) -> Command restriction toMsg msg -> Cmd msg
toCmd broadcastCmd toFrontendCmd toBackendCmd effect =
    case effect of
        Effect.Internal.Batch effects ->
            List.map (toCmd broadcastCmd toFrontendCmd toBackendCmd) effects |> Cmd.batch

        Effect.Internal.None ->
            Cmd.none

        Effect.Internal.SendToBackend toBackend ->
            toBackendCmd toBackend

        Effect.Internal.NavigationPushUrl navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.pushUrl key string

                MockNavigationKey ->
                    Cmd.none

        Effect.Internal.NavigationReplaceUrl navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.replaceUrl key string

                MockNavigationKey ->
                    Cmd.none

        Effect.Internal.NavigationLoad url ->
            Browser.Navigation.load url

        Effect.Internal.NavigationBack navigationKey int ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.back key int

                MockNavigationKey ->
                    Cmd.none

        Effect.Internal.NavigationForward navigationKey int ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.forward key int

                MockNavigationKey ->
                    Cmd.none

        Effect.Internal.NavigationReload ->
            Browser.Navigation.reload

        Effect.Internal.NavigationReloadAndSkipCache ->
            Browser.Navigation.reloadAndSkipCache

        Effect.Internal.Task simulatedTask ->
            toTask simulatedTask
                |> Task.attempt
                    (\result ->
                        case result of
                            Ok ok ->
                                ok

                            Err err ->
                                err
                    )

        Effect.Internal.Port _ portFunction value ->
            portFunction value

        Effect.Internal.PortBytes _ portFunction value ->
            portFunction value

        Effect.Internal.SendToFrontend (Effect.Internal.ClientId clientId) toFrontend ->
            toFrontendCmd clientId toFrontend

        Effect.Internal.SendToFrontends (Effect.Internal.SessionId sessionId) toFrontend ->
            toFrontendCmd sessionId toFrontend

        Effect.Internal.FileDownloadUrl { href } ->
            File.Download.url href

        Effect.Internal.FileDownloadString { name, mimeType, content } ->
            File.Download.string name mimeType content

        Effect.Internal.FileDownloadBytes { name, mimeType, content } ->
            File.Download.bytes name mimeType content

        Effect.Internal.FileSelectFile mimeTypes msg ->
            File.Select.file mimeTypes (RealFile >> msg)

        Effect.Internal.FileSelectFiles mimeTypes msg ->
            File.Select.files mimeTypes (\file restOfFiles -> msg (RealFile file) (List.map RealFile restOfFiles))

        Effect.Internal.Broadcast toMsg ->
            broadcastCmd toMsg

        Effect.Internal.HttpCancel string ->
            Http.cancel string

        Effect.Internal.HttpTrackedRequest httpRequest ->
            trackedHttpRequestCmd httpRequest

        Effect.Internal.Passthrough cmd ->
            cmd


toHttpBody : Effect.Internal.HttpBody -> Http.Body
toHttpBody body =
    case body of
        Effect.Internal.EmptyBody ->
            Http.emptyBody

        Effect.Internal.StringBody { contentType, content } ->
            Http.stringBody contentType content

        Effect.Internal.JsonBody value ->
            Http.jsonBody value

        Effect.Internal.MultipartBody httpParts ->
            List.map
                (\part ->
                    case part of
                        Effect.Internal.StringPart a b ->
                            Http.stringPart a b

                        Effect.Internal.FilePart a b ->
                            case b of
                                Effect.Internal.RealFile file ->
                                    Http.filePart a file

                                Effect.Internal.MockFile _ ->
                                    Http.stringPart "" ""

                        Effect.Internal.BytesPart key mimeType content ->
                            Http.bytesPart key mimeType content
                )
                httpParts
                |> Http.multipartBody

        Effect.Internal.BytesBody a b ->
            Http.bytesBody a b

        Effect.Internal.FileBody file ->
            case file of
                Effect.Internal.RealFile realFile ->
                    Http.fileBody realFile

                MockFile _ ->
                    Http.emptyBody


{-| Http requests that have a tracker can't be handled with `Http.task` (it doesn't support trackers)
so they are sent with `Http.request` instead. That way `Effect.Http.track` and `Effect.Http.cancel` work.
-}
trackedHttpRequestCmd : Effect.Internal.TrackedHttpRequest msg -> Cmd msg
trackedHttpRequestCmd httpRequest =
    let
        toMsg : Result msg msg -> msg
        toMsg result =
            case result of
                Ok msg ->
                    msg

                Err msg ->
                    msg

        request :
            { method : String
            , headers : List Http.Header
            , url : String
            , body : Http.Body
            , expect : Http.Expect msg
            , timeout : Maybe Float
            , tracker : Maybe String
            }
        request =
            { method = httpRequest.method
            , headers = List.map (\( key, value ) -> Http.header key value) httpRequest.headers
            , url = httpRequest.url
            , body = toHttpBody httpRequest.body
            , expect =
                case httpRequest.expect of
                    Effect.Internal.ExpectStringResponse onRequestComplete ->
                        Http.expectStringResponse toMsg (\response -> onRequestComplete response |> Ok)

                    Effect.Internal.ExpectBytesResponse onRequestComplete ->
                        Http.expectBytesResponse toMsg (\response -> onRequestComplete response |> Ok)
            , timeout = Maybe.map Duration.inMilliseconds httpRequest.timeout
            , tracker = Just httpRequest.tracker
            }
    in
    if httpRequest.isRisky then
        Http.riskyRequest request

    else
        Http.request request


httpHelper httpRequest resolver =
    Http.task
        { method = httpRequest.method
        , headers = List.map (\( key, value ) -> Http.header key value) httpRequest.headers
        , url = httpRequest.url
        , body = toHttpBody httpRequest.body
        , resolver = resolver Ok
        , timeout = Maybe.map Duration.inMilliseconds httpRequest.timeout
        }
        |> Task.andThen (\response -> httpRequest.onRequestComplete response |> toTask)


toTask : Effect.Internal.Task restriction x b -> Task.Task x b
toTask simulatedTask =
    case simulatedTask of
        Effect.Internal.Succeed a ->
            Task.succeed a

        Effect.Internal.Fail x ->
            Task.fail x

        Effect.Internal.HttpStringTask httpRequest ->
            httpHelper httpRequest Http.stringResolver

        Effect.Internal.HttpBytesTask httpRequest ->
            httpHelper httpRequest Http.bytesResolver

        Effect.Internal.SleepTask duration function ->
            Process.sleep (Duration.inMilliseconds duration)
                |> Task.andThen (\() -> toTask (function ()))

        Effect.Internal.TimeNow gotTime ->
            Time.now |> Task.andThen (\time -> toTask (gotTime time))

        Effect.Internal.TimeHere gotTimeZone ->
            Time.here |> Task.andThen (\timeZone -> toTask (gotTimeZone timeZone))

        Effect.Internal.TimeGetZoneName gotTimeZoneName ->
            Time.getZoneName |> Task.andThen (\time -> toTask (gotTimeZoneName time))

        Effect.Internal.SetViewport x y function ->
            Browser.Dom.setViewport x y |> Task.andThen (\() -> toTask (function ()))

        Effect.Internal.GetViewport function ->
            Browser.Dom.getViewport |> Task.andThen (\viewport -> toTask (function viewport))

        Effect.Internal.GetElement string function ->
            Browser.Dom.getElement string
                |> Task.map Ok
                |> Task.onError
                    (\(Browser.Dom.NotFound id) -> Effect.Internal.BrowserDomNotFound id |> Err |> Task.succeed)
                |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.Focus string msg ->
            Browser.Dom.focus string
                |> Task.map Ok
                |> Task.onError
                    (\(Browser.Dom.NotFound id) -> Effect.Internal.BrowserDomNotFound id |> Err |> Task.succeed)
                |> Task.andThen (\result -> toTask (msg result))

        Effect.Internal.Blur string msg ->
            Browser.Dom.blur string
                |> Task.map Ok
                |> Task.onError
                    (\(Browser.Dom.NotFound id) -> Effect.Internal.BrowserDomNotFound id |> Err |> Task.succeed)
                |> Task.andThen (\result -> toTask (msg result))

        Effect.Internal.GetViewportOf string msg ->
            Browser.Dom.getViewportOf string
                |> Task.map Ok
                |> Task.onError
                    (\(Browser.Dom.NotFound id) -> Effect.Internal.BrowserDomNotFound id |> Err |> Task.succeed)
                |> Task.andThen (\result -> toTask (msg result))

        Effect.Internal.SetViewportOf string x y msg ->
            Browser.Dom.setViewportOf string x y
                |> Task.map Ok
                |> Task.onError
                    (\(Browser.Dom.NotFound id) -> Effect.Internal.BrowserDomNotFound id |> Err |> Task.succeed)
                |> Task.andThen (\result -> toTask (msg result))

        Effect.Internal.FileToString file function ->
            case file of
                RealFile file_ ->
                    File.toString file_ |> Task.andThen (\result -> toTask (function result))

                MockFile { content } ->
                    (case content of
                        Effect.Internal.StringFile a ->
                            a

                        Effect.Internal.BytesFile a ->
                            Bytes.Decode.decode (Bytes.Decode.string (Bytes.width a)) a
                                |> Maybe.withDefault ""
                    )
                        |> function
                        |> toTask

        Effect.Internal.FileToBytes file function ->
            case file of
                RealFile file_ ->
                    File.toBytes file_ |> Task.andThen (\result -> toTask (function result))

                MockFile { content } ->
                    (case content of
                        Effect.Internal.StringFile a ->
                            Bytes.Encode.encode (Bytes.Encode.string a)

                        Effect.Internal.BytesFile a ->
                            a
                    )
                        |> function
                        |> toTask

        Effect.Internal.FileToUrl file function ->
            case file of
                RealFile file_ ->
                    File.toUrl file_ |> Task.andThen (\result -> toTask (function result))

                MockFile { content } ->
                    (case content of
                        Effect.Internal.StringFile a ->
                            "data:*/*;base64," ++ Maybe.withDefault "" (Base64.fromString a)

                        Effect.Internal.BytesFile a ->
                            "data:*/*;base64," ++ Maybe.withDefault "" (Base64.fromBytes a)
                    )
                        |> function
                        |> toTask

        Effect.Internal.LoadTexture options string function ->
            let
                convertWrap wrap =
                    case wrap of
                        Effect.Internal.Repeat ->
                            WebGLFix.Texture.repeat

                        Effect.Internal.ClampToEdge ->
                            WebGLFix.Texture.clampToEdge

                        Effect.Internal.MirroredRepeat ->
                            WebGLFix.Texture.mirroredRepeat
            in
            WebGLFix.Texture.loadWith
                { magnify =
                    case options.magnify of
                        Effect.Internal.Linear ->
                            WebGLFix.Texture.linear

                        _ ->
                            WebGLFix.Texture.nearest
                , minify =
                    case options.minify of
                        Effect.Internal.Linear ->
                            WebGLFix.Texture.linear

                        Effect.Internal.Nearest ->
                            WebGLFix.Texture.nearest

                        Effect.Internal.NearestMipmapNearest ->
                            WebGLFix.Texture.nearestMipmapNearest

                        Effect.Internal.LinearMipmapNearest ->
                            WebGLFix.Texture.linearMipmapNearest

                        Effect.Internal.NearestMipmapLinear ->
                            WebGLFix.Texture.nearestMipmapLinear

                        Effect.Internal.LinearMipmapLinear ->
                            WebGLFix.Texture.linearMipmapLinear
                , horizontalWrap = convertWrap options.horizontalWrap
                , verticalWrap = convertWrap options.verticalWrap
                , flipY = options.flipY
                , premultiplyAlpha = options.premultiplyAlpha
                }
                string
                |> Task.map Ok
                |> Task.onError (Err >> Task.succeed)
                |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.RequestXrStart options function ->
            WebGLFix.requestXrStart options
                |> Task.map Ok
                |> Task.onError (Err >> Task.succeed)
                |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.RenderXrFrame entities function ->
            WebGLFix.renderXrFrame entities
                |> Task.map Ok
                |> Task.onError (Err >> Task.succeed)
                |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.EndXrSession function ->
            WebGLFix.endXrSession |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.WebsocketCreateHandle url function ->
            Websocket.createHandle url
                |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.WebsocketSendString connection data function ->
            Websocket.sendString connection data
                |> Task.map Ok
                |> Task.onError (Err >> Task.succeed)
                |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.WebsocketClose connection function ->
            Websocket.close connection
                |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.CryptoTaskAesCtr operation function ->
            runAesCtr operation |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.CryptoTaskAesCbc operation function ->
            runAesCbc operation |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.CryptoTaskAesGcm operation function ->
            runAesGcm operation |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.CryptoTaskHmac operation function ->
            runHmac operation |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.CryptoTaskRsaOaep operation function ->
            runRsaOaep operation |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.CryptoTaskRsaPss operation function ->
            runRsaPss operation |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.CryptoTaskRsaSsaPkcs1V1_5 operation function ->
            runRsaSsaPkcs1V1_5 operation |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.CryptoTaskEcdsa operation function ->
            runEcdsa operation |> Task.andThen (\result -> toTask (function result))

        Effect.Internal.CryptoTaskPlain operation function ->
            runPlain operation |> Task.andThen (\result -> toTask (function result))



-- CRYPTO
--
-- One interpreter per algorithm. They are written out rather than shared through a
-- record of functions, because each one calls a different set of Crypto functions and
-- the only thing they have in common is their shape.


browserContext : Effect.Internal.CryptoSecureContext -> Maybe Crypto.SecureContext
browserContext context =
    case context of
        Effect.Internal.BrowserSecureContext secureContext ->
            Just secureContext

        Effect.Internal.SimulatedSecureContext ->
            Nothing


browserKey : Effect.Internal.CryptoKey key keyData -> Maybe (Crypto.Key key keyData)
browserKey key =
    case key of
        Effect.Internal.BrowserCryptoKey realKey ->
            Just realKey

        Effect.Internal.SimulatedCryptoKey _ ->
            Nothing


browserPublicKey : Effect.Internal.CryptoPublicKey key keyData -> Maybe (Crypto.PublicKey key keyData)
browserPublicKey key =
    case key of
        Effect.Internal.BrowserCryptoPublicKey realKey ->
            Just realKey

        Effect.Internal.SimulatedCryptoPublicKey _ ->
            Nothing


browserPrivateKey : Effect.Internal.CryptoPrivateKey key keyData -> Maybe (Crypto.PrivateKey key keyData)
browserPrivateKey key =
    case key of
        Effect.Internal.BrowserCryptoPrivateKey realKey ->
            Just realKey

        Effect.Internal.SimulatedCryptoPrivateKey _ ->
            Nothing



-- Folding a failed crypto task into the result, so an interpreter never fails and the
-- error reaches Effect.Crypto, which knows which error type this operation has.


cipherKey : Effect.Internal.CryptoError -> Task.Task e (Crypto.Key key keyData) -> Task.Task x (Effect.Internal.CipherResult key keyData)
cipherKey error task =
    task
        |> Task.map (Effect.Internal.BrowserCryptoKey >> Effect.Internal.GotCipherKey)
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.CipherFailed error))


cipherBytes : Effect.Internal.CryptoError -> Task.Task e Bytes.Bytes -> Task.Task x (Effect.Internal.CipherResult key keyData)
cipherBytes error task =
    task
        |> Task.map Effect.Internal.GotCipherBytes
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.CipherFailed error))


cipherJwk : Effect.Internal.CryptoError -> Task.Task e Json.Encode.Value -> Task.Task x (Effect.Internal.CipherResult key keyData)
cipherJwk error task =
    task
        |> Task.map Effect.Internal.GotCipherJwk
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.CipherFailed error))


cipherUnavailable : Task.Task x (Effect.Internal.CipherResult key keyData)
cipherUnavailable =
    Task.succeed (Effect.Internal.CipherFailed Effect.Internal.CryptoSimulatedValueOutsideTest)


runAesCtr :
    Effect.Internal.CipherOperation Crypto.AesCtrKey Crypto.AesKeyParams Crypto.AesCtrParams
    -> Task.Task x (Effect.Internal.CipherResult Crypto.AesCtrKey Crypto.AesKeyParams)
runAesCtr operation =
    case operation of
        Effect.Internal.GenerateCipherKey context params ->
            case browserContext context of
                Just secureContext ->
                    cipherKey Effect.Internal.CryptoKeyGenerationFailed (Crypto.generateAesCtrKey secureContext params)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ImportCipherKeyFromRaw context extractable bytes ->
            case browserContext context of
                Just secureContext ->
                    cipherKey Effect.Internal.CryptoKeyImportFailed (Crypto.importAesCtrKeyFromRaw secureContext extractable bytes)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ImportCipherKeyFromJwk context extractable jwk ->
            case browserContext context of
                Just secureContext ->
                    cipherKey Effect.Internal.CryptoKeyImportFailed (Crypto.importAesCtrKeyFromJwk secureContext extractable jwk)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ExportCipherKeyAsRaw key ->
            case browserKey key of
                Just realKey ->
                    cipherBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportAesCtrKeyAsRaw realKey)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ExportCipherKeyAsJwk key ->
            case browserKey key of
                Just realKey ->
                    cipherJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportAesCtrKeyAsJwk realKey)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.Encrypt params key bytes ->
            case browserKey key of
                Just realKey ->
                    cipherBytes Effect.Internal.CryptoEncryptionFailed (Crypto.encryptWithAesCtr params realKey bytes)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.Decrypt params key bytes ->
            case browserKey key of
                Just realKey ->
                    cipherBytes Effect.Internal.CryptoDecryptionFailed (Crypto.decryptWithAesCtr params realKey bytes)

                Nothing ->
                    cipherUnavailable


runAesCbc :
    Effect.Internal.CipherOperation Crypto.AesCbcKey Crypto.AesKeyParams Crypto.AesCbcParams
    -> Task.Task x (Effect.Internal.CipherResult Crypto.AesCbcKey Crypto.AesKeyParams)
runAesCbc operation =
    case operation of
        Effect.Internal.GenerateCipherKey context params ->
            case browserContext context of
                Just secureContext ->
                    cipherKey Effect.Internal.CryptoKeyGenerationFailed (Crypto.generateAesCbcKey secureContext params)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ImportCipherKeyFromRaw context extractable bytes ->
            case browserContext context of
                Just secureContext ->
                    cipherKey Effect.Internal.CryptoKeyImportFailed (Crypto.importAesCbcKeyFromRaw secureContext extractable bytes)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ImportCipherKeyFromJwk context extractable jwk ->
            case browserContext context of
                Just secureContext ->
                    cipherKey Effect.Internal.CryptoKeyImportFailed (Crypto.importAesCbcKeyFromJwk secureContext extractable jwk)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ExportCipherKeyAsRaw key ->
            case browserKey key of
                Just realKey ->
                    cipherBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportAesCbcKeyAsRaw realKey)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ExportCipherKeyAsJwk key ->
            case browserKey key of
                Just realKey ->
                    cipherJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportAesCbcKeyAsJwk realKey)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.Encrypt params key bytes ->
            case browserKey key of
                Just realKey ->
                    cipherBytes Effect.Internal.CryptoEncryptionFailed (Crypto.encryptWithAesCbc params realKey bytes)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.Decrypt params key bytes ->
            case browserKey key of
                Just realKey ->
                    cipherBytes Effect.Internal.CryptoDecryptionFailed (Crypto.decryptWithAesCbc params realKey bytes)

                Nothing ->
                    cipherUnavailable


runAesGcm :
    Effect.Internal.CipherOperation Crypto.AesGcmKey Crypto.AesKeyParams Crypto.AesGcmParams
    -> Task.Task x (Effect.Internal.CipherResult Crypto.AesGcmKey Crypto.AesKeyParams)
runAesGcm operation =
    case operation of
        Effect.Internal.GenerateCipherKey context params ->
            case browserContext context of
                Just secureContext ->
                    cipherKey Effect.Internal.CryptoKeyGenerationFailed (Crypto.generateAesGcmKey secureContext params)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ImportCipherKeyFromRaw context extractable bytes ->
            case browserContext context of
                Just secureContext ->
                    cipherKey Effect.Internal.CryptoKeyImportFailed (Crypto.importAesGcmKeyFromRaw secureContext extractable bytes)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ImportCipherKeyFromJwk context extractable jwk ->
            case browserContext context of
                Just secureContext ->
                    cipherKey Effect.Internal.CryptoKeyImportFailed (Crypto.importAesGcmKeyFromJwk secureContext extractable jwk)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ExportCipherKeyAsRaw key ->
            case browserKey key of
                Just realKey ->
                    cipherBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportAesGcmKeyAsRaw realKey)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.ExportCipherKeyAsJwk key ->
            case browserKey key of
                Just realKey ->
                    cipherJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportAesGcmKeyAsJwk realKey)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.Encrypt params key bytes ->
            case browserKey key of
                Just realKey ->
                    cipherBytes Effect.Internal.CryptoEncryptionFailed (Crypto.encryptWithAesGcm params realKey bytes)

                Nothing ->
                    cipherUnavailable

        Effect.Internal.Decrypt params key bytes ->
            case browserKey key of
                Just realKey ->
                    cipherBytes Effect.Internal.CryptoDecryptionFailed (Crypto.decryptWithAesGcm params realKey bytes)

                Nothing ->
                    cipherUnavailable


macKey : Effect.Internal.CryptoError -> Task.Task e (Crypto.Key key keyData) -> Task.Task x (Effect.Internal.MacResult key keyData)
macKey error task =
    task
        |> Task.map (Effect.Internal.BrowserCryptoKey >> Effect.Internal.GotMacKey)
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.MacFailed error))


macBytes : Effect.Internal.CryptoError -> Task.Task e Bytes.Bytes -> Task.Task x (Effect.Internal.MacResult key keyData)
macBytes error task =
    task
        |> Task.map Effect.Internal.GotMacBytes
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.MacFailed error))


macJwk : Effect.Internal.CryptoError -> Task.Task e Json.Encode.Value -> Task.Task x (Effect.Internal.MacResult key keyData)
macJwk error task =
    task
        |> Task.map Effect.Internal.GotMacJwk
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.MacFailed error))


macUnavailable : Task.Task x (Effect.Internal.MacResult key keyData)
macUnavailable =
    Task.succeed (Effect.Internal.MacFailed Effect.Internal.CryptoSimulatedValueOutsideTest)


runHmac :
    Effect.Internal.MacOperation Crypto.HmacKey Crypto.HmacKeyParams
    -> Task.Task x (Effect.Internal.MacResult Crypto.HmacKey Crypto.HmacKeyParams)
runHmac operation =
    case operation of
        Effect.Internal.GenerateMacKey context params ->
            case browserContext context of
                Just secureContext ->
                    macKey Effect.Internal.CryptoKeyGenerationFailed (Crypto.generateHmacKey secureContext params)

                Nothing ->
                    macUnavailable

        Effect.Internal.ImportMacKeyFromRaw context extractable hash length bytes ->
            case browserContext context of
                Just secureContext ->
                    macKey Effect.Internal.CryptoKeyImportFailed (Crypto.importHmacKeyFromRaw secureContext extractable hash length bytes)

                Nothing ->
                    macUnavailable

        Effect.Internal.ImportMacKeyFromJwk context extractable hash length jwk ->
            case browserContext context of
                Just secureContext ->
                    macKey Effect.Internal.CryptoKeyImportFailed (Crypto.importHmacKeyFromJwk secureContext extractable hash length jwk)

                Nothing ->
                    macUnavailable

        Effect.Internal.ExportMacKeyAsRaw key ->
            case browserKey key of
                Just realKey ->
                    macBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportHmacKeyAsRaw realKey)

                Nothing ->
                    macUnavailable

        Effect.Internal.ExportMacKeyAsJwk key ->
            case browserKey key of
                Just realKey ->
                    macJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportHmacKeyAsJwk realKey)

                Nothing ->
                    macUnavailable

        Effect.Internal.SignWithMacKey key bytes ->
            case browserKey key of
                Just realKey ->
                    macBytes Effect.Internal.CryptoSigningFailed (Crypto.signWithHmac realKey bytes)

                Nothing ->
                    macUnavailable

        Effect.Internal.VerifyWithMacKey key signature bytes ->
            case browserKey key of
                Just realKey ->
                    macBytes Effect.Internal.CryptoVerificationFailed (Crypto.verifyWithHmac realKey signature bytes)

                Nothing ->
                    macUnavailable


rsaSignatureKeyPair : Task.Task e (Crypto.KeyPair key Crypto.RsaKeyParams) -> Task.Task x (Effect.Internal.RsaSignatureResult key)
rsaSignatureKeyPair task =
    task
        |> Task.map
            (\keyPair ->
                Effect.Internal.GotRsaSignatureKeyPair
                    (Effect.Internal.BrowserCryptoPublicKey keyPair.publicKey)
                    (Effect.Internal.BrowserCryptoPrivateKey keyPair.privateKey)
            )
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.RsaSignatureFailed Effect.Internal.CryptoKeyGenerationFailed))


rsaSignaturePublicKey : Task.Task e (Crypto.PublicKey key Crypto.RsaKeyParams) -> Task.Task x (Effect.Internal.RsaSignatureResult key)
rsaSignaturePublicKey task =
    task
        |> Task.map (Effect.Internal.BrowserCryptoPublicKey >> Effect.Internal.GotRsaSignaturePublicKey)
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.RsaSignatureFailed Effect.Internal.CryptoKeyImportFailed))


rsaSignaturePrivateKey : Task.Task e (Crypto.PrivateKey key Crypto.RsaKeyParams) -> Task.Task x (Effect.Internal.RsaSignatureResult key)
rsaSignaturePrivateKey task =
    task
        |> Task.map (Effect.Internal.BrowserCryptoPrivateKey >> Effect.Internal.GotRsaSignaturePrivateKey)
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.RsaSignatureFailed Effect.Internal.CryptoKeyImportFailed))


rsaSignatureBytes : Effect.Internal.CryptoError -> Task.Task e Bytes.Bytes -> Task.Task x (Effect.Internal.RsaSignatureResult key)
rsaSignatureBytes error task =
    task
        |> Task.map Effect.Internal.GotRsaSignatureBytes
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.RsaSignatureFailed error))


rsaSignatureJwk : Effect.Internal.CryptoError -> Task.Task e Json.Encode.Value -> Task.Task x (Effect.Internal.RsaSignatureResult key)
rsaSignatureJwk error task =
    task
        |> Task.map Effect.Internal.GotRsaSignatureJwk
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.RsaSignatureFailed error))


rsaSignatureUnavailable : Task.Task x (Effect.Internal.RsaSignatureResult key)
rsaSignatureUnavailable =
    Task.succeed (Effect.Internal.RsaSignatureFailed Effect.Internal.CryptoSimulatedValueOutsideTest)


runRsaPss :
    Effect.Internal.RsaSignatureOperation Crypto.RsaPssKey Crypto.RsaPssParams
    -> Task.Task x (Effect.Internal.RsaSignatureResult Crypto.RsaPssKey)
runRsaPss operation =
    case operation of
        Effect.Internal.GenerateRsaSignatureKeyPair context params ->
            case browserContext context of
                Just secureContext ->
                    rsaSignatureKeyPair (Crypto.generateRsaPssKeyPair secureContext params)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ImportRsaSignaturePublicKeyFromSpki context params bytes ->
            case browserContext context of
                Just secureContext ->
                    rsaSignaturePublicKey (Crypto.importRsaPssPublicKeyFromSpki secureContext params bytes)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ImportRsaSignaturePublicKeyFromJwk context params jwk ->
            case browserContext context of
                Just secureContext ->
                    rsaSignaturePublicKey (Crypto.importRsaPssPublicKeyFromJwk secureContext params jwk)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ImportRsaSignaturePrivateKeyFromPkcs8 context extractable params bytes ->
            case browserContext context of
                Just secureContext ->
                    rsaSignaturePrivateKey (Crypto.importRsaPssPrivateKeyFromPkcs8 secureContext extractable params bytes)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ImportRsaSignaturePrivateKeyFromJwk context extractable params jwk ->
            case browserContext context of
                Just secureContext ->
                    rsaSignaturePrivateKey (Crypto.importRsaPssPrivateKeyFromJwk secureContext extractable params jwk)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ExportRsaSignaturePublicKeyAsSpki key ->
            case browserPublicKey key of
                Just realKey ->
                    rsaSignatureBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaPssPublicKeyAsSpki realKey)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ExportRsaSignaturePublicKeyAsJwk key ->
            case browserPublicKey key of
                Just realKey ->
                    rsaSignatureJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaPssPublicKeyAsJwk realKey)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ExportRsaSignaturePrivateKeyAsPkcs8 key ->
            case browserPrivateKey key of
                Just realKey ->
                    rsaSignatureBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaPssPrivateKeyAsPkcs8 realKey)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ExportRsaSignaturePrivateKeyAsJwk key ->
            case browserPrivateKey key of
                Just realKey ->
                    rsaSignatureJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaPssPrivateKeyAsJwk realKey)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.SignWithRsaPrivateKey params key bytes ->
            case browserPrivateKey key of
                Just realKey ->
                    rsaSignatureBytes Effect.Internal.CryptoSigningFailed (Crypto.signWithRsaPss params realKey bytes)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.VerifyWithRsaPublicKey params key signature bytes ->
            case browserPublicKey key of
                Just realKey ->
                    rsaSignatureBytes Effect.Internal.CryptoVerificationFailed (Crypto.verifyWithRsaPss params realKey signature bytes)

                Nothing ->
                    rsaSignatureUnavailable


runRsaSsaPkcs1V1_5 :
    Effect.Internal.RsaSignatureOperation Crypto.RsaSsaPkcs1V1_5Key ()
    -> Task.Task x (Effect.Internal.RsaSignatureResult Crypto.RsaSsaPkcs1V1_5Key)
runRsaSsaPkcs1V1_5 operation =
    case operation of
        Effect.Internal.GenerateRsaSignatureKeyPair context params ->
            case browserContext context of
                Just secureContext ->
                    rsaSignatureKeyPair (Crypto.generateRsaSsaPkcs1V1_5KeyPair secureContext params)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ImportRsaSignaturePublicKeyFromSpki context params bytes ->
            case browserContext context of
                Just secureContext ->
                    rsaSignaturePublicKey (Crypto.importRsaSsaPkcs1V1_5PublicKeyFromSpki secureContext params bytes)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ImportRsaSignaturePublicKeyFromJwk context params jwk ->
            case browserContext context of
                Just secureContext ->
                    rsaSignaturePublicKey (Crypto.importRsaSsaPkcs1V1_5PublicKeyFromJwk secureContext params jwk)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ImportRsaSignaturePrivateKeyFromPkcs8 context extractable params bytes ->
            case browserContext context of
                Just secureContext ->
                    rsaSignaturePrivateKey (Crypto.importRsaSsaPkcs1V1_5PrivateKeyFromPkcs8 secureContext extractable params bytes)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ImportRsaSignaturePrivateKeyFromJwk context extractable params jwk ->
            case browserContext context of
                Just secureContext ->
                    rsaSignaturePrivateKey (Crypto.importRsaSsaPkcs1V1_5PrivateKeyFromJwk secureContext extractable params jwk)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ExportRsaSignaturePublicKeyAsSpki key ->
            case browserPublicKey key of
                Just realKey ->
                    rsaSignatureBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaSsaPkcs1V1_5PublicKeyAsSpki realKey)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ExportRsaSignaturePublicKeyAsJwk key ->
            case browserPublicKey key of
                Just realKey ->
                    rsaSignatureJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaSsaPkcs1V1_5PublicKeyAsJwk realKey)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ExportRsaSignaturePrivateKeyAsPkcs8 key ->
            case browserPrivateKey key of
                Just realKey ->
                    rsaSignatureBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaSsaPkcs1V1_5PrivateKeyAsPkcs8 realKey)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.ExportRsaSignaturePrivateKeyAsJwk key ->
            case browserPrivateKey key of
                Just realKey ->
                    rsaSignatureJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaSsaPkcs1V1_5PrivateKeyAsJwk realKey)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.SignWithRsaPrivateKey () key bytes ->
            case browserPrivateKey key of
                Just realKey ->
                    rsaSignatureBytes Effect.Internal.CryptoSigningFailed (Crypto.signWithRsaSsaPkcs1V1_5 realKey bytes)

                Nothing ->
                    rsaSignatureUnavailable

        Effect.Internal.VerifyWithRsaPublicKey () key signature bytes ->
            case browserPublicKey key of
                Just realKey ->
                    rsaSignatureBytes Effect.Internal.CryptoVerificationFailed (Crypto.verifyWithRsaSsaPkcs1V1_5 realKey signature bytes)

                Nothing ->
                    rsaSignatureUnavailable


publicKeyCipherKeyPair : Task.Task e (Crypto.KeyPair key Crypto.RsaKeyParams) -> Task.Task x (Effect.Internal.PublicKeyCipherResult key)
publicKeyCipherKeyPair task =
    task
        |> Task.map
            (\keyPair ->
                Effect.Internal.GotCipherKeyPair
                    (Effect.Internal.BrowserCryptoPublicKey keyPair.publicKey)
                    (Effect.Internal.BrowserCryptoPrivateKey keyPair.privateKey)
            )
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.PublicKeyCipherFailed Effect.Internal.CryptoKeyGenerationFailed))


publicKeyCipherPublicKey : Task.Task e (Crypto.PublicKey key Crypto.RsaKeyParams) -> Task.Task x (Effect.Internal.PublicKeyCipherResult key)
publicKeyCipherPublicKey task =
    task
        |> Task.map (Effect.Internal.BrowserCryptoPublicKey >> Effect.Internal.GotCipherPublicKey)
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.PublicKeyCipherFailed Effect.Internal.CryptoKeyImportFailed))


publicKeyCipherPrivateKey : Task.Task e (Crypto.PrivateKey key Crypto.RsaKeyParams) -> Task.Task x (Effect.Internal.PublicKeyCipherResult key)
publicKeyCipherPrivateKey task =
    task
        |> Task.map (Effect.Internal.BrowserCryptoPrivateKey >> Effect.Internal.GotCipherPrivateKey)
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.PublicKeyCipherFailed Effect.Internal.CryptoKeyImportFailed))


publicKeyCipherBytes : Effect.Internal.CryptoError -> Task.Task e Bytes.Bytes -> Task.Task x (Effect.Internal.PublicKeyCipherResult key)
publicKeyCipherBytes error task =
    task
        |> Task.map Effect.Internal.GotPublicKeyCipherBytes
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.PublicKeyCipherFailed error))


publicKeyCipherJwk : Effect.Internal.CryptoError -> Task.Task e Json.Encode.Value -> Task.Task x (Effect.Internal.PublicKeyCipherResult key)
publicKeyCipherJwk error task =
    task
        |> Task.map Effect.Internal.GotPublicKeyCipherJwk
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.PublicKeyCipherFailed error))


publicKeyCipherUnavailable : Task.Task x (Effect.Internal.PublicKeyCipherResult key)
publicKeyCipherUnavailable =
    Task.succeed (Effect.Internal.PublicKeyCipherFailed Effect.Internal.CryptoSimulatedValueOutsideTest)


runRsaOaep :
    Effect.Internal.PublicKeyCipherOperation Crypto.RsaOaepKey Crypto.RsaOaepParams
    -> Task.Task x (Effect.Internal.PublicKeyCipherResult Crypto.RsaOaepKey)
runRsaOaep operation =
    case operation of
        Effect.Internal.GenerateCipherKeyPair context params ->
            case browserContext context of
                Just secureContext ->
                    publicKeyCipherKeyPair (Crypto.generateRsaOaepKeyPair secureContext params)

                Nothing ->
                    publicKeyCipherUnavailable

        Effect.Internal.ImportCipherPublicKeyFromSpki context params bytes ->
            case browserContext context of
                Just secureContext ->
                    publicKeyCipherPublicKey (Crypto.importRsaOaepPublicKeyFromSpki secureContext params bytes)

                Nothing ->
                    publicKeyCipherUnavailable

        Effect.Internal.ImportCipherPublicKeyFromJwk context params jwk ->
            case browserContext context of
                Just secureContext ->
                    publicKeyCipherPublicKey (Crypto.importRsaOaepPublicKeyFromJwk secureContext params jwk)

                Nothing ->
                    publicKeyCipherUnavailable

        Effect.Internal.ImportCipherPrivateKeyFromPkcs8 context extractable params bytes ->
            case browserContext context of
                Just secureContext ->
                    publicKeyCipherPrivateKey (Crypto.importRsaOaepPrivateKeyFromPkcs8 secureContext extractable params bytes)

                Nothing ->
                    publicKeyCipherUnavailable

        Effect.Internal.ImportCipherPrivateKeyFromJwk context extractable params jwk ->
            case browserContext context of
                Just secureContext ->
                    publicKeyCipherPrivateKey (Crypto.importRsaOaepPrivateKeyFromJwk secureContext extractable params jwk)

                Nothing ->
                    publicKeyCipherUnavailable

        Effect.Internal.ExportCipherPublicKeyAsSpki key ->
            case browserPublicKey key of
                Just realKey ->
                    publicKeyCipherBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaOaepPublicKeyAsSpki realKey)

                Nothing ->
                    publicKeyCipherUnavailable

        Effect.Internal.ExportCipherPublicKeyAsJwk key ->
            case browserPublicKey key of
                Just realKey ->
                    publicKeyCipherJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaOaepPublicKeyAsJwk realKey)

                Nothing ->
                    publicKeyCipherUnavailable

        Effect.Internal.ExportCipherPrivateKeyAsPkcs8 key ->
            case browserPrivateKey key of
                Just realKey ->
                    publicKeyCipherBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaOaepPrivateKeyAsPkcs8 realKey)

                Nothing ->
                    publicKeyCipherUnavailable

        Effect.Internal.ExportCipherPrivateKeyAsJwk key ->
            case browserPrivateKey key of
                Just realKey ->
                    publicKeyCipherJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportRsaOaepPrivateKeyAsJwk realKey)

                Nothing ->
                    publicKeyCipherUnavailable

        Effect.Internal.EncryptWithPublicKey params key bytes ->
            case browserPublicKey key of
                Just realKey ->
                    publicKeyCipherBytes Effect.Internal.CryptoEncryptionFailed (Crypto.encryptWithRsaOaep params realKey bytes)

                Nothing ->
                    publicKeyCipherUnavailable

        Effect.Internal.DecryptWithPrivateKey params key bytes ->
            case browserPrivateKey key of
                Just realKey ->
                    publicKeyCipherBytes Effect.Internal.CryptoDecryptionFailed (Crypto.decryptWithRsaOaep params realKey bytes)

                Nothing ->
                    publicKeyCipherUnavailable


ecSignatureKeyPair : Task.Task e (Crypto.KeyPair key Crypto.EcKeyParams) -> Task.Task x (Effect.Internal.EcSignatureResult key)
ecSignatureKeyPair task =
    task
        |> Task.map
            (\keyPair ->
                Effect.Internal.GotEcSignatureKeyPair
                    (Effect.Internal.BrowserCryptoPublicKey keyPair.publicKey)
                    (Effect.Internal.BrowserCryptoPrivateKey keyPair.privateKey)
            )
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.EcSignatureFailed Effect.Internal.CryptoKeyGenerationFailed))


ecSignaturePublicKey : Task.Task e (Crypto.PublicKey key Crypto.EcKeyParams) -> Task.Task x (Effect.Internal.EcSignatureResult key)
ecSignaturePublicKey task =
    task
        |> Task.map (Effect.Internal.BrowserCryptoPublicKey >> Effect.Internal.GotEcSignaturePublicKey)
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.EcSignatureFailed Effect.Internal.CryptoKeyImportFailed))


ecSignaturePrivateKey : Task.Task e (Crypto.PrivateKey key Crypto.EcKeyParams) -> Task.Task x (Effect.Internal.EcSignatureResult key)
ecSignaturePrivateKey task =
    task
        |> Task.map (Effect.Internal.BrowserCryptoPrivateKey >> Effect.Internal.GotEcSignaturePrivateKey)
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.EcSignatureFailed Effect.Internal.CryptoKeyImportFailed))


ecSignatureBytes : Effect.Internal.CryptoError -> Task.Task e Bytes.Bytes -> Task.Task x (Effect.Internal.EcSignatureResult key)
ecSignatureBytes error task =
    task
        |> Task.map Effect.Internal.GotEcSignatureBytes
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.EcSignatureFailed error))


ecSignatureJwk : Effect.Internal.CryptoError -> Task.Task e Json.Encode.Value -> Task.Task x (Effect.Internal.EcSignatureResult key)
ecSignatureJwk error task =
    task
        |> Task.map Effect.Internal.GotEcSignatureJwk
        |> Task.onError (\_ -> Task.succeed (Effect.Internal.EcSignatureFailed error))


ecSignatureUnavailable : Task.Task x (Effect.Internal.EcSignatureResult key)
ecSignatureUnavailable =
    Task.succeed (Effect.Internal.EcSignatureFailed Effect.Internal.CryptoSimulatedValueOutsideTest)


runEcdsa :
    Effect.Internal.EcSignatureOperation Crypto.EcdsaKey
    -> Task.Task x (Effect.Internal.EcSignatureResult Crypto.EcdsaKey)
runEcdsa operation =
    case operation of
        Effect.Internal.GenerateEcSignatureKeyPair context params ->
            case browserContext context of
                Just secureContext ->
                    ecSignatureKeyPair (Crypto.generateEcdsaKeyPair secureContext params)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.ImportEcSignaturePublicKeyFromRaw context namedCurve bytes ->
            case browserContext context of
                Just secureContext ->
                    ecSignaturePublicKey (Crypto.importEcdsaPublicKeyFromRaw secureContext namedCurve bytes)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.ImportEcSignaturePublicKeyFromSpki context namedCurve bytes ->
            case browserContext context of
                Just secureContext ->
                    ecSignaturePublicKey (Crypto.importEcdsaPublicKeyFromSpki secureContext namedCurve bytes)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.ImportEcSignaturePublicKeyFromJwk context namedCurve jwk ->
            case browserContext context of
                Just secureContext ->
                    ecSignaturePublicKey (Crypto.importEcdsaPublicKeyFromJwk secureContext namedCurve jwk)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.ImportEcSignaturePrivateKeyFromPkcs8 context extractable namedCurve bytes ->
            case browserContext context of
                Just secureContext ->
                    ecSignaturePrivateKey (Crypto.importEcdsaPrivateKeyFromPkcs8 secureContext extractable namedCurve bytes)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.ImportEcSignaturePrivateKeyFromSpki context extractable namedCurve bytes ->
            case browserContext context of
                Just secureContext ->
                    ecSignaturePrivateKey (Crypto.importEcdsaPrivateKeyFromSpki secureContext extractable namedCurve bytes)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.ImportEcSignaturePrivateKeyFromJwk context extractable namedCurve jwk ->
            case browserContext context of
                Just secureContext ->
                    ecSignaturePrivateKey (Crypto.importEcdsaPrivateKeyFromJwk secureContext extractable namedCurve jwk)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.ExportEcSignaturePublicKeyAsRaw key ->
            case browserPublicKey key of
                Just realKey ->
                    ecSignatureBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportEcdsaPublicKeyAsRaw realKey)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.ExportEcSignaturePublicKeyAsSpki key ->
            case browserPublicKey key of
                Just realKey ->
                    ecSignatureBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportEcdsaPublicKeyAsSpki realKey)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.ExportEcSignaturePublicKeyAsJwk key ->
            case browserPublicKey key of
                Just realKey ->
                    ecSignatureJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportEcdsaPublicKeyAsJwk realKey)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.ExportEcSignaturePrivateKeyAsPkcs8 key ->
            case browserPrivateKey key of
                Just realKey ->
                    ecSignatureBytes Effect.Internal.CryptoKeyNotExportable (Crypto.exportEcdsaPrivateKeyAsPkcs8 realKey)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.ExportEcSignaturePrivateKeyAsJwk key ->
            case browserPrivateKey key of
                Just realKey ->
                    ecSignatureJwk Effect.Internal.CryptoKeyNotExportable (Crypto.exportEcdsaPrivateKeyAsJwk realKey)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.SignWithEcPrivateKey hash key bytes ->
            case browserPrivateKey key of
                Just realKey ->
                    ecSignatureBytes Effect.Internal.CryptoSigningFailed (Crypto.signWithEcdsa hash realKey bytes)

                Nothing ->
                    ecSignatureUnavailable

        Effect.Internal.VerifyWithEcPublicKey hash key signature bytes ->
            case browserPublicKey key of
                Just realKey ->
                    ecSignatureBytes Effect.Internal.CryptoVerificationFailed (Crypto.verifyWithEcdsa hash realKey signature bytes)

                Nothing ->
                    ecSignatureUnavailable


runPlain : Effect.Internal.PlainOperation -> Task.Task x Effect.Internal.PlainResult
runPlain operation =
    case operation of
        Effect.Internal.GetSecureContext ->
            Crypto.getSecureContext
                |> Task.map (Effect.Internal.BrowserSecureContext >> Effect.Internal.GotSecureContext)
                |> Task.onError (\_ -> Task.succeed (Effect.Internal.PlainFailed Effect.Internal.CryptoNotASecureContext))

        Effect.Internal.RandomUuid context ->
            case browserContext context of
                Just secureContext ->
                    Crypto.randomUuidV4 secureContext |> Task.map Effect.Internal.GotUuid

                Nothing ->
                    plainUnavailable

        Effect.Internal.GetRandomValues valueType count ->
            (case valueType of
                Effect.Internal.RandomInt8 ->
                    Crypto.getRandomInt8Values count

                Effect.Internal.RandomUInt8 ->
                    Crypto.getRandomUInt8Values count

                Effect.Internal.RandomInt16 ->
                    Crypto.getRandomInt16Values count

                Effect.Internal.RandomUInt16 ->
                    Crypto.getRandomUInt16Values count

                Effect.Internal.RandomInt32 ->
                    Crypto.getRandomInt32Values count

                Effect.Internal.RandomUInt32 ->
                    Crypto.getRandomUInt32Values count
            )
                |> Task.map Effect.Internal.GotPlainBytes

        Effect.Internal.Digest context algorithm bytes ->
            case browserContext context of
                Just secureContext ->
                    Crypto.digest secureContext algorithm bytes |> Task.map Effect.Internal.GotPlainBytes

                Nothing ->
                    plainUnavailable


plainUnavailable : Task.Task x Effect.Internal.PlainResult
plainUnavailable =
    Task.succeed (Effect.Internal.PlainFailed Effect.Internal.CryptoSimulatedValueOutsideTest)


toSub : Subscription restriction msg -> Sub msg
toSub sub =
    case sub of
        SubBatch subs ->
            List.map toSub subs |> Sub.batch

        SubNone ->
            Sub.none

        TimeEvery duration msg ->
            Time.every (Duration.inMilliseconds duration) msg

        OnAnimationFrame msg ->
            Browser.Events.onAnimationFrame msg

        OnAnimationFrameDelta msg ->
            Browser.Events.onAnimationFrameDelta (Duration.milliseconds >> msg)

        OnKeyPress decoder ->
            Browser.Events.onKeyPress decoder

        OnKeyDown decoder ->
            Browser.Events.onKeyDown decoder

        OnKeyUp decoder ->
            Browser.Events.onKeyUp decoder

        OnClick decoder ->
            Browser.Events.onClick decoder

        OnMouseMove decoder ->
            Browser.Events.onMouseMove decoder

        OnMouseDown decoder ->
            Browser.Events.onMouseDown decoder

        OnMouseUp decoder ->
            Browser.Events.onMouseUp decoder

        OnVisibilityChange msg ->
            Browser.Events.onVisibilityChange
                (\visibility ->
                    case visibility of
                        Browser.Events.Visible ->
                            msg Visible

                        Browser.Events.Hidden ->
                            msg Hidden
                )

        OnResize msg ->
            Browser.Events.onResize msg

        SubPort _ portFunction _ ->
            portFunction

        SubPortBytes _ portFunction _ ->
            portFunction

        OnConnect msg ->
            Lamdera.onConnect
                (\sessionId clientId ->
                    msg (Effect.Internal.SessionId sessionId) (Effect.Internal.ClientId clientId)
                )

        OnDisconnect msg ->
            Lamdera.onDisconnect
                (\sessionId clientId ->
                    msg (Effect.Internal.SessionId sessionId) (Effect.Internal.ClientId clientId)
                )

        HttpTrack string function ->
            Http.track string function

        WebsocketListen connection onData onClose ->
            Websocket.listen connection onData onClose
