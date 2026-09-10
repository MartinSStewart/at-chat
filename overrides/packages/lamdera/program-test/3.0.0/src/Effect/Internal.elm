module Effect.Internal exposing
    ( BackendOnly
    , Bigger(..)
    , BrowserDomError(..)
    , CipherOperation(..)
    , CipherResult(..)
    , ClientId(..)
    , Command(..)
    , CryptoError(..)
    , CryptoKey(..)
    , CryptoPrivateKey(..)
    , CryptoPublicKey(..)
    , CryptoSecureContext(..)
    , EcSignatureOperation(..)
    , EcSignatureResult(..)
    , File(..)
    , FileUploadContent(..)
    , FrontendOnly
    , HttpBody(..)
    , HttpExpect(..)
    , HttpPart(..)
    , HttpRequest
    , MacOperation(..)
    , MacResult(..)
    , NavigationKey(..)
    , PlainOperation(..)
    , PlainResult(..)
    , PublicKeyCipherOperation(..)
    , PublicKeyCipherResult(..)
    , RandomValueType(..)
    , Resize(..)
    , RsaSignatureOperation(..)
    , RsaSignatureResult(..)
    , SessionId(..)
    , SimulatedKeyData
    , Smaller(..)
    , Subscription(..)
    , Task(..)
    , TrackedHttpRequest
    , Visibility(..)
    , Wrap(..)
    , XrButton
    , XrEyeType(..)
    , XrHandedness(..)
    , XrInput
    , XrPose
    , XrRenderError(..)
    , XrStartData
    , XrStartError(..)
    , XrView
    , andThen
    , mapTrackedHttpRequest
    , taskMap
    , taskMapError
    , trackedHttpRequestToTask
    )

import Browser.Dom
import Browser.Events
import Browser.Navigation
import Bytes exposing (Bytes)
import Crypto
import Duration exposing (Duration)
import File
import Http
import Json.Decode
import Json.Encode
import Lamdera
import Math.Matrix4 exposing (Mat4)
import Math.Vector2 exposing (Vec2)
import Time
import WebGL
import WebGLFix.Internal
import WebGLFix.Texture
import Websocket


type SessionId
    = SessionId String


type ClientId
    = ClientId String


type FrontendOnly
    = FrontendOnly Never


type BackendOnly
    = BackendOnly Never


type Subscription restriction msg
    = SubBatch (List (Subscription restriction msg))
    | SubNone
    | TimeEvery Duration (Time.Posix -> msg)
    | OnAnimationFrame (Time.Posix -> msg)
    | OnAnimationFrameDelta (Duration -> msg)
    | OnKeyPress (Json.Decode.Decoder msg)
    | OnKeyDown (Json.Decode.Decoder msg)
    | OnKeyUp (Json.Decode.Decoder msg)
    | OnClick (Json.Decode.Decoder msg)
    | OnMouseMove (Json.Decode.Decoder msg)
    | OnMouseDown (Json.Decode.Decoder msg)
    | OnMouseUp (Json.Decode.Decoder msg)
    | OnResize (Int -> Int -> msg)
    | OnVisibilityChange (Visibility -> msg)
    | SubPort String (Sub msg) (Json.Decode.Value -> msg)
    | SubPortBytes String (Sub msg) (Bytes -> msg)
    | OnConnect (SessionId -> ClientId -> msg)
    | OnDisconnect (SessionId -> ClientId -> msg)
    | HttpTrack String (Http.Progress -> msg)
    | WebsocketListen Websocket.Connection (String -> msg) ({ code : Websocket.CloseEventCode, reason : String } -> msg)


type Visibility
    = Visible
    | Hidden


