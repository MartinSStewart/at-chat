module TwoFactorAuthentication exposing
    ( Msg(..)
    , ToBackend(..)
    , ToFrontend(..)
    , TwoFactorAuthentication
    , TwoFactorAuthenticationSetup
    , TwoFactorSecret(..)
    , TwoFactorSetupData
    , TwoFactorState(..)
    , getCode
    , getConfig
    , isPressMsg
    , isValidCode
    , update
    , updateFromBackend
    , view
    )

import Duration
import Effect.Browser.Dom as Dom
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera
import Effect.Time as Time
import LoginForm exposing (CodeStatus(..))
import MyUi
import Ports
import QRCode
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import TOTP.Algorithm
import TOTP.Key
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import Ui.Prose


type alias TwoFactorAuthentication =
    { secret : SecretId TwoFactorSecret
    , finishedAt : Time.Posix
    }


type alias TwoFactorAuthenticationSetup =
    { secret : SecretId TwoFactorSecret
    , startedAt : Time.Posix
    }


type TwoFactorSecret
    = TwoFactorSecret Never


getConfig : String -> SecretId TwoFactorSecret -> Result String TOTP.Key.Key
getConfig user secret =
    TOTP.Key.init
        { issuer = "atchat"
        , user = user
        , rawSecret = SecretId.toString secret
        , outputLength =
            -- We can leave this as nothing since the default is 6 and not including it makes the QR code a bit smaller
            Nothing
        , periodSeconds =
            -- We can leave this as nothing since the default is 30 and not including it makes the QR code a bit smaller
            Nothing
        , algorithm =
            -- You can't change this value. Google Authenticator will ignore this setting and always use SHA1. If you change this, it will make it impossible for anyone setting up 2FA to use Google Authenticator.
            TOTP.Algorithm.SHA1
        }


{-| You can't change this value. Google Authenticator will ignore this setting and always use 30. If you change this, it will make it impossible for anyone setting up 2FA to use Google Authenticator.
-}
periodSeconds : number
periodSeconds =
    30


isValidCode : Time.Posix -> Int -> SecretId TwoFactorSecret -> Bool
isValidCode time code secret =
    case getConfig "" secret of
        Ok config ->
            List.any
                (\t ->
                    case getCode t config of
                        Just expectedCode ->
                            expectedCode == code

                        Nothing ->
                            False
                )
                [ time
                , Duration.addTo time (Duration.seconds periodSeconds)
                , Duration.addTo time (Duration.seconds -periodSeconds)
                ]

        Err _ ->
            False


getCode : Time.Posix -> TOTP.Key.Key -> Maybe Int
getCode time config =
    case TOTP.Key.code time config of
        Ok ok ->
            String.toInt ok

        Err _ ->
            Nothing


type TwoFactorState
    = TwoFactorNotStarted
    | TwoFactorLoading
    | TwoFactorSetup TwoFactorSetupData
    | TwoFactorComplete
    | TwoFactorAlreadyComplete Time.Posix


type alias TwoFactorSetupData =
    { qrCodeUrl : String, code : String, attempts : SeqDict Int CodeStatus }


type Msg
    = PressedStart2FaSetup
    | PressedCopy String
    | TypedTwoFactorCode String


type ToBackend
    = EnableTwoFactorAuthenticationRequest
    | ConfirmTwoFactorAuthenticationRequest Int


type ToFrontend
    = EnableTwoFactorAuthenticationResponse { qrCodeUrl : String }
    | ConfirmTwoFactorAuthenticationResponse Int Bool


update : Msg -> TwoFactorState -> ( TwoFactorState, Command FrontendOnly ToBackend Msg )
update msg twoFactorStatus =
    case msg of
        PressedStart2FaSetup ->
            case twoFactorStatus of
                TwoFactorNotStarted ->
                    ( TwoFactorLoading
                    , Lamdera.sendToBackend EnableTwoFactorAuthenticationRequest
                    )

                _ ->
                    ( twoFactorStatus, Command.none )

        PressedCopy text ->
            ( twoFactorStatus, Ports.copyToClipboard text )

        TypedTwoFactorCode code ->
            case twoFactorStatus of
                TwoFactorSetup state ->
                    let
                        ( state2, cmd ) =
                            LoginForm.typedCode
                                LoginForm.twoFactorCodeLength
                                (\a -> Lamdera.sendToBackend (ConfirmTwoFactorAuthenticationRequest a))
                                code
                                { state | attempts = SeqDict.empty }
                    in
                    ( TwoFactorSetup state2, cmd )

                _ ->
                    ( twoFactorStatus, Command.none )


updateFromBackend : ToFrontend -> TwoFactorState -> TwoFactorState
updateFromBackend toFrontend model =
    case toFrontend of
        EnableTwoFactorAuthenticationResponse { qrCodeUrl } ->
            case model of
                TwoFactorLoading ->
                    TwoFactorSetup
                        { qrCodeUrl = qrCodeUrl
                        , code = ""
                        , attempts = SeqDict.empty
                        }

                _ ->
                    model

        ConfirmTwoFactorAuthenticationResponse code isSuccessful ->
            case model of
                TwoFactorSetup data ->
                    if isSuccessful then
                        TwoFactorComplete

                    else
                        TwoFactorSetup
                            { data
                                | attempts =
                                    SeqDict.insert code NotValid data.attempts
                            }

                _ ->
                    model


