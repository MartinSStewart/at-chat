module LoginForm exposing
    ( CodeStatus(..)
    , EnterEmail2
    , EnterLoginCode2
    , EnterTwoFactorCode2
    , EnterUserData2
    , LoginForm(..)
    , Msg(..)
    , SubmitStatus
    , emailInputId
    , errorView
    , init
    , invalidCode
    , loginCodeInput
    , loginCodeInputId
    , loginCodeLength
    , maxLoginAttempts
    , needsTwoFactor
    , needsUserData
    , rateLimited
    , submitEmailButtonId
    , twoFactorCodeLength
    , typedCode
    , update
    , validateCode
    , view
    )

import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import EmailAddress exposing (EmailAddress)
import Html.Attributes
import MyUi
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import Ui exposing (Element)
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Prose
import Ui.Shadow


{-| OpaqueVariants
-}
type Msg
    = PressedSubmitEmail
    | PressedCancelLogin
    | TypedLoginFormEmail String
    | TypedLoginCode String
    | TypedTwoFactorCode String
    | TypedName String
    | PressedSubmitUserData


{-| Opaque
-}
type LoginForm
    = EnterEmail EnterEmail2
    | EnterLoginCode EnterLoginCode2
    | EnterTwoFactorCode EnterTwoFactorCode2
    | EnterUserData EnterUserData2


{-| Opaque
-}
type alias EnterEmail2 =
    { email : String
    , pressedSubmitEmail : Bool
    , rateLimited : Bool
    }


{-| Opaque
-}
type alias EnterLoginCode2 =
    { sentTo : EmailAddress, code : String, attempts : SeqDict Int CodeStatus }


type alias EnterTwoFactorCode2 =
    { code : String, attempts : SeqDict Int CodeStatus, attemptCount : Int }


type alias EnterUserData2 =
    { name : String, pressedSubmit : SubmitStatus }


type SubmitStatus
    = NotSubmitted Bool
    | Submitting


type CodeStatus
    = Checking
    | NotValid


{-| Returns `Nothing` when the users presses the "Cancel" button.
-}
update :
    (EmailAddress -> Command FrontendOnly toBackend Msg)
    -> (Int -> Command FrontendOnly toBackend Msg)
    -> (Int -> Command FrontendOnly toBackend Msg)
    -> (PersonName -> Command FrontendOnly toBackend Msg)
    -> Msg
    -> LoginForm
    -> Maybe ( LoginForm, Command FrontendOnly toBackend Msg )
update onSubmitEmail onSubmitLoginCode onSubmitTwoFactorCode onSubmitUserData msg model =
    case msg of
        PressedSubmitEmail ->
            (case model of
                EnterEmail loginForm ->
                    case EmailAddress.fromString loginForm.email of
                        Just email ->
                            ( EnterLoginCode { sentTo = email, code = "", attempts = SeqDict.empty }
                            , onSubmitEmail email
                            )

                        Nothing ->
                            ( EnterEmail { loginForm | pressedSubmitEmail = True }, Command.none )

                _ ->
                    ( model, Command.none )
            )
                |> Just

        TypedLoginFormEmail text ->
            (case model of
                EnterEmail loginForm ->
                    ( EnterEmail { loginForm | email = text }, Command.none )

                _ ->
                    ( model, Command.none )
            )
                |> Just

        PressedCancelLogin ->
            Nothing

        TypedLoginCode loginCodeText ->
            (case model of
                EnterLoginCode enterLoginCode ->
                    typedCode loginCodeLength onSubmitLoginCode loginCodeText enterLoginCode
                        |> Tuple.mapFirst EnterLoginCode

                _ ->
                    ( model, Command.none )
            )
                |> Just

        TypedTwoFactorCode twoFactorCodeText ->
            (case model of
                EnterTwoFactorCode twoFactorCode ->
                    typedCode
                        twoFactorCodeLength
                        onSubmitTwoFactorCode
                        twoFactorCodeText
                        { twoFactorCode
                            | attempts =
                                -- The correct answer changes every 30 seconds so we don't hang onto the attempts
                                SeqDict.empty
                        }
                        |> Tuple.mapFirst EnterTwoFactorCode

                _ ->
                    ( model, Command.none )
            )
                |> Just

        TypedName text ->
            ( case model of
                EnterUserData enterUserData ->
                    case enterUserData.pressedSubmit of
                        NotSubmitted _ ->
                            EnterUserData { enterUserData | name = text }

                        Submitting ->
                            model

                _ ->
                    model
            , Command.none
            )
                |> Just

        PressedSubmitUserData ->
            case model of
                EnterUserData enterUserData ->
                    case PersonName.fromString enterUserData.name of
                        Ok name ->
                            Just
                                ( EnterUserData { enterUserData | pressedSubmit = Submitting }
                                , onSubmitUserData name
                                )

                        Err _ ->
                            ( EnterUserData { enterUserData | pressedSubmit = NotSubmitted True }
                            , Command.none
                            )
                                |> Just

                _ ->
                    Just ( model, Command.none )