type Command restriction toMsg msg
    = Batch (List (Command restriction toMsg msg))
    | None
    | SendToBackend toMsg
    | NavigationPushUrl NavigationKey String
    | NavigationReplaceUrl NavigationKey String
    | NavigationBack NavigationKey Int
    | NavigationForward NavigationKey Int
    | NavigationLoad String
    | NavigationReload
    | NavigationReloadAndSkipCache
    | Task (Task restriction msg msg)
    | Port String (Json.Encode.Value -> Cmd msg) Json.Encode.Value
    | PortBytes String (Bytes -> Cmd msg) Bytes
    | SendToFrontend ClientId toMsg
    | SendToFrontends SessionId toMsg
    | Broadcast toMsg
    | FileDownloadUrl { href : String }
    | FileDownloadString { name : String, mimeType : String, content : String }
    | FileDownloadBytes { name : String, mimeType : String, content : Bytes }
    | FileSelectFile (List String) (File -> msg)
    | FileSelectFiles (List String) (File -> List File -> msg)
    | HttpCancel String
    | HttpTrackedRequest (TrackedHttpRequest msg)
    | Passthrough (Cmd msg)


type Task restriction x a
    = Succeed a
    | Fail x
    | HttpStringTask (HttpRequest String restriction x a)
    | HttpBytesTask (HttpRequest Bytes restriction x a)
    | SleepTask Duration (() -> Task restriction x a)
    | TimeNow (Time.Posix -> Task restriction x a)
    | TimeHere (Time.Zone -> Task restriction x a)
    | TimeGetZoneName (Time.ZoneName -> Task restriction x a)
    | Focus String (Result BrowserDomError () -> Task restriction x a)
    | Blur String (Result BrowserDomError () -> Task restriction x a)
    | GetViewport (Browser.Dom.Viewport -> Task restriction x a)
    | SetViewport Float Float (() -> Task restriction x a)
    | GetViewportOf String (Result BrowserDomError Browser.Dom.Viewport -> Task restriction x a)
    | SetViewportOf String Float Float (Result BrowserDomError () -> Task restriction x a)
    | GetElement String (Result BrowserDomError Browser.Dom.Element -> Task restriction x a)
    | FileToString File (String -> Task restriction x a)
    | FileToBytes File (Bytes -> Task restriction x a)
    | FileToUrl File (String -> Task restriction x a)
    | LoadTexture LoadTextureOptions String (Result WebGLFix.Texture.Error WebGLFix.Texture.Texture -> Task restriction x a)
    | RequestXrStart (List WebGLFix.Internal.Option) (Result XrStartError XrStartData -> Task restriction x a)
    | RenderXrFrame ({ time : Float, xrView : XrView, inputs : List XrInput } -> List WebGL.Entity) (Result XrRenderError XrPose -> Task restriction x a)
    | EndXrSession (() -> Task restriction x a)
    | WebsocketCreateHandle String (Websocket.Connection -> Task restriction x a)
    | WebsocketSendString Websocket.Connection String (Result Websocket.SendError () -> Task restriction x a)
    | WebsocketClose Websocket.Connection (() -> Task restriction x a)
    | CryptoTaskAesCtr (CipherOperation Crypto.AesCtrKey Crypto.AesKeyParams Crypto.AesCtrParams) (CipherResult Crypto.AesCtrKey Crypto.AesKeyParams -> Task restriction x a)
    | CryptoTaskAesCbc (CipherOperation Crypto.AesCbcKey Crypto.AesKeyParams Crypto.AesCbcParams) (CipherResult Crypto.AesCbcKey Crypto.AesKeyParams -> Task restriction x a)
    | CryptoTaskAesGcm (CipherOperation Crypto.AesGcmKey Crypto.AesKeyParams Crypto.AesGcmParams) (CipherResult Crypto.AesGcmKey Crypto.AesKeyParams -> Task restriction x a)
    | CryptoTaskHmac (MacOperation Crypto.HmacKey Crypto.HmacKeyParams) (MacResult Crypto.HmacKey Crypto.HmacKeyParams -> Task restriction x a)
    | CryptoTaskRsaOaep (PublicKeyCipherOperation Crypto.RsaOaepKey Crypto.RsaOaepParams) (PublicKeyCipherResult Crypto.RsaOaepKey -> Task restriction x a)
    | CryptoTaskRsaPss (RsaSignatureOperation Crypto.RsaPssKey Crypto.RsaPssParams) (RsaSignatureResult Crypto.RsaPssKey -> Task restriction x a)
    | CryptoTaskRsaSsaPkcs1V1_5 (RsaSignatureOperation Crypto.RsaSsaPkcs1V1_5Key ()) (RsaSignatureResult Crypto.RsaSsaPkcs1V1_5Key -> Task restriction x a)
    | CryptoTaskEcdsa (EcSignatureOperation Crypto.EcdsaKey) (EcSignatureResult Crypto.EcdsaKey -> Task restriction x a)
    | CryptoTaskPlain PlainOperation (PlainResult -> Task restriction x a)


