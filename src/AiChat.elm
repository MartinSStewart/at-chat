port module AiChat exposing (AiModelsStatus(..), BackendMsg(..), FrontendModel, FrontendMsg(..), LocalStorage, PendingResponse(..), ResponseId(..), SendMessageWith(..), ToBackend(..), ToFrontend(..), backendUpdate, init, subscriptions, update, updateFromBackend, updateFromFrontend, view)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (BackendOnly, Command, FrontendOnly)
import Effect.Http as Http exposing (Response(..))
import Effect.Lamdera as Lamdera exposing (ClientId)
import Effect.Process as Process
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task
import Env
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Json.Decode
import Json.Encode
import MyUi
import SeqDict exposing (SeqDict)
import Serialize exposing (Codec)
import Svg
import Svg.Attributes
import Ui exposing (Element)
import Ui.Events
import Ui.Font
import Ui.Gradient
import Ui.Input
import Ui.Shadow


port save_user_settings_to_js : Json.Encode.Value -> Cmd msg


port load_user_settings_to_js : Json.Encode.Value -> Cmd msg


port load_user_settings_from_js : (Json.Encode.Value -> msg) -> Sub msg


saveUserSettingsToJs : String -> Command FrontendOnly toMsg msg
saveUserSettingsToJs text =
    Command.sendToJs "save_user_settings_to_js" save_user_settings_to_js (Json.Encode.string text)


loadUserSettingsToJs : Command FrontendOnly toMsg msg
loadUserSettingsToJs =
    Command.sendToJs "load_user_settings_to_js" load_user_settings_to_js Json.Encode.null


loadUserSettingsFromJs : (String -> b) -> Subscription FrontendOnly b
loadUserSettingsFromJs msg =
    Subscription.fromJs
        "load_user_settings_from_js"
        load_user_settings_from_js
        (\json ->
            Json.Decode.decodeValue Json.Decode.string json
                |> Result.withDefault ""
                |> msg
        )


type alias FrontendModel =
    { message : String
    , chatHistory : String
    , pendingResponses : SeqDict ResponseId PendingResponse
    , responseCounter : Int
    , showOptions : Bool
    , selectedModel : Maybe String
    , userPrefix : String
    , botPrefix : String
    , debounceCounter : Int
    , sendMessageWith : SendMessageWith
    , aiModels : AiModelsStatus
    }


type alias LocalStorage =
    { message : String
    , chatHistory : String
    , pendingResponses : SeqDict ResponseId PendingResponse
    , showOptions : Bool
    , selectedModel : Maybe String
    , userPrefix : String
    , botPrefix : String
    , sendMessageWith : SendMessageWith
    , responseCounter : Int
    }


type ResponseId
    = RespondId Int


type PendingResponse
    = Pending
    | GotResponse String
    | GotError Http.Error


type SendMessageWith
    = SendWithEnter
    | SendWithShiftEnter


type FrontendMsg
    = TypedMessage String
    | PressedSend
    | TypedChatHistory String
    | PressedKeep ResponseId
    | PressedDelete ResponseId
    | PressedRetry ResponseId
    | PressedChatHistoryContainer
    | PressedClearChatHistory
    | PressedOptionsButton
    | SelectedAiModel String
    | SelectedSendMessageWith SendMessageWith
    | TypedUserPrefix String
    | TypedBotPrefix String
    | CheckDebounce Int
    | GotLocalStorage String
    | EditedResponse ResponseId String
    | NoOpFrontendMsg
    | GotAiModels (Result Http.Error (List String))


type ToBackend
    = AiMessageRequest String ResponseId String


type BackendMsg
    = GotAiMessage ClientId ResponseId (Result Http.Error String)


type ToFrontend
    = AiMessageResponse ResponseId (Result Http.Error String)



-- PORTS


init : ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
init =
    ( { message = ""
      , chatHistory = ""
      , pendingResponses = SeqDict.empty
      , responseCounter = 0
      , showOptions = True
      , selectedModel = Nothing
      , userPrefix = "[user]"
      , botPrefix = "[bot]"
      , debounceCounter = 0
      , sendMessageWith = SendWithShiftEnter
      , aiModels = LoadingAiModels
      }
    , Command.batch
        [ loadUserSettingsToJs
        , Http.get
            { url = "https://openrouter.ai/api/v1/models"
            , expect = Http.expectJson GotAiModels decodeModels
            }
        ]
    )


type AiModelsStatus
    = LoadingAiModels
    | LoadedAiModels (List String)
    | LoadingFailed Http.Error