typedCode :
    Int
    -> (Int -> Command FrontendOnly toMsg msg)
    -> String
    -> { a | attempts : SeqDict Int CodeStatus, code : String }
    -> ( { a | attempts : SeqDict Int CodeStatus, code : String }, Command FrontendOnly toMsg msg )
typedCode digitCount onSubmitLoginCode text model =
    case validateCode digitCount text of
        Ok loginCode ->
            if SeqDict.member loginCode model.attempts then
                ( { model | code = String.left digitCount text }
                , Command.none
                )

            else
                ( { model
                    | code = String.left digitCount text
                    , attempts = SeqDict.insert loginCode Checking model.attempts
                  }
                , onSubmitLoginCode loginCode
                )

        Err _ ->
            ( { model | code = String.left digitCount text }
            , Command.none
            )


validateCode : Int -> String -> Result String Int
validateCode digitCount text =
    if String.any (\char -> Char.isDigit char |> not) text then
        Err "Must only contain digits 0-9"

    else if String.length text == digitCount then
        case String.toInt text of
            Just int ->
                Ok int

            Nothing ->
                Err "Invalid code"

    else
        Err ""


loginCodeLength : number
loginCodeLength =
    8


emailInput : msg -> (String -> msg) -> String -> String -> Maybe String -> Element msg
emailInput onSubmit onChange text labelText maybeError =
    let
        label : { element : Element msg, id : Ui.Input.Label }
        label =
            Ui.Input.label
                (Dom.idToString emailInputId)
                [ Ui.Font.weight 600 ]
                (Ui.text labelText)
    in
    Ui.column
        [ Ui.spacing 4 ]
        [ MyUi.column
            []
            [ label.element
            , Ui.Input.email
                [ Ui.Events.onKey Ui.Events.enter onSubmit
                , case maybeError of
                    Just _ ->
                        Ui.borderColor MyUi.errorColor

                    Nothing ->
                        Ui.noAttr
                ]
                { text = text
                , onChange = onChange
                , placeholder = Nothing
                , label = label.id
                }
            ]
        , Maybe.map errorView maybeError |> Maybe.withDefault Ui.none
        ]


errorView : String -> Element msg
errorView errorMessage =
    Ui.el
        [ Ui.width Ui.shrink
        , Ui.Font.color MyUi.errorColor
        , Ui.Font.weight 500
        ]
        (Ui.text errorMessage)


view : LoginForm -> Element Msg
view loginForm =
    Ui.column
        [ MyUi.montserrat, Ui.padding 16, Ui.centerX, Ui.centerY, Ui.widthMax 520, Ui.spacing 24 ]
        [ case loginForm of
            EnterEmail enterEmail2 ->
                enterEmailView enterEmail2

            EnterLoginCode enterLoginCode ->
                enterLoginCodeView enterLoginCode

            EnterTwoFactorCode enterTwoFactorCode ->
                enterTwoFactorCodeView enterTwoFactorCode

            EnterUserData data ->
                let
                    label =
                        Ui.Input.label
                            "loginForm_name"
                            []
                            (Ui.text "Pick a username (you can change it later)")
                in
                Ui.column
                    [ Ui.spacing 16 ]
                    [ Ui.el [ Ui.Font.size 20 ] (Ui.text "Just one thing before you get started!")
                    , Ui.column
                        []
                        [ label.element
                        , Ui.Input.text
                            []
                            { onChange = TypedName
                            , text = data.name
                            , label = label.id
                            , placeholder = Nothing
                            }
                        , case ( data.pressedSubmit, PersonName.fromString data.name ) of
                            ( NotSubmitted True, Err error ) ->
                                errorView error

                            _ ->
                                Ui.none
                        ]
                    , Ui.el
                        [ Ui.Input.button PressedSubmitUserData
                        , Ui.paddingXY 16 8
                        , Ui.background (Ui.rgb 240 240 240)
                        , Ui.width Ui.shrink
                        , Ui.border 1
                        , Ui.borderColor (Ui.rgb 220 220 220)
                        , Ui.rounded 4
                        ]
                        (Ui.text "Submit")
                    ]
        ]


{-| You can't change this value. Google Authenticator will ignore this setting and always use 6. If you change this, it will make it impossible for anyone setting up 2FA to use Google Authenticator.
-}
twoFactorCodeLength : number
twoFactorCodeLength =
    6