type alias XrPose =
    { transform : Mat4
    , views : List XrView
    , time : Float
    , boundary : Maybe (List Vec2)
    , inputs : List XrInput
    }


type alias XrInput =
    { handedness : XrHandedness, matrix : Maybe Mat4, buttons : List XrButton, axes : List Float, mapping : String }


type alias XrButton =
    { isPressed : Bool, isTouched : Bool, value : Float }


type XrHandedness
    = LeftHand
    | RightHand
    | Unknown


type alias XrView =
    { eye : XrEyeType, projectionMatrix : Mat4, viewMatrix : Mat4 }


type XrEyeType
    = LeftEye
    | RightEye
    | OtherEye


type XrStartError
    = AlreadyStarted
    | NotSupported


type alias XrStartData =
    { boundary : Maybe (List Vec2), supportedFrameRates : List Int }


type XrRenderError
    = XrSessionNotStarted
    | XrLostTracking


type Bigger
    = Bigger


type Smaller
    = Smaller


type Wrap
    = Repeat
    | ClampToEdge
    | MirroredRepeat


type Resize a
    = Linear
    | Nearest
    | NearestMipmapNearest
    | LinearMipmapNearest
    | NearestMipmapLinear
    | LinearMipmapLinear


type alias LoadTextureOptions =
    { magnify : Resize Bigger
    , minify : Resize Smaller
    , horizontalWrap : Wrap
    , verticalWrap : Wrap
    , flipY : Bool
    , premultiplyAlpha : Bool
    }


type NavigationKey
    = RealNavigationKey Browser.Navigation.Key
    | MockNavigationKey


type BrowserDomError
    = BrowserDomNotFound String


type File
    = RealFile File.File
    | MockFile { name : String, mimeType : String, content : FileUploadContent, lastModified : Time.Posix }


{-| The type of data stored in a file
-}
type FileUploadContent
    = BytesFile Bytes
    | StringFile String


{-| Proof that Web Crypto is available. `BrowserSecureContext` only ever comes out of
`Effect.Lamdera`, and `SimulatedSecureContext` only ever out of `Effect.Test`, so an
interpreter never sees the other one's.
-}
type CryptoSecureContext
    = BrowserSecureContext Crypto.SecureContext
    | SimulatedSecureContext


{-| What a simulated key carries. A browser key is a handle the page cannot read, but a
test has to compute with the key material itself, so the simulated branch holds bytes.
-}
type alias SimulatedKeyData keyData =
    { keyBytes : Bytes, data : keyData }


{-| A secret key.
-}
type CryptoKey key keyData
    = BrowserCryptoKey (Crypto.Key key keyData)
    | SimulatedCryptoKey (SimulatedKeyData keyData)


{-| A public key.
-}
type CryptoPublicKey key keyData
    = BrowserCryptoPublicKey (Crypto.PublicKey key keyData)
    | SimulatedCryptoPublicKey (SimulatedKeyData keyData)