decodeModels : Json.Decode.Decoder (List String)
decodeModels =
    Json.Decode.field
        "data"
        (Json.Decode.list
            (Json.Decode.field "id" Json.Decode.string)
        )


subscriptions : Subscription FrontendOnly FrontendMsg
subscriptions =
    loadUserSettingsFromJs GotLocalStorage


localStorageCodec : Codec e LocalStorage
localStorageCodec =
    Serialize.record LocalStorage
        |> Serialize.field .message Serialize.string
        |> Serialize.field .chatHistory Serialize.string
        |> Serialize.field .pendingResponses (seqDictCodec responseIdCodec pendingResponseCodec)
        |> Serialize.field .showOptions Serialize.bool
        |> Serialize.field .selectedModel (Serialize.maybe Serialize.string)
        |> Serialize.field .userPrefix Serialize.string
        |> Serialize.field .botPrefix Serialize.string
        |> Serialize.field .sendMessageWith sendMessageWithCodec
        |> Serialize.field .responseCounter Serialize.int
        |> Serialize.finishRecord


responseIdCodec : Codec e ResponseId
responseIdCodec =
    Serialize.customType
        (\respondIdEncoder value ->
            case value of
                RespondId arg0 ->
                    respondIdEncoder arg0
        )
        |> Serialize.variant1 RespondId Serialize.int
        |> Serialize.finishCustomType


pendingResponseCodec : Codec e PendingResponse
pendingResponseCodec =
    Serialize.customType
        (\pendingEncoder gotResponseEncoder gotErrorEncoder value ->
            case value of
                Pending ->
                    pendingEncoder

                GotResponse arg0 ->
                    gotResponseEncoder arg0

                GotError arg0 ->
                    gotErrorEncoder arg0
        )
        |> Serialize.variant0 Pending
        |> Serialize.variant1 GotResponse Serialize.string
        |> Serialize.variant1 GotError errorCodec
        |> Serialize.finishCustomType


errorCodec : Codec e Http.Error
errorCodec =
    Serialize.customType
        (\badUrlEncoder timeoutEncoder networkErrorEncoder badStatusEncoder badBodyEncoder value ->
            case value of
                Http.BadUrl arg0 ->
                    badUrlEncoder arg0

                Http.Timeout ->
                    timeoutEncoder

                Http.NetworkError ->
                    networkErrorEncoder

                Http.BadStatus arg0 ->
                    badStatusEncoder arg0

                Http.BadBody arg0 ->
                    badBodyEncoder arg0
        )
        |> Serialize.variant1 Http.BadUrl Serialize.string
        |> Serialize.variant0 Http.Timeout
        |> Serialize.variant0 Http.NetworkError
        |> Serialize.variant1 Http.BadStatus Serialize.int
        |> Serialize.variant1 Http.BadBody Serialize.string
        |> Serialize.finishCustomType


seqDictCodec : Codec e key -> Codec e value -> Codec e (SeqDict key value)
seqDictCodec keyCodec valueCodec =
    Serialize.map
        SeqDict.fromList
        SeqDict.toList
        (Serialize.list (Serialize.tuple keyCodec valueCodec))


sendMessageWithCodec : Codec e SendMessageWith
sendMessageWithCodec =
    Serialize.enum
        SendWithEnter
        [ SendWithShiftEnter ]


startDebounceSave : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
startDebounceSave model =
    ( { model | debounceCounter = model.debounceCounter + 1 }
    , Process.sleep (Duration.seconds 0.5) |> Task.perform (\_ -> CheckDebounce (model.debounceCounter + 1))
    )


saveToLocalStorage : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
saveToLocalStorage model =
    ( model
    , modelToLocalStorage model |> Serialize.encodeToString localStorageCodec |> saveUserSettingsToJs
    )


modelToLocalStorage : FrontendModel -> LocalStorage
modelToLocalStorage model =
    { message = model.message
    , chatHistory = model.chatHistory
    , pendingResponses = model.pendingResponses
    , showOptions = model.showOptions
    , selectedModel = model.selectedModel
    , userPrefix = model.userPrefix
    , botPrefix = model.botPrefix
    , sendMessageWith = model.sendMessageWith
    , responseCounter = model.responseCounter
    }


refreshIcon : Html msg
refreshIcon =
    Svg.svg [ Svg.Attributes.fill "none", Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.strokeWidth "1.5", Svg.Attributes.stroke "currentColor" ] [ Svg.path [ Svg.Attributes.strokeLinecap "round", Svg.Attributes.strokeLinejoin "round", Svg.Attributes.d "M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99" ] [] ]


