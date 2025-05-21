module Pages.UserOverview exposing
    ( Config
    , Model(..)
    , Msg(..)
    , PersonalViewData
    , ToBackend(..)
    , ToFrontend(..)
    , TwoFactorSetupData
    , TwoFactorState(..)
    , init
    , update
    , updateFromBackend
    , view
    )

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Effect.Browser.Dom as Dom
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera
import Id exposing (Id, UserId)
import LocalState exposing (LocalState)
import LoginForm exposing (CodeStatus(..))
import MyUi
import PersonName
import Ports
import QRCode
import SeqDict exposing (SeqDict)
import Time
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import Ui.Prose
import User exposing (BackendUser, EmailNotifications(..))


{-| OpaqueVariants
-}
type Model
    = PublicView
    | PersonalView PersonalViewData


type alias PersonalViewData =
    { twoFactorStatus : TwoFactorState }


type TwoFactorState
    = TwoFactorNotStarted
    | TwoFactorLoading
    | TwoFactorSetup TwoFactorSetupData
    | TwoFactorComplete
    | TwoFactorAlreadyComplete Time.Posix


type alias TwoFactorSetupData =
    { qrCodeUrl : String, code : String, attempts : SeqDict Int CodeStatus }


type Msg
    = SelectedNotificationFrequency EmailNotifications
    | PressedStart2FaSetup
    | PressedCopyError String
    | TypedTwoFactorCode String


type ToBackend
    = EnableTwoFactorAuthenticationRequest
    | ConfirmTwoFactorAuthenticationRequest Int


type ToFrontend
    = EnableTwoFactorAuthenticationResponse { qrCodeUrl : String }
    | ConfirmTwoFactorAuthenticationResponse Int Bool


init : Maybe Time.Posix -> Maybe BackendUser -> Model
init twoFactorStatusEnabled maybeUser =
    case maybeUser of
        Just _ ->
            { twoFactorStatus =
                case twoFactorStatusEnabled of
                    Just enabledAt ->
                        TwoFactorAlreadyComplete enabledAt

                    Nothing ->
                        TwoFactorNotStarted
            }
                |> PersonalView

        Nothing ->
            PublicView


update : Msg -> Model -> ( Model, Command FrontendOnly ToBackend Msg )
update msg model =
    case msg of
        SelectedNotificationFrequency emailNotifications ->
            ( model, Command.none )

        PressedStart2FaSetup ->
            updatePersonal
                (\personal ->
                    case personal.twoFactorStatus of
                        TwoFactorNotStarted ->
                            ( { personal | twoFactorStatus = TwoFactorLoading }
                            , Lamdera.sendToBackend EnableTwoFactorAuthenticationRequest
                            )

                        _ ->
                            ( personal, Command.none )
                )
                model

        PressedCopyError text ->
            ( model, Ports.copyToClipboard text )

        TypedTwoFactorCode code ->
            updatePersonal
                (\personal ->
                    case personal.twoFactorStatus of
                        TwoFactorSetup state ->
                            let
                                ( state2, cmd ) =
                                    LoginForm.typedCode
                                        LoginForm.twoFactorCodeLength
                                        (\a -> Lamdera.sendToBackend (ConfirmTwoFactorAuthenticationRequest a))
                                        code
                                        { state | attempts = SeqDict.empty }
                            in
                            ( { personal | twoFactorStatus = TwoFactorSetup state2 }
                            , cmd
                            )

                        _ ->
                            ( personal, Command.none )
                )
                model


updatePersonal :
    (PersonalViewData -> ( PersonalViewData, Command FrontendOnly ToBackend Msg ))
    -> Model
    -> ( Model, Command FrontendOnly ToBackend Msg )
updatePersonal updateFunc model =
    case model of
        PersonalView personal ->
            let
                ( data, cmd ) =
                    updateFunc personal
            in
            ( PersonalView data, cmd )

        PublicView ->
            ( PublicView, Command.none )


updateFromBackend : ToFrontend -> Model -> Model
updateFromBackend toFrontend model =
    case toFrontend of
        EnableTwoFactorAuthenticationResponse { qrCodeUrl } ->
            case model of
                PersonalView personal ->
                    case personal.twoFactorStatus of
                        TwoFactorLoading ->
                            { personal
                                | twoFactorStatus =
                                    TwoFactorSetup
                                        { qrCodeUrl = qrCodeUrl
                                        , code = ""
                                        , attempts = SeqDict.empty
                                        }
                            }
                                |> PersonalView

                        _ ->
                            model

                PublicView ->
                    model

        ConfirmTwoFactorAuthenticationResponse code isSuccessful ->
            case model of
                PersonalView personal ->
                    case personal.twoFactorStatus of
                        TwoFactorSetup data ->
                            (if isSuccessful then
                                { personal | twoFactorStatus = TwoFactorComplete }

                             else
                                { personal
                                    | twoFactorStatus =
                                        TwoFactorSetup
                                            { data
                                                | attempts =
                                                    SeqDict.insert code NotValid data.attempts
                                            }
                                }
                            )
                                |> PersonalView

                        _ ->
                            model

                PublicView ->
                    model