{-| A private key.
-}
type CryptoPrivateKey key keyData
    = BrowserCryptoPrivateKey (Crypto.PrivateKey key keyData)
    | SimulatedCryptoPrivateKey (SimulatedKeyData keyData)


{-| Why a crypto operation did not produce a result. Each `Effect.Crypto` function knows
which operation it issued, so it maps this to that operation's own error type.
-}
type CryptoError
    = CryptoKeyGenerationFailed
    | CryptoKeyImportFailed
    | CryptoKeyNotExportable
    | CryptoEncryptionFailed
    | CryptoDecryptionFailed
    | CryptoSigningFailed
    | CryptoVerificationFailed
    | CryptoNotASecureContext
    | CryptoSimulatedValueOutsideTest


{-| Which width and signedness of random values to generate.
-}
type RandomValueType
    = RandomInt8
    | RandomUInt8
    | RandomInt16
    | RandomUInt16
    | RandomInt32
    | RandomUInt32


{-| The operations that need no key. One `Task` variant covers all of them.
-}
type PlainOperation
    = GetSecureContext
    | RandomUuid CryptoSecureContext
    | GetRandomValues RandomValueType Int
    | Digest CryptoSecureContext Crypto.DigestAlgorithm Bytes


{-| -}
type PlainResult
    = GotSecureContext CryptoSecureContext
    | GotUuid String
    | GotPlainBytes Bytes
    | PlainFailed CryptoError


{-| The operations a symmetric cipher supports. AES-CTR, AES-CBC and AES-GCM share this,
differing only in `params`, so an interpreter can handle all three at once wherever the
params do not matter.
-}
type CipherOperation key keyData params
    = GenerateCipherKey CryptoSecureContext keyData
    | ImportCipherKeyFromRaw CryptoSecureContext Crypto.Extractable Bytes
    | ImportCipherKeyFromJwk CryptoSecureContext Crypto.Extractable Json.Encode.Value
    | ExportCipherKeyAsRaw (CryptoKey key keyData)
    | ExportCipherKeyAsJwk (CryptoKey key keyData)
    | Encrypt params (CryptoKey key keyData) Bytes
    | Decrypt params (CryptoKey key keyData) Bytes


{-| -}
type CipherResult key keyData
    = GotCipherKey (CryptoKey key keyData)
    | GotCipherBytes Bytes
    | GotCipherJwk Json.Encode.Value
    | CipherFailed CryptoError


{-| The operations a message authentication code supports. Only HMAC uses this.
-}
type MacOperation key keyData
    = GenerateMacKey CryptoSecureContext keyData
    | ImportMacKeyFromRaw CryptoSecureContext Crypto.Extractable Crypto.DigestAlgorithm (Maybe Int) Bytes
    | ImportMacKeyFromJwk CryptoSecureContext Crypto.Extractable Crypto.DigestAlgorithm (Maybe Int) Json.Encode.Value
    | ExportMacKeyAsRaw (CryptoKey key keyData)
    | ExportMacKeyAsJwk (CryptoKey key keyData)
    | SignWithMacKey (CryptoKey key keyData) Bytes
    | VerifyWithMacKey (CryptoKey key keyData) Bytes Bytes


{-| -}
type MacResult key keyData
    = GotMacKey (CryptoKey key keyData)
    | GotMacBytes Bytes
    | GotMacJwk Json.Encode.Value
    | MacFailed CryptoError


