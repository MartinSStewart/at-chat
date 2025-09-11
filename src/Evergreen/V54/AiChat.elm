module Evergreen.V54.AiChat exposing (..)

import Effect.Http
import Effect.Lamdera
import SeqDict


type ResponseId
    = RespondId Int


type PendingResponse
    = Pending
    | GotResponse String
    | GotError Effect.Http.Error


type SendMessageWith
    = SendWithEnter
    | SendWithShiftEnter


type AiModelsStatus
    = LoadingAiModels
    | LoadedAiModels (List String)
    | LoadingFailed Effect.Http.Error


type alias FrontendModel =
    { message : String
    , chatHistory : String
    , pendingResponses : SeqDict.SeqDict ResponseId PendingResponse
    , responseCounter : Int
    , showOptions : Bool
    , selectedModel : Maybe String
    , userPrefix : String
    , botPrefix : String
    , debounceCounter : Int
    , sendMessageWith : SendMessageWith
    , aiModels : AiModelsStatus
    }


type Msg
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
    | NoOp
    | GotAiModels (Result Effect.Http.Error (List String))


type ToBackend
    = AiMessageRequest String ResponseId String


type BackendMsg
    = GotAiMessage Effect.Lamdera.ClientId ResponseId (Result Effect.Http.Error String)


type ToFrontend
    = AiMessageResponse ResponseId (Result Effect.Http.Error String)