deleteIcon : Html msg
deleteIcon =
    Svg.svg [ Svg.Attributes.fill "none", Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.strokeWidth "1.5", Svg.Attributes.stroke "currentColor" ] [ Svg.path [ Svg.Attributes.strokeLinecap "round", Svg.Attributes.strokeLinejoin "round", Svg.Attributes.d "m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" ] [] ]


checkIcon : Html msg
checkIcon =
    Svg.svg [ Svg.Attributes.viewBox "0 0 20 20", Svg.Attributes.fill "currentColor" ] [ Svg.path [ Svg.Attributes.fillRule "evenodd", Svg.Attributes.d "M16.704 4.153a.75.75 0 0 1 .143 1.052l-8 10.5a.75.75 0 0 1-1.127.075l-4.5-4.5a.75.75 0 0 1 1.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 0 1 1.05-.143Z", Svg.Attributes.clipRule "evenodd" ] [] ]


closeIcon : Html msg
closeIcon =
    Svg.svg [ Svg.Attributes.fill "none", Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.strokeWidth "1.5", Svg.Attributes.stroke "currentColor" ] [ Svg.path [ Svg.Attributes.strokeLinecap "round", Svg.Attributes.strokeLinejoin "round", Svg.Attributes.d "M6 18 18 6M6 6l12 12" ] [] ]


sendIcon : Html msg
sendIcon =
    Svg.svg [ Svg.Attributes.fill "none", Svg.Attributes.viewBox "0 0 24 24", Svg.Attributes.strokeWidth "1.5", Svg.Attributes.stroke "currentColor" ] [ Svg.path [ Svg.Attributes.strokeLinecap "round", Svg.Attributes.strokeLinejoin "round", Svg.Attributes.d "M6 12 3.269 3.125A59.769 59.769 0 0 1 21.485 12 59.768 59.768 0 0 1 3.27 20.875L5.999 12Zm0 0h7.5" ] [] ]


update : FrontendMsg -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
update msg model =
    case msg of
        TypedMessage message ->
            startDebounceSave { model | message = message }

        PressedSend ->
            if SeqDict.size model.pendingResponses < 3 then
                case model.selectedModel of
                    Just aiModel ->
                        let
                            newChatHistory : String
                            newChatHistory =
                                if String.trim model.message == "" then
                                    model.chatHistory

                                else
                                    String.trimRight model.chatHistory
                                        ++ prefixWrapper model.userPrefix
                                        ++ String.trim model.message
                                        ++ prefixWrapper model.botPrefix
                                        |> String.trimLeft

                            responseId =
                                RespondId model.responseCounter
                        in
                        ( { model
                            | message = ""
                            , chatHistory = newChatHistory
                            , pendingResponses =
                                SeqDict.insert
                                    responseId
                                    Pending
                                    model.pendingResponses
                            , responseCounter = model.responseCounter + 1
                          }
                        , Command.batch
                            [ Lamdera.sendToBackend (AiMessageRequest aiModel responseId newChatHistory)
                            , scrollToBottom
                            ]
                        )

                    Nothing ->
                        ( model, Command.none )

            else
                ( model, Command.none )

        TypedChatHistory text ->
            startDebounceSave { model | chatHistory = text }

        PressedKeep responseId ->
            case SeqDict.get responseId model.pendingResponses of
                Just (GotResponse text) ->
                    saveToLocalStorage
                        { model
                            | pendingResponses = SeqDict.empty
                            , chatHistory = String.trim model.chatHistory ++ "\n" ++ text
                        }
                        |> Tuple.mapSecond (\cmd -> Command.batch [ scrollToBottom, cmd ])

                _ ->
                    ( model, Command.none )

        PressedDelete responseId ->
            saveToLocalStorage { model | pendingResponses = SeqDict.remove responseId model.pendingResponses }

        PressedRetry responseId ->
            case model.selectedModel of
                Just aiModel ->
                    ( { model
                        | pendingResponses = SeqDict.insert responseId Pending model.pendingResponses
                      }
                    , Command.batch
                        [ Lamdera.sendToBackend (AiMessageRequest aiModel responseId model.chatHistory)
                        , scrollToTop (responseContainerId responseId)
                        ]
                    )

                Nothing ->
                    ( model, Command.none )

        PressedChatHistoryContainer ->
            ( model, Dom.focus chatHistoryInputId |> Task.attempt (\_ -> NoOpFrontendMsg) )

        PressedClearChatHistory ->
            saveToLocalStorage { model | chatHistory = "" }

        PressedOptionsButton ->
            saveToLocalStorage { model | showOptions = not model.showOptions }

        SelectedAiModel aiModel ->
            saveToLocalStorage { model | selectedModel = Just aiModel }

        SelectedSendMessageWith sendMessageWith ->
            saveToLocalStorage { model | sendMessageWith = sendMessageWith }

        TypedUserPrefix prefix ->
            startDebounceSave { model | userPrefix = prefix }

        TypedBotPrefix prefix ->
            startDebounceSave { model | botPrefix = prefix }

        CheckDebounce counter ->
            if counter == model.debounceCounter then
                saveToLocalStorage model

            else
                ( model, Command.none )

        GotLocalStorage text ->
            case Serialize.decodeFromString localStorageCodec text of
                Ok ok ->
                    ( { model
                        | message = ok.message
                        , chatHistory = ok.chatHistory
                        , pendingResponses = ok.pendingResponses
                        , showOptions = ok.showOptions
                        , selectedModel = ok.selectedModel
                        , userPrefix = ok.userPrefix
                        , botPrefix = ok.botPrefix
                        , sendMessageWith = ok.sendMessageWith
                        , responseCounter = ok.responseCounter
                      }
                    , Command.none
                    )

                Err _ ->
                    ( model, Command.none )

        EditedResponse responseId text ->
            startDebounceSave
                { model
                    | pendingResponses =
                        SeqDict.updateIfExists responseId
                            (\response ->
                                case response of
                                    GotResponse _ ->
                                        GotResponse text

                                    Pending ->
                                        response

                                    GotError _ ->
                                        response
                            )
                            model.pendingResponses
                }

        NoOpFrontendMsg ->
            ( model, Command.none )

        GotAiModels result ->
            ( case result of
                Ok ok ->
                    { model
                        | aiModels = LoadedAiModels (List.sort ok)
                        , selectedModel =
                            if List.member "anthropic/claude-sonnet-4" ok then
                                Just "anthropic/claude-sonnet-4"

                            else
                                Nothing
                    }

                Err err ->
                    { model
                        | aiModels = LoadingFailed err
                    }
            , Command.none
            )