{-| The operations a public key cipher supports. Only RSA-OAEP uses this.
-}
type PublicKeyCipherOperation key params
    = GenerateCipherKeyPair CryptoSecureContext Crypto.RsaKeyParams
    | ImportCipherPublicKeyFromSpki CryptoSecureContext Crypto.ImportRsaKeyParams Bytes
    | ImportCipherPublicKeyFromJwk CryptoSecureContext Crypto.ImportRsaKeyParams Json.Encode.Value
    | ImportCipherPrivateKeyFromPkcs8 CryptoSecureContext Crypto.Extractable Crypto.ImportRsaKeyParams Bytes
    | ImportCipherPrivateKeyFromJwk CryptoSecureContext Crypto.Extractable Crypto.ImportRsaKeyParams Json.Encode.Value
    | ExportCipherPublicKeyAsSpki (CryptoPublicKey key Crypto.RsaKeyParams)
    | ExportCipherPublicKeyAsJwk (CryptoPublicKey key Crypto.RsaKeyParams)
    | ExportCipherPrivateKeyAsPkcs8 (CryptoPrivateKey key Crypto.RsaKeyParams)
    | ExportCipherPrivateKeyAsJwk (CryptoPrivateKey key Crypto.RsaKeyParams)
    | EncryptWithPublicKey params (CryptoPublicKey key Crypto.RsaKeyParams) Bytes
    | DecryptWithPrivateKey params (CryptoPrivateKey key Crypto.RsaKeyParams) Bytes


{-| -}
type PublicKeyCipherResult key
    = GotCipherKeyPair (CryptoPublicKey key Crypto.RsaKeyParams) (CryptoPrivateKey key Crypto.RsaKeyParams)
    | GotCipherPublicKey (CryptoPublicKey key Crypto.RsaKeyParams)
    | GotCipherPrivateKey (CryptoPrivateKey key Crypto.RsaKeyParams)
    | GotPublicKeyCipherBytes Bytes
    | GotPublicKeyCipherJwk Json.Encode.Value
    | PublicKeyCipherFailed CryptoError


{-| The operations an RSA signature algorithm supports. RSA-PSS and RSASSA-PKCS1-v1\_5
share this, differing only in the `params` their signing takes.
-}
type RsaSignatureOperation key params
    = GenerateRsaSignatureKeyPair CryptoSecureContext Crypto.RsaKeyParams
    | ImportRsaSignaturePublicKeyFromSpki CryptoSecureContext Crypto.ImportRsaKeyParams Bytes
    | ImportRsaSignaturePublicKeyFromJwk CryptoSecureContext Crypto.ImportRsaKeyParams Json.Encode.Value
    | ImportRsaSignaturePrivateKeyFromPkcs8 CryptoSecureContext Crypto.Extractable Crypto.ImportRsaKeyParams Bytes
    | ImportRsaSignaturePrivateKeyFromJwk CryptoSecureContext Crypto.Extractable Crypto.ImportRsaKeyParams Json.Encode.Value
    | ExportRsaSignaturePublicKeyAsSpki (CryptoPublicKey key Crypto.RsaKeyParams)
    | ExportRsaSignaturePublicKeyAsJwk (CryptoPublicKey key Crypto.RsaKeyParams)
    | ExportRsaSignaturePrivateKeyAsPkcs8 (CryptoPrivateKey key Crypto.RsaKeyParams)
    | ExportRsaSignaturePrivateKeyAsJwk (CryptoPrivateKey key Crypto.RsaKeyParams)
    | SignWithRsaPrivateKey params (CryptoPrivateKey key Crypto.RsaKeyParams) Bytes
    | VerifyWithRsaPublicKey params (CryptoPublicKey key Crypto.RsaKeyParams) Bytes Bytes


{-| -}
type RsaSignatureResult key
    = GotRsaSignatureKeyPair (CryptoPublicKey key Crypto.RsaKeyParams) (CryptoPrivateKey key Crypto.RsaKeyParams)
    | GotRsaSignaturePublicKey (CryptoPublicKey key Crypto.RsaKeyParams)
    | GotRsaSignaturePrivateKey (CryptoPrivateKey key Crypto.RsaKeyParams)
    | GotRsaSignatureBytes Bytes
    | GotRsaSignatureJwk Json.Encode.Value
    | RsaSignatureFailed CryptoError