loginCodeInput : Int -> (String -> msg) -> String -> { element : Element msg, id : Ui.Input.Label } -> Element msg
loginCodeInput codeLength onInput loginCode label =
    Ui.el
        [ Ui.Font.size 36
        , Ui.Prose.paragraph
            [ Ui.Font.letterSpacing 26
            , Ui.paddingXY 0 6
            , inputFont
            , MyUi.noPointerEvents
            ]
            (List.range 0 (codeLength - 1)
                |> List.map
                    (\index ->
                        Ui.el
                            [ Ui.paddingXY -1 -1
                            , Ui.behindContent
                                (Ui.el
                                    [ Ui.height (Ui.px 54)
                                    , Ui.paddingXY 0 24
                                    , Ui.width (Ui.px 32)
                                    , Ui.Font.color (Ui.rgba 0 0 0 1)
                                    , if index == (codeLength - 1) // 2 then
                                        Ui.onRight
                                            (Ui.el
                                                [ Ui.borderWith
                                                    { left = 0
                                                    , right = 0
                                                    , top = 1
                                                    , bottom = 1
                                                    }
                                                , Ui.move (Ui.right 3)
                                                , Ui.centerY
                                                , Ui.width (Ui.px 9)
                                                ]
                                                Ui.none
                                            )

                                      else
                                        Ui.noAttr
                                    , Ui.border 1
                                    , Ui.rounded 8
                                    , Ui.borderColor MyUi.gray
                                    , Ui.Shadow.shadows [ { x = 0, y = 1, blur = 2, size = 0, color = Ui.rgba 0 0 0 0.2 } ]
                                    , MyUi.noPointerEvents
                                    ]
                                    Ui.none
                                )
                            , Ui.Font.color (Ui.rgba 0 0 0 0)
                            , MyUi.noPointerEvents
                            ]
                            (Ui.text "_")
                    )
            )
            |> Ui.behindContent
        , Ui.width (Ui.px (50 * codeLength))
        ]
        (Ui.Input.text
            [ Ui.Font.letterSpacing 26
            , Ui.paddingWith { left = 6, right = 0, top = 0, bottom = 8 }
            , inputFont
            , Html.Attributes.attribute "inputmode" "numeric" |> Ui.htmlAttribute
            , Ui.border 0
            , Ui.background (Ui.rgba 0 0 0 0)
            ]
            { onChange = onInput
            , text = loginCode
            , placeholder = Nothing
            , label = label.id
            }
        )


inputFont : Ui.Attribute msg
inputFont =
    Ui.Font.family [ Ui.Font.typeface "Consolas", Ui.Font.monospace ]


enterLoginCodeView : EnterLoginCode2 -> Element Msg
enterLoginCodeView model =
    let
        label : { element : Element msg, id : Ui.Input.Label }
        label =
            Ui.Input.label
                (Dom.idToString loginCodeInputId)
                []
                (MyUi.column
                    [ Ui.Font.center, Ui.spacing 16 ]
                    [ Ui.Prose.paragraph
                        [ Ui.Font.size 30, Ui.Font.weight 600 ]
                        [ Ui.text "Check your email for a code" ]
                    , Ui.Prose.paragraph
                        [ Ui.width Ui.shrink ]
                        [ Ui.text "An email has been sent to "
                        , Ui.el
                            [ Ui.Font.weight 600 ]
                            (Ui.text (EmailAddress.toString model.sentTo))
                        , Ui.text
                            (" containing an "
                                ++ String.fromInt loginCodeLength
                                ++ " digit code. Please enter that code here."
                            )
                        ]
                    ]
                )
    in
    Ui.column
        [ Ui.spacing 24 ]
        [ label.element
        , Ui.column
            [ Ui.spacing 8, Ui.centerX, Ui.width Ui.shrink, Ui.move (Ui.right 18) ]
            [ Ui.el [ Ui.centerX ] (loginCodeInput loginCodeLength TypedLoginCode model.code label)
            , if SeqDict.size model.attempts < maxLoginAttempts then
                case validateCode loginCodeLength model.code of
                    Ok loginCode ->
                        case SeqDict.get loginCode model.attempts of
                            Just NotValid ->
                                errorView "Incorrect code"

                            _ ->
                                Ui.Prose.paragraph
                                    []
                                    [ Ui.text "Submitting..." ]

                    Err error ->
                        errorView error

              else
                errorView "Too many incorrect attempts. Please refresh the page and try again."
            ]
        ]