prefixWrapper : String -> String
prefixWrapper prefix =
    "\n\n" ++ prefix ++ "\n"


scrollToBottom : Command FrontendOnly ToBackend FrontendMsg
scrollToBottom =
    Dom.setViewportOf chatHistoryId 0 999999 |> Task.attempt (\_ -> NoOpFrontendMsg)


scrollToTop : HtmlId -> Command FrontendOnly ToBackend FrontendMsg
scrollToTop id =
    Dom.setViewportOf id 0 0 |> Task.attempt (\_ -> NoOpFrontendMsg)


responseContainerId : ResponseId -> HtmlId
responseContainerId (RespondId responseId) =
    "responseContainer_" ++ String.fromInt responseId |> Dom.id


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
updateFromBackend msg model =
    case msg of
        AiMessageResponse responseId result ->
            case SeqDict.get responseId model.pendingResponses of
                Just Pending ->
                    { model
                        | pendingResponses =
                            SeqDict.insert
                                responseId
                                (case result of
                                    Ok aiMessage ->
                                        let
                                            aiMessage2 =
                                                case String.split (prefixWrapper model.botPrefix) aiMessage of
                                                    aiMessage3 :: _ ->
                                                        case String.split (prefixWrapper model.userPrefix) aiMessage3 of
                                                            aiMessage4 :: _ ->
                                                                aiMessage4

                                                            [] ->
                                                                aiMessage3

                                                    [] ->
                                                        aiMessage
                                        in
                                        String.replace "\\\"" "\"" aiMessage2 |> GotResponse

                                    Err error ->
                                        GotError error
                                )
                                model.pendingResponses
                    }
                        |> saveToLocalStorage

                _ ->
                    ( model, Command.none )


chatHistoryId : HtmlId
chatHistoryId =
    Dom.id "chat-history"


chatHistoryInputId : HtmlId
chatHistoryInputId =
    Dom.id "chat-history-input"


isMobile : Coord CssPixels -> Bool
isMobile windowSize =
    Coord.xRaw windowSize < 800


