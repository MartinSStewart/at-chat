module Evergreen.V213.AiChat exposing (..)

import Effect.Http
import Effect.Lamdera
import SeqDict


type ResponseId
    = RespondId Int


type AiModelName
    = AiModelName String


type PendingResponse
    = Pending AiModelName
    | GotResponse AiModelName String
    | GotError AiModelName Effect.Http.Error


type SendMessageWith
    = SendWithEnter
    | SendWithShiftEnter


type alias AiModel =
    { id : AiModelName
    , inputs : List String
    }


type AiModelsStatus
    = LoadingAiModels
    | LoadedAiModels (List AiModel)
    | LoadingFailed Effect.Http.Error


type alias FrontendModel =
    { message : String
    , chatHistory : String
    , pendingResponses : SeqDict.SeqDict ResponseId PendingResponse
    , responseCounter : Int
    , showOptions : Bool
    , selectedModel : Maybe AiModelName
    , userPrefix : String
    , botPrefix : String
    , debounceCounter : Int
    , sendMessageWith : SendMessageWith
    , aiModels : AiModelsStatus
    }


type alias AiResponse =
    { images : List String
    , content : String
    }


type ToFrontend
    = AiMessageResponse ResponseId (Result Effect.Http.Error AiResponse)


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
    | SelectedAiModel AiModelName
    | SelectedSendMessageWith SendMessageWith
    | TypedUserPrefix String
    | TypedBotPrefix String
    | CheckDebounce Int
    | GotLocalStorage String
    | EditedResponse ResponseId String
    | NoOp
    | GotAiModels (Result Effect.Http.Error (List AiModel))


type Message
    = TextMessage String
    | ImageUrlMessage String


type ToBackend
    = AiMessageRequest AiModelName ResponseId (List Message)
    | AiMessageRequestSimple AiModelName ResponseId String


type BackendMsg
    = GotAiMessage Effect.Lamdera.ClientId ResponseId (Result Effect.Http.Error AiResponse)