type alias Config a =
    { a | windowSize : Coord CssPixels, time : Time.Posix }


view : Config a -> Id UserId -> LocalState -> Model -> Element Msg
view config userId localState model =
    Ui.column
        MyUi.contentContainerAttributes
        (case LocalState.getUser userId localState of
            Just user ->
                [ Ui.el [ Ui.Font.size 32 ] (Ui.text (PersonName.toString user.name))
                , Ui.column
                    [ Ui.spacing 8 ]
                    [ Ui.row
                        [ Ui.spacing 8 ]
                        [ Ui.el [ Ui.Font.bold, Ui.width Ui.shrink ] (Ui.text "Joined at:")
                        , Ui.text (MyUi.datestamp user.createdAt)
                        ]
                    , case model of
                        PublicView ->
                            Ui.none

                        PersonalView _ ->
                            let
                                emailNotificationLabel : { element : Element msg, id : Ui.Input.Label }
                                emailNotificationLabel =
                                    MyUi.label
                                        (Dom.id "UserOverview_emailNotification")
                                        [ Ui.width Ui.shrink ]
                                        (Ui.text "How often do you want email notifications?")
                            in
                            container
                                "Notifications"
                                [ Ui.column
                                    [ Ui.spacing 4 ]
                                    [ emailNotificationLabel.element
                                    , Ui.Input.chooseOne
                                        Ui.column
                                        [ Ui.spacing 4 ]
                                        { onChange = SelectedNotificationFrequency
                                        , options =
                                            List.map
                                                (\a ->
                                                    (case a of
                                                        CheckEvery5Minutes ->
                                                            "Check every 5 minutes"

                                                        CheckEveryHour ->
                                                            "Check every hour"

                                                        NeverNotifyMe ->
                                                            "Never notify me by email"
                                                    )
                                                        |> Ui.text
                                                        |> Ui.Input.option a
                                                )
                                                User.allEmailNotifications
                                        , selected = localState.localUser.user.emailNotifications |> Just
                                        , label = emailNotificationLabel.id
                                        }
                                    ]
                                ]
                    , case model of
                        PublicView ->
                            Ui.none

                        PersonalView personal ->
                            container
                                "Two-factor authentication"
                                [ case personal.twoFactorStatus of
                                    TwoFactorNotStarted ->
                                        MyUi.primaryButton
                                            (Dom.id "userOverview_start2FaSetup")
                                            PressedStart2FaSetup
                                            "Enable two factor authentication"

                                    TwoFactorLoading ->
                                        MyUi.primaryButton
                                            (Dom.id "userOverview_start2FaSetup")
                                            PressedStart2FaSetup
                                            "Loading..."

                                    TwoFactorSetup data ->
                                        twoFactorSetupView data

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
                                            , MyUi.timeElapsedView config.time enabledAt
                                            , Ui.text "."
                                            ]
                                ]
                    ]
                ]

            Nothing ->
                [ Ui.text "User could not be found" ]
        )


twoFactorSetupView : TwoFactorSetupData -> Element Msg
twoFactorSetupView { qrCodeUrl, code, attempts } =
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
                        [ Ui.spacing 4 ]
                        [ Ui.text "Scan this QR code using the app"
                        , QRCode.toSvgWithoutQuietZone
                            [ MyUi.widthAttr 260, MyUi.heightAttr 260 ]
                            qrCode
                            |> Ui.html
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
                PressedCopyError
                "Something went wrong when setting up two factor authentication"


container : String -> List (Element msg) -> Element msg
container label contents =
    Ui.el
        [ Ui.paddingWith { left = 0, right = 0, top = 10, bottom = 0 }
        , Ui.text label
            |> Ui.el
                [ Ui.Font.bold
                , Ui.Font.size 14
                , Ui.move { x = 12, y = 0, z = 0 }
                , Ui.paddingXY 2 0
                , Ui.width Ui.shrink
                , Ui.background MyUi.white
                ]
            |> Ui.inFront
        ]
        (Ui.column
            [ Ui.border 1
            , Ui.rounded 4
            , Ui.padding 12
            ]
            contents
        )