view : Coord CssPixels -> FrontendModel -> Element FrontendMsg
view windowSize model =
    let
        isMobile2 =
            isMobile windowSize

        responseCount =
            SeqDict.size model.pendingResponses
    in
    Ui.column
        [ if isMobile2 then
            MyUi.htmlStyle "padding-bottom" MyUi.insetBottom

          else
            Ui.paddingXY 16 16
        , if isMobile2 then
            Ui.spacing 8

          else
            Ui.spacing 16
        , Ui.height Ui.fill
        , Ui.htmlAttribute (Html.Attributes.style "min-height" "0")
        , Ui.Font.color MyUi.font1
        , Ui.background MyUi.background1
        , Ui.el
            [ MyUi.htmlStyle "height" MyUi.insetTop
            , Ui.backgroundGradient
                [ Ui.Gradient.linear
                    (Ui.radians 0)
                    [ Ui.Gradient.percent 0 (Ui.rgba 0 0 0 0)
                    , Ui.Gradient.percent 100 MyUi.background1
                    ]
                ]
            ]
            Ui.none
            |> Ui.inFront
        ]
        [ Ui.el
            [ Ui.htmlAttribute (Html.Attributes.style "min-height" "0")
            , Ui.inFront
                (if String.trim model.chatHistory == "" then
                    Ui.none

                 else
                    Ui.row
                        [ Ui.alignRight
                        , Ui.Input.button PressedClearChatHistory
                        , Ui.paddingXY 6 4
                        , Ui.rounded 4
                        , Ui.background MyUi.buttonBackground
                        , Ui.border 1
                        , Ui.borderColor MyUi.border1
                        , MyUi.htmlStyle
                            "transform"
                            ("translateX(-21px) translateY(calc(4px + " ++ MyUi.insetTop ++ "))")
                        , Ui.Font.size 14
                        , Ui.Font.bold
                        , Ui.spacing 4
                        ]
                        [ Ui.el [ Ui.width (Ui.px 16), Ui.centerY ] (Ui.html deleteIcon)
                        , Ui.text "Reset"
                        ]
                )
            , Ui.widthMax 1000
            , Ui.centerX
            , Ui.attrIf (responseCount > 0) (Ui.heightMax (Coord.yRaw windowSize // 2))
            , Ui.height Ui.fill
            ]
            (Ui.column
                [ Ui.htmlAttribute (Html.Attributes.style "min-height" "0")
                , MyUi.htmlStyle "overflow-y" "scroll"
                , Ui.attrIf (not isMobile2) (Ui.rounded 4)
                , Ui.borderColor MyUi.inputBorder
                , if isMobile2 then
                    Ui.borderWith { left = 0, right = 0, top = 0, bottom = 1 }

                  else
                    Ui.border 1
                , MyUi.id chatHistoryId
                , Ui.Events.onClick PressedChatHistoryContainer
                , Ui.attrIf (model.chatHistory == "") (Ui.Font.color MyUi.font3)
                , Ui.attrIf (model.chatHistory == "") Ui.Font.italic
                , containerShadow
                , Ui.height Ui.fill
                , Ui.background MyUi.inputBackground
                , MyUi.htmlStyle "padding-top" MyUi.insetTop
                ]
                [ Ui.Input.multiline
                    [ Ui.border 0
                    , MyUi.id chatHistoryInputId
                    , Ui.paddingXY 12 8
                    , Ui.background MyUi.inputBackground
                    ]
                    { onChange = TypedChatHistory
                    , text = model.chatHistory
                    , placeholder = Just "Nothing in the chat history yet..."
                    , label = Ui.Input.labelHidden "chat-history-label"
                    , spellcheck = True
                    }
                ]
            )
        , if responseCount == 0 then
            Ui.none

          else
            Ui.row
                [ Ui.htmlAttribute (Html.Attributes.style "min-height" "0")
                , if isMobile2 then
                    Ui.paddingXY 0 0

                  else
                    Ui.paddingXY 16 0
                , Ui.centerX
                , Ui.spacing 8
                , Ui.height (Ui.px (Coord.yRaw windowSize // 2))
                ]
                (SeqDict.toList model.pendingResponses
                    |> List.map
                        (\( responseId, response ) ->
                            responseView (Coord.xRaw windowSize) responseCount responseId response
                        )
                )
        , Ui.row
            [ Ui.spacing 8
            , Ui.widthMax 1000
            , Ui.centerX
            , Ui.paddingXY 8 0
            ]
            [ if model.message == "" || not isMobile2 then
                showOptionsButton

              else
                Ui.none
            , userMessageView model
            ]
        , if model.showOptions then
            optionsView model

          else
            Ui.none
        ]


responseView : Int -> Int -> ResponseId -> PendingResponse -> Element FrontendMsg
responseView windowWidth responseCount responseId response =
    Ui.el
        [ min
            1000
            ((windowWidth - 32 - 8) // responseCount)
            |> Ui.px
            |> Ui.width
        , [ case response of
                GotResponse _ ->
                    responseButton
                        (PressedKeep responseId)
                        MyUi.background2
                        checkIcon
                        "Keep"

                Pending ->
                    Ui.none

                GotError _ ->
                    Ui.none
          , responseButton
                (PressedRetry responseId)
                MyUi.background3
                refreshIcon
                "Retry"
          , responseButton
                (PressedDelete responseId)
                MyUi.deleteButtonBackground
                deleteIcon
                "Delete"
          ]
            |> Ui.row
                [ Ui.alignRight
                , Ui.width Ui.shrink
                , Ui.borderWith { left = 1, right = 1, top = 1, bottom = 0 }
                , Ui.roundedWith { topLeft = 4, topRight = 4, bottomRight = 0, bottomLeft = 0 }
                , Ui.move { x = -32, y = 0, z = 0 }
                , Ui.clip
                , Ui.borderColor MyUi.inputBorder
                ]
            |> Ui.above
        , Ui.height Ui.fill
        , containerShadow
        , Ui.htmlAttribute (Html.Attributes.style "min-height" "0")
        ]
        (case response of
            Pending ->
                Ui.el
                    [ Ui.border 1
                    , Ui.paddingXY 8 8
                    , Ui.height Ui.fill
                    , Ui.scrollable
                    , responseContainerId responseId |> MyUi.id
                    , Ui.rounded 4
                    , Ui.borderColor MyUi.inputBorder
                    ]
                    (Ui.text "Loading...")

            GotResponse response2 ->
                Ui.el
                    [ Ui.scrollable
                    , Ui.rounded 4
                    , Ui.border 1
                    , Ui.borderColor MyUi.inputBorder
                    , responseContainerId responseId |> MyUi.id
                    , Ui.htmlAttribute (Html.Attributes.style "min-height" "0")
                    ]
                    (Ui.Input.multiline
                        [ Ui.paddingXY 8 8
                        , MyUi.htmlStyle "white-space" "pre-wrap"
                        , Ui.border 0
                        , Ui.background MyUi.inputBackground
                        ]
                        { text = response2
                        , onChange = EditedResponse responseId
                        , placeholder = Just "No response"
                        , spellcheck = True
                        , label = Ui.Input.labelHidden "AI response"
                        }
                    )

            GotError error ->
                Ui.el
                    [ Ui.border 1
                    , Ui.paddingXY 8 8
                    , Ui.height Ui.fill
                    , Ui.rounded 4
                    , Ui.borderColor MyUi.inputBorder
                    , Ui.Font.italic
                    , Ui.Font.color MyUi.errorColor
                    ]
                    (case error of
                        Http.NetworkError ->
                            Ui.text "Network error"

                        Http.BadUrl url ->
                            Ui.text ("Bad url: " ++ url)

                        Http.Timeout ->
                            Ui.text "Request timed out"

                        Http.BadStatus int ->
                            Ui.text ("Bad status code: " ++ String.fromInt int)

                        Http.BadBody string ->
                            Ui.text ("Error in response body: " ++ string)
                    )
        )


responseButton : msg -> Ui.Color -> Html msg -> String -> Element msg
responseButton msg color icon text =
    Ui.row
        [ Ui.background color
        , Ui.paddingXY 16 4
        , Ui.Font.bold
        , Ui.Input.button msg
        , Ui.width Ui.shrink
        , Ui.spacing 4
        ]
        [ Ui.el [ Ui.width (Ui.px 20), Ui.centerY ] (Ui.html icon), Ui.text text ]


showOptionsButton : Element FrontendMsg
showOptionsButton =
    Ui.el
        [ Ui.Input.button PressedOptionsButton
        , Ui.paddingXY 4 4
        , Ui.background MyUi.buttonBackground
        , Ui.border 1
        , Ui.borderColor MyUi.border1
        , Ui.rounded 4
        , Ui.width (Ui.px 36)
        , Ui.height (Ui.px 36)
        ]
        (Ui.html Icons.gearIcon)


optionsView : FrontendModel -> Element FrontendMsg
optionsView model =
    let
        userPrefixLabel : { element : Element FrontendMsg, id : Ui.Input.Label }
        userPrefixLabel =
            Ui.Input.label
                "user-label"
                [ Ui.Font.weight 500
                , Ui.Font.size 14
                , Ui.paddingXY 4 4
                ]
                (Ui.text "User's name")

        botPrefixLabel : { element : Element FrontendMsg, id : Ui.Input.Label }
        botPrefixLabel =
            Ui.Input.label
                "bot-label"
                [ Ui.Font.weight 500
                , Ui.Font.size 14
                , Ui.paddingXY 4 4
                ]
                (Ui.text "Bot's name")
    in
    Ui.column
        [ Ui.widthMax 1000
        , Ui.centerX
        , Ui.background MyUi.background2
        , Ui.border 1
        , Ui.borderColor MyUi.border1
        , Ui.rounded 4
        , Ui.spacing 12
        , containerShadow
        , Ui.paddingWith { left = 0, right = 0, top = 0, bottom = 16 }
        ]
        [ Ui.row
            [ Ui.width Ui.fill
            , Ui.contentCenterY
            ]
            [ Ui.el
                [ Ui.Font.bold
                , Ui.Font.size 16
                , Ui.paddingXY 16 0
                ]
                (Ui.text "Options")
            , Ui.el
                [ Ui.alignRight
                , Ui.Input.button PressedOptionsButton
                , Ui.paddingXY 8 8
                , Ui.rounded 4
                , Ui.width (Ui.px 42)
                , Ui.height (Ui.px 42)
                ]
                (Ui.html closeIcon)
            ]
        , Ui.column
            [ Ui.spacing 8
            , Ui.width Ui.fill
            , Ui.paddingXY 16 0
            ]
            [ Ui.column
                []
                [ Ui.el
                    [ Ui.Font.size 14
                    , Ui.paddingXY 4 4
                    ]
                    (Ui.text "AI Model")
                , Ui.html (aiModelDropdown model.aiModels model.selectedModel)
                ]
            , Ui.column
                []
                [ Ui.el
                    [ Ui.Font.size 14
                    , Ui.paddingXY 4 4
                    ]
                    (Ui.text "Send Message With")
                , Ui.column
                    [ Ui.spacing 4
                    , Ui.paddingXY 4 0
                    ]
                    [ Ui.Input.chooseOne Ui.column
                        [ Ui.spacing 8 ]
                        { onChange = SelectedSendMessageWith
                        , selected = Just model.sendMessageWith
                        , label = Ui.Input.labelHidden "send-message-with"
                        , options =
                            [ Ui.Input.option SendWithEnter (Ui.text "Enter")
                            , Ui.Input.option SendWithShiftEnter (Ui.text "Shift + Enter")
                            ]
                        }
                    ]
                ]
            , Ui.column
                []
                [ userPrefixLabel.element
                , Ui.Input.text
                    [ Ui.paddingXY 8 6
                    , Ui.border 1
                    , Ui.borderColor MyUi.inputBorder
                    , Ui.rounded 4
                    , Ui.background MyUi.inputBackground
                    ]
                    { onChange = TypedUserPrefix
                    , text = model.userPrefix
                    , placeholder = Nothing
                    , label = userPrefixLabel.id
                    }
                ]
            , Ui.column
                []
                [ botPrefixLabel.element
                , Ui.Input.text
                    [ Ui.paddingXY 8 6
                    , Ui.border 1
                    , Ui.borderColor MyUi.inputBorder
                    , Ui.rounded 4
                    , Ui.background MyUi.inputBackground
                    ]
                    { onChange = TypedBotPrefix
                    , text = model.botPrefix
                    , placeholder = Nothing
                    , label = Ui.Input.labelHidden "bot-prefix"
                    }
                ]
            ]
        ]


containerShadow : Ui.Attribute msg
containerShadow =
    Ui.Shadow.shadows [ { x = 0, y = 2, blur = 8, size = 0, color = Ui.rgba 0 0 0 0.1 } ]


userMessageView : FrontendModel -> Element FrontendMsg
userMessageView model =
    let
        message =
            model.message
    in
    Ui.row
        [ containerShadow
        , Ui.rounded 4
        ]
        [ Ui.Input.multiline
            [ Ui.Events.preventDefaultOn
                "keydown"
                (Json.Decode.map2
                    Tuple.pair
                    (Json.Decode.field "key" Json.Decode.string)
                    (Json.Decode.field "shiftKey" Json.Decode.bool)
                    |> Json.Decode.andThen
                        (\( key, shiftHeld ) ->
                            case model.sendMessageWith of
                                SendWithEnter ->
                                    if key == "Enter" && not shiftHeld then
                                        Json.Decode.succeed ( PressedSend, True )

                                    else
                                        Json.Decode.fail ""

                                SendWithShiftEnter ->
                                    if key == "Enter" && shiftHeld then
                                        Json.Decode.succeed ( PressedSend, True )

                                    else
                                        Json.Decode.fail ""
                        )
                )
            , Ui.paddingXY 8 6
            , Ui.borderColor MyUi.inputBorder
            , Ui.roundedWith { topLeft = 4, topRight = 0, bottomRight = 0, bottomLeft = 4 }
            , Ui.attrIf (message == "") Ui.Font.italic
            , Ui.attrIf (message == "") (Ui.Font.color MyUi.font3)
            , Ui.background MyUi.inputBackground
            ]
            { onChange = TypedMessage
            , text = message
            , placeholder = Just "Type a message"
            , label = Ui.Input.labelHidden "message"
            , spellcheck = True
            }
        , Ui.el
            [ Ui.Input.button PressedSend
            , Ui.width (Ui.px 40)
            , Ui.paddingXY 8 0
            , Ui.background MyUi.buttonBackground
            , Ui.height Ui.fill
            , Ui.contentCenterY
            , Ui.borderColor MyUi.inputBorder
            , Ui.borderWith { left = 0, right = 1, top = 1, bottom = 1 }
            , Ui.roundedWith { topLeft = 0, topRight = 4, bottomRight = 4, bottomLeft = 0 }
            , MyUi.noShrinking
            ]
            (Ui.html sendIcon)
        ]


aiModelDropdown : AiModelsStatus -> Maybe String -> Html FrontendMsg
aiModelDropdown status selected =
    case status of
        LoadedAiModels aiModels ->
            Html.select
                [ Html.Attributes.value (Maybe.withDefault "" selected)
                , Html.Events.onInput SelectedAiModel
                , Html.Attributes.style "width" "100%"
                , Html.Attributes.style "padding" "7px 8px"
                , Html.Attributes.style "border" "1px solid rgb(97,104,124)"
                , Html.Attributes.style "border-radius" "4px"
                , Html.Attributes.style "font-size" "16px"
                , Html.Attributes.style "background-color" "rgb(32,40,70)"
                , Html.Attributes.style "color" "rgb(255,255,255)"
                , Html.Attributes.style "cursor" "pointer"
                ]
                (List.map
                    (\aiModel ->
                        Html.option
                            [ Html.Attributes.value aiModel
                            , Html.Attributes.selected (Just aiModel == selected)
                            ]
                            [ Html.text aiModel ]
                    )
                    aiModels
                )

        LoadingAiModels ->
            Html.text "Loading..."

        LoadingFailed error ->
            (case error of
                Http.BadUrl url ->
                    "Bad url: "
                        ++ url

                Http.Timeout ->
                    "Request timed out"

                Http.NetworkError ->
                    "Network error"

                Http.BadStatus int ->
                    "Bad status code " ++ String.fromInt int

                Http.BadBody string ->
                    "Bad body: " ++ string
            )
                |> Html.text



--- Backend


backendUpdate : BackendMsg -> Command BackendOnly ToFrontend BackendMsg
backendUpdate msg =
    case msg of
        GotAiMessage clientId responseId result ->
            Lamdera.sendToFrontend clientId (AiMessageResponse responseId result)


updateFromFrontend : ClientId -> ToBackend -> Command BackendOnly ToFrontend BackendMsg
updateFromFrontend clientId msg =
    case msg of
        AiMessageRequest aiModel responseId text ->
            Http.task
                { method = "POST"
                , headers = [ Http.header "Authorization" ("Bearer " ++ Env.openRouterKey) ]
                , url = "https://openrouter.ai/api/v1/chat/completions"
                , body =
                    Json.Encode.object
                        [ ( "model", Json.Encode.string aiModel )
                        , ( "messages"
                          , Json.Encode.list
                                identity
                                [ Json.Encode.object
                                    [ ( "role", Json.Encode.string "user" )
                                    , ( "content", Json.Encode.string text )
                                    ]
                                ]
                          )
                        ]
                        |> Http.jsonBody
                , resolver =
                    Http.stringResolver
                        (\result ->
                            case result of
                                BadUrl_ url ->
                                    Err (Http.BadUrl url)

                                Timeout_ ->
                                    Err Http.Timeout

                                NetworkError_ ->
                                    Err Http.NetworkError

                                BadStatus_ _ body ->
                                    Http.BadBody body |> Err

                                GoodStatus_ _ body ->
                                    case
                                        Json.Decode.decodeString
                                            (Json.Decode.field
                                                "choices"
                                                (Json.Decode.index
                                                    0
                                                    (Json.Decode.at [ "message", "content" ] Json.Decode.string)
                                                )
                                            )
                                            body
                                    of
                                        Ok ok ->
                                            Ok ok

                                        Err error ->
                                            Json.Decode.errorToString error |> Http.BadBody |> Err
                        )
                , timeout = Nothing
                }
                |> Task.attempt (GotAiMessage clientId responseId)