view : Bool -> Time.Posix -> TwoFactorState -> Element Msg
view isMobile time twoFactorStatus =
    MyUi.container
        isMobile
        "Two-factor authentication"
        [ case twoFactorStatus of
            TwoFactorNotStarted ->
                MyUi.simpleButton
                    (Dom.id "userOverview_start2FaSetup")
                    PressedStart2FaSetup
                    (Ui.text "Add two factor authentication")

            TwoFactorLoading ->
                MyUi.simpleButton
                    (Dom.id "userOverview_start2FaSetup")
                    PressedStart2FaSetup
                    (Ui.text "Loading...")

            TwoFactorSetup data ->
                setupView isMobile data

            TwoFactorComplete ->
                Ui.column
                    []
                    [ Ui.el [ Ui.Font.size 18, Ui.Font.bold, Ui.paddingXY 0 4 ] (Ui.text "Two factor authentication enabled!")
                    , Ui.text "Next time you log in you'll be prompted to use your authenticator app in addition to the normal login."
                    ]

            TwoFactorAlreadyComplete enabledAt ->
                Ui.Prose.paragraph
                    [ Ui.paddingXY 0 4 ]
                    [ Ui.text "Two factor authentication was enabled "
                    , MyUi.timeElapsedView time enabledAt
                    , Ui.text "."
                    ]
        ]


setupView : Bool -> TwoFactorSetupData -> Element Msg
setupView isMobile { qrCodeUrl, code, attempts } =
    case QRCode.fromString qrCodeUrl of
        Ok qrCode ->
            let
                label : { element : Element msg, id : Ui.Input.Label }
                label =
                    Ui.Input.label
                        "userOverview_twoFactorCodeInput"
                        []
                        (Ui.text
                            ("The app will provide you with a "
                                ++ String.fromInt LoginForm.twoFactorCodeLength
                                ++ " digit code. Enter that code here:"
                            )
                        )

                step : Int -> Element msg -> Element msg
                step count content =
                    Ui.column
                        []
                        [ Ui.el
                            [ Ui.Font.bold ]
                            (Ui.text ("Step " ++ String.fromInt count))
                        , content
                        ]

                link : String -> String -> Element msg
                link text url =
                    Ui.el
                        [ Ui.linkNewTab url
                        , Ui.Font.color MyUi.textLinkColor
                        ]
                        (Ui.text text)
            in
            Ui.column
                [ Ui.spacing 24 ]
                [ Ui.el
                    [ Ui.Font.size 20
                    , Ui.Font.bold
                    ]
                    (Ui.text "In order to setup two factor authentication, please do the following steps.")
                , step 1
                    (Ui.Prose.paragraph
                        [ Ui.paddingXY 0 4 ]
                        [ Ui.text "Install Google Authenticator ("
                        , link "Apple" "https://apps.apple.com/us/app/google-authenticator/id388497605"
                        , Ui.text ", "
                        , link "Android" "https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2&hl=en-US"
                        , Ui.text ") or Microsoft Authenticator ("
                        , link "Apple" "https://apps.apple.com/us/app/microsoft-authenticator/id983156458"
                        , Ui.text ", "
                        , link "Android" "https://play.google.com/store/apps/details?id=com.azure.authenticator&hl=en-us"
                        , Ui.text ") onto your mobile device."
                        ]
                    )
                , step 2
                    (Ui.column
                        [ Ui.spacing 8 ]
                        [ Ui.text "Scan this QR code using the app"
                        , Ui.el
                            [ Ui.background MyUi.white
                            , Ui.padding 12
                            , Ui.rounded 8
                            , Ui.width Ui.shrink
                            , if isMobile then
                                Ui.centerX

                              else
                                Ui.noAttr
                            ]
                            (QRCode.toSvgWithoutQuietZone
                                [ MyUi.widthAttr 260, MyUi.heightAttr 260 ]
                                qrCode
                                |> Ui.html
                            )
                        ]
                    )
                , step 3
                    (Ui.column
                        [ Ui.spacing 8 ]
                        [ label.element
                        , LoginForm.loginCodeInput LoginForm.twoFactorCodeLength TypedTwoFactorCode code label
                        , case LoginForm.validateCode LoginForm.twoFactorCodeLength code of
                            Ok code2 ->
                                case SeqDict.get code2 attempts of
                                    Just NotValid ->
                                        LoginForm.errorView "Incorrect code"

                                    _ ->
                                        Ui.Prose.paragraph
                                            []
                                            [ Ui.text "Submitting..." ]

                            Err error ->
                                LoginForm.errorView error
                        ]
                    )
                ]

        Err _ ->
            MyUi.errorBox
                (Dom.id "userOverview_qrCodeError")
                PressedCopy
                "Something went wrong when setting up two factor authentication"


isPressMsg : Msg -> Bool
isPressMsg msg =
    case msg of
        PressedStart2FaSetup ->
            True

        PressedCopy _ ->
            True

        TypedTwoFactorCode _ ->
            False