enterTwoFactorCodeView : EnterTwoFactorCode2 -> Element Msg
enterTwoFactorCodeView model =
    let
        label : { element : Element msg, id : Ui.Input.Label }
        label =
            Ui.Input.label
                "loginForm_twoFactorCodeInput"
                []
                (MyUi.column
                    [ Ui.Font.center, Ui.spacing 16 ]
                    [ Ui.Prose.paragraph
                        [ Ui.Font.size 30, Ui.Font.weight 600 ]
                        [ Ui.text "Two Factor Authentication" ]
                    , Ui.text
                        ("Open your authenticator app and copy the "
                            ++ String.fromInt twoFactorCodeLength
                            ++ " digit code here"
                        )
                    ]
                )
    in
    Ui.column
        [ Ui.spacing 24 ]
        [ label.element
        , Ui.column
            [ Ui.spacing 8, Ui.centerX, Ui.width Ui.shrink, Ui.move (Ui.right 18) ]
            [ Ui.el [ Ui.centerX ] (loginCodeInput twoFactorCodeLength TypedTwoFactorCode model.code label)
            , if model.attemptCount < maxLoginAttempts then
                case validateCode twoFactorCodeLength model.code of
                    Ok loginCode ->
                        case SeqDict.get loginCode model.attempts of
                            Just NotValid ->
                                errorView "Incorrect code"

                            _ ->
                                Ui.Prose.paragraph
                                    []
                                    [ Ui.text "Submitting..." ]

                    Err error ->
                        errorView error

              else
                errorView "Too many incorrect attempts. Please refresh the page and try again."
            ]
        ]


emailInputId : HtmlId
emailInputId =
    Dom.id "loginForm_emailInput"


submitEmailButtonId : HtmlId
submitEmailButtonId =
    Dom.id "loginForm_loginButton"


cancelButtonId : HtmlId
cancelButtonId =
    Dom.id "loginForm_cancelButton"


loginCodeInputId : HtmlId
loginCodeInputId =
    Dom.id "loginForm_loginCodeInput"


maxLoginAttempts : number
maxLoginAttempts =
    10


rateLimited : LoginForm -> LoginForm
rateLimited loginForm =
    case loginForm of
        EnterEmail enterEmail ->
            EnterEmail { enterEmail | rateLimited = True }

        EnterLoginCode enterLoginCode ->
            EnterEmail
                { email = EmailAddress.toString enterLoginCode.sentTo
                , pressedSubmitEmail = False
                , rateLimited = True
                }

        EnterTwoFactorCode _ ->
            EnterEmail
                { email = "", pressedSubmitEmail = False, rateLimited = True }

        EnterUserData _ ->
            loginForm


invalidCode : Int -> LoginForm -> LoginForm
invalidCode loginCode loginForm =
    case loginForm of
        EnterEmail _ ->
            loginForm

        EnterLoginCode enterLoginCode ->
            { enterLoginCode | attempts = SeqDict.insert loginCode NotValid enterLoginCode.attempts }
                |> EnterLoginCode

        EnterTwoFactorCode enterTwoFactorCode ->
            { enterTwoFactorCode
                | attempts = SeqDict.insert loginCode NotValid enterTwoFactorCode.attempts
                , attemptCount = enterTwoFactorCode.attemptCount + 1
            }
                |> EnterTwoFactorCode

        EnterUserData _ ->
            loginForm


needsTwoFactor : LoginForm -> LoginForm
needsTwoFactor loginForm =
    case loginForm of
        EnterLoginCode _ ->
            EnterTwoFactorCode { code = "", attempts = SeqDict.empty, attemptCount = 0 }

        _ ->
            loginForm


needsUserData : LoginForm
needsUserData =
    EnterUserData { name = "", pressedSubmit = NotSubmitted False }


enterEmailView : EnterEmail2 -> Element Msg
enterEmailView model =
    Ui.column
        [ Ui.spacing 16 ]
        [ emailInput
            PressedSubmitEmail
            TypedLoginFormEmail
            model.email
            "Enter your email address"
            (case ( model.pressedSubmitEmail, validateEmail model.email ) of
                ( True, Err error ) ->
                    Just error

                _ ->
                    Nothing
            )
        , Ui.row
            [ Ui.spacing 16 ]
            [ MyUi.secondaryButton cancelButtonId [] PressedCancelLogin "Cancel"
            , MyUi.primaryButton submitEmailButtonId PressedSubmitEmail "Login"
            ]
        , if model.rateLimited then
            errorView "Too many login attempts have been made. Please try again later."

          else
            Ui.none
        ]


validateEmail : String -> Result String EmailAddress
validateEmail text =
    EmailAddress.fromString text
        |> Result.fromMaybe
            (if String.isEmpty text then
                "Enter your email first"

             else
                "Invalid email address"
            )


init : LoginForm
init =
    EnterEmail
        { email = ""
        , pressedSubmitEmail = False
        , rateLimited = False
        }