{-| The operations an elliptic curve signature algorithm supports. Only ECDSA uses this.
-}
type EcSignatureOperation key
    = GenerateEcSignatureKeyPair CryptoSecureContext Crypto.EcKeyParams
    | ImportEcSignaturePublicKeyFromRaw CryptoSecureContext Crypto.EcNamedCurve Bytes
    | ImportEcSignaturePublicKeyFromSpki CryptoSecureContext Crypto.EcNamedCurve Bytes
    | ImportEcSignaturePublicKeyFromJwk CryptoSecureContext Crypto.EcNamedCurve Json.Encode.Value
    | ImportEcSignaturePrivateKeyFromPkcs8 CryptoSecureContext Crypto.Extractable Crypto.EcNamedCurve Bytes
    | ImportEcSignaturePrivateKeyFromSpki CryptoSecureContext Crypto.Extractable Crypto.EcNamedCurve Bytes
    | ImportEcSignaturePrivateKeyFromJwk CryptoSecureContext Crypto.Extractable Crypto.EcNamedCurve Json.Encode.Value
    | ExportEcSignaturePublicKeyAsRaw (CryptoPublicKey key Crypto.EcKeyParams)
    | ExportEcSignaturePublicKeyAsSpki (CryptoPublicKey key Crypto.EcKeyParams)
    | ExportEcSignaturePublicKeyAsJwk (CryptoPublicKey key Crypto.EcKeyParams)
    | ExportEcSignaturePrivateKeyAsPkcs8 (CryptoPrivateKey key Crypto.EcKeyParams)
    | ExportEcSignaturePrivateKeyAsJwk (CryptoPrivateKey key Crypto.EcKeyParams)
    | SignWithEcPrivateKey Crypto.DigestAlgorithm (CryptoPrivateKey key Crypto.EcKeyParams) Bytes
    | VerifyWithEcPublicKey Crypto.DigestAlgorithm (CryptoPublicKey key Crypto.EcKeyParams) Bytes Bytes


{-| -}
type EcSignatureResult key
    = GotEcSignatureKeyPair (CryptoPublicKey key Crypto.EcKeyParams) (CryptoPrivateKey key Crypto.EcKeyParams)
    | GotEcSignaturePublicKey (CryptoPublicKey key Crypto.EcKeyParams)
    | GotEcSignaturePrivateKey (CryptoPrivateKey key Crypto.EcKeyParams)
    | GotEcSignatureBytes Bytes
    | GotEcSignatureJwk Json.Encode.Value
    | EcSignatureFailed CryptoError


type alias HttpRequest data restriction x a =
    { method : String
    , url : String
    , body : HttpBody
    , headers : List ( String, String )
    , onRequestComplete : Http.Response data -> Task restriction x a
    , timeout : Maybe Duration
    , isRisky : Bool
    , tracker : Maybe String
    }


{-| An http request that has a tracker. Since `Http.task` doesn't support trackers, these requests are
represented as a command (which can be handled with `Http.request`) rather than as a task.
-}
type alias TrackedHttpRequest msg =
    { method : String
    , url : String
    , body : HttpBody
    , headers : List ( String, String )
    , expect : HttpExpect msg
    , timeout : Maybe Duration
    , isRisky : Bool
    , tracker : String
    }


type HttpExpect msg
    = ExpectStringResponse (Http.Response String -> msg)
    | ExpectBytesResponse (Http.Response Bytes -> msg)


mapTrackedHttpRequest : (a -> b) -> TrackedHttpRequest a -> TrackedHttpRequest b
mapTrackedHttpRequest mapMsg request =
    { method = request.method
    , url = request.url
    , body = request.body
    , headers = request.headers
    , expect =
        case request.expect of
            ExpectStringResponse onRequestComplete ->
                ExpectStringResponse (onRequestComplete >> mapMsg)

            ExpectBytesResponse onRequestComplete ->
                ExpectBytesResponse (onRequestComplete >> mapMsg)
    , timeout = request.timeout
    , isRisky = request.isRisky
    , tracker = request.tracker
    }


