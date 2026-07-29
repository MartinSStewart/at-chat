module RecoveryLogin exposing
    ( Model
    , Msg(..)
    , incorrectPassword
    , init
    , isPressMsg
    , passwordInputId
    , submitButtonId
    , update
    , view
    )

{-| A way to log in as the admin user when the backend has no Postmark API key and therefore can't
email a login code to anyone. That's the state the backend is in after it has been reset, which is
exactly when someone needs to log in to upload a backup.

This lives on the admin page instead of the normal login page so that it's only reachable by
someone who already knows where to look.

-}

import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import MyUi
import Ui exposing (Element)
import Ui.Events
import Ui.Font
import Ui.Input
import Ui.Prose


{-| OpaqueVariants
-}
type Msg
    = TypedPassword String
    | PressedSubmit


isPressMsg : Msg -> Bool
isPressMsg msg =
    case msg of
        TypedPassword _ ->
            False

        PressedSubmit ->
            True


{-| Opaque
-}
type Model
    = Model { password : String, submitStatus : SubmitStatus }


type SubmitStatus
    = NotSubmitted Bool
    | Submitting
    | IncorrectPassword


init : Model
init =
    Model { password = "", submitStatus = NotSubmitted False }


{-| The backend rejected the password we sent it.
-}
incorrectPassword : Model -> Model
incorrectPassword (Model model) =
    Model { model | submitStatus = IncorrectPassword }


update : (String -> Command FrontendOnly toBackend Msg) -> Msg -> Model -> ( Model, Command FrontendOnly toBackend Msg )
update onSubmitPassword msg (Model model) =
    case msg of
        TypedPassword text ->
            case model.submitStatus of
                Submitting ->
                    ( Model model, Command.none )

                _ ->
                    ( Model { model | password = text }, Command.none )

        PressedSubmit ->
            if String.isEmpty model.password then
                ( Model { model | submitStatus = NotSubmitted True }, Command.none )

            else
                ( Model { model | submitStatus = Submitting }, onSubmitPassword model.password )


passwordInputId : HtmlId
passwordInputId =
    Dom.id "recoveryLogin_passwordInput"


submitButtonId : HtmlId
submitButtonId =
    Dom.id "recoveryLogin_submitButton"


view : Model -> Element Msg
view (Model model) =
    let
        label : { element : Element msg, id : Ui.Input.Label }
        label =
            Ui.Input.label
                (Dom.idToString passwordInputId)
                [ Ui.Font.weight 600 ]
                (Ui.text "Enter the recovery password")
    in
    Ui.column
        [ MyUi.notoSans
        , Ui.padding 16
        , Ui.centerX
        , Ui.centerY
        , Ui.widthMax 520
        , Ui.spacing 16
        , Ui.Font.color MyUi.font1
        ]
        [ Ui.Prose.paragraph
            [ Ui.Font.size 30, Ui.Font.weight 600 ]
            [ Ui.text "Recovery login" ]
        , Ui.Prose.paragraph
            [ Ui.Font.color MyUi.font3, Ui.Font.size 16 ]
            [ Ui.text "This server has no Postmark API key configured, so it can't email login codes to anyone. Enter the recovery password to log in as the admin user." ]
        , MyUi.column
            []
            [ label.element
            , Ui.Input.currentPassword
                [ Ui.Events.onKey Ui.Events.enter PressedSubmit
                , Ui.background MyUi.inputBackground
                , Ui.Font.color MyUi.font1
                , case model.submitStatus of
                    IncorrectPassword ->
                        Ui.borderColor MyUi.errorColor

                    _ ->
                        Ui.borderColor MyUi.inputBorder
                ]
                { onChange = TypedPassword
                , text = model.password
                , placeholder = Nothing
                , label = label.id
                , show = False
                }
            ]
        , Ui.el
            [ Ui.width Ui.shrink ]
            (MyUi.simpleButton submitButtonId PressedSubmit (Ui.text "Login"))
        , case model.submitStatus of
            IncorrectPassword ->
                errorView "Incorrect password"

            NotSubmitted True ->
                errorView "Enter the recovery password first"

            NotSubmitted False ->
                Ui.none

            Submitting ->
                Ui.Prose.paragraph [] [ Ui.text "Submitting..." ]
        ]


errorView : String -> Element msg
errorView errorMessage =
    Ui.el
        [ Ui.width Ui.shrink
        , Ui.Font.color MyUi.errorColor
        , Ui.Font.weight 500
        ]
        (Ui.text errorMessage)