{-| Used when running a tracked http request in an environment that can't actually track progress
(such as `Effect.Test`). The tracker is kept so that it's still visible to whoever handles the request.
-}
trackedHttpRequestToTask : TrackedHttpRequest msg -> Task restriction msg msg
trackedHttpRequestToTask request =
    case request.expect of
        ExpectStringResponse onRequestComplete ->
            HttpStringTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = onRequestComplete >> Succeed
                , timeout = request.timeout
                , isRisky = request.isRisky
                , tracker = Just request.tracker
                }

        ExpectBytesResponse onRequestComplete ->
            HttpBytesTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = onRequestComplete >> Succeed
                , timeout = request.timeout
                , isRisky = request.isRisky
                , tracker = Just request.tracker
                }


type HttpBody
    = EmptyBody
    | StringBody
        { contentType : String
        , content : String
        }
    | JsonBody Json.Encode.Value
    | MultipartBody (List HttpPart)
    | BytesBody String Bytes
    | FileBody File


type HttpPart
    = StringPart String String
    | FilePart String File
    | BytesPart String String Bytes


taskMap : (a -> b) -> Task restriction x a -> Task restriction x b
taskMap f =
    andThen (f >> Succeed)


andThen : (a -> Task restriction x b) -> Task c x a -> Task restriction x b
andThen f task =
    case task of
        Succeed a ->
            f a

        Fail x ->
            Fail x

        HttpStringTask request ->
            HttpStringTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> andThen f
                , timeout = request.timeout
                , isRisky = request.isRisky
                , tracker = request.tracker
                }

        HttpBytesTask request ->
            HttpBytesTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> andThen f
                , timeout = request.timeout
                , isRisky = request.isRisky
                , tracker = request.tracker
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> andThen f)

        TimeNow gotTime ->
            TimeNow (gotTime >> andThen f)

        TimeHere gotTimeZone ->
            TimeHere (gotTimeZone >> andThen f)

        TimeGetZoneName gotTimeZoneName ->
            TimeGetZoneName (gotTimeZoneName >> andThen f)

        SetViewport x y function ->
            SetViewport x y (function >> andThen f)

        GetViewport function ->
            GetViewport (function >> andThen f)

        GetElement string function ->
            GetElement string (function >> andThen f)

        Focus string function ->
            Focus string (function >> andThen f)

        Blur string function ->
            Blur string (function >> andThen f)

        GetViewportOf string function ->
            GetViewportOf string (function >> andThen f)

        SetViewportOf string x y function ->
            SetViewportOf string x y (function >> andThen f)

        FileToString file function ->
            FileToString file (function >> andThen f)

        FileToBytes file function ->
            FileToBytes file (function >> andThen f)

        FileToUrl file function ->
            FileToUrl file (function >> andThen f)

        LoadTexture loadTextureOptions string function ->
            LoadTexture loadTextureOptions string (function >> andThen f)

        RequestXrStart options function ->
            RequestXrStart options (function >> andThen f)

        RenderXrFrame entities function ->
            RenderXrFrame entities (function >> andThen f)

        EndXrSession function ->
            EndXrSession (function >> andThen f)

        WebsocketCreateHandle url function ->
            WebsocketCreateHandle url (function >> andThen f)

        WebsocketSendString connection data function ->
            WebsocketSendString connection data (function >> andThen f)

        WebsocketClose connection function ->
            WebsocketClose connection (function >> andThen f)

        CryptoTaskAesCtr operation function ->
            CryptoTaskAesCtr operation (function >> andThen f)

        CryptoTaskAesCbc operation function ->
            CryptoTaskAesCbc operation (function >> andThen f)

        CryptoTaskAesGcm operation function ->
            CryptoTaskAesGcm operation (function >> andThen f)

        CryptoTaskHmac operation function ->
            CryptoTaskHmac operation (function >> andThen f)

        CryptoTaskRsaOaep operation function ->
            CryptoTaskRsaOaep operation (function >> andThen f)

        CryptoTaskRsaPss operation function ->
            CryptoTaskRsaPss operation (function >> andThen f)

        CryptoTaskRsaSsaPkcs1V1_5 operation function ->
            CryptoTaskRsaSsaPkcs1V1_5 operation (function >> andThen f)

        CryptoTaskEcdsa operation function ->
            CryptoTaskEcdsa operation (function >> andThen f)

        CryptoTaskPlain operation function ->
            CryptoTaskPlain operation (function >> andThen f)


taskMapError : (x -> y) -> Task restriction x a -> Task restriction y a
taskMapError f task =
    case task of
        Succeed a ->
            Succeed a

        Fail x ->
            Fail (f x)

        HttpStringTask request ->
            HttpStringTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> taskMapError f
                , timeout = request.timeout
                , isRisky = request.isRisky
                , tracker = request.tracker
                }

        HttpBytesTask request ->
            HttpBytesTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> taskMapError f
                , timeout = request.timeout
                , isRisky = request.isRisky
                , tracker = request.tracker
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> taskMapError f)

        TimeNow gotTime ->
            TimeNow (gotTime >> taskMapError f)

        TimeHere gotTimeZone ->
            TimeHere (gotTimeZone >> taskMapError f)

        TimeGetZoneName gotTimeZoneName ->
            TimeGetZoneName (gotTimeZoneName >> taskMapError f)

        SetViewport x y function ->
            SetViewport x y (function >> taskMapError f)

        GetViewport function ->
            GetViewport (function >> taskMapError f)

        GetElement string function ->
            GetElement string (function >> taskMapError f)

        Focus string function ->
            Focus string (function >> taskMapError f)

        Blur string function ->
            Blur string (function >> taskMapError f)

        GetViewportOf string function ->
            GetViewportOf string (function >> taskMapError f)

        SetViewportOf string x y function ->
            SetViewportOf string x y (function >> taskMapError f)

        FileToString file function ->
            FileToString file (function >> taskMapError f)

        FileToBytes file function ->
            FileToBytes file (function >> taskMapError f)

        FileToUrl file function ->
            FileToUrl file (function >> taskMapError f)

        LoadTexture loadTextureOptions string function ->
            LoadTexture loadTextureOptions string (function >> taskMapError f)

        RequestXrStart options function ->
            RequestXrStart options (function >> taskMapError f)

        RenderXrFrame entities function ->
            RenderXrFrame entities (function >> taskMapError f)

        EndXrSession function ->
            EndXrSession (function >> taskMapError f)

        WebsocketCreateHandle url function ->
            WebsocketCreateHandle url (function >> taskMapError f)

        WebsocketSendString connection data function ->
            WebsocketSendString connection data (function >> taskMapError f)

        WebsocketClose connection function ->
            WebsocketClose connection (function >> taskMapError f)

        CryptoTaskAesCtr operation function ->
            CryptoTaskAesCtr operation (function >> taskMapError f)

        CryptoTaskAesCbc operation function ->
            CryptoTaskAesCbc operation (function >> taskMapError f)

        CryptoTaskAesGcm operation function ->
            CryptoTaskAesGcm operation (function >> taskMapError f)

        CryptoTaskHmac operation function ->
            CryptoTaskHmac operation (function >> taskMapError f)

        CryptoTaskRsaOaep operation function ->
            CryptoTaskRsaOaep operation (function >> taskMapError f)

        CryptoTaskRsaPss operation function ->
            CryptoTaskRsaPss operation (function >> taskMapError f)

        CryptoTaskRsaSsaPkcs1V1_5 operation function ->
            CryptoTaskRsaSsaPkcs1V1_5 operation (function >> taskMapError f)

        CryptoTaskEcdsa operation function ->
            CryptoTaskEcdsa operation (function >> taskMapError f)

        CryptoTaskPlain operation function ->
            CryptoTaskPlain operation (function >> taskMapError f)
