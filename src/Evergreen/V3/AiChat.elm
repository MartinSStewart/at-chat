module Evergreen.V3.AiChat exposing (..)

import Effect.Http
import Effect.Lamdera
import SeqDict


type ResponseId
    = RespondId Int


type PendingResponse
    = Pending
    | GotResponse String
    | GotError Effect.Http.Error


type AiModel
    = Gemini_2_5_Flash
    | GPT4o
    | Grok3
    | Llama4Maverick
    | L3EuryaleV2_1
    | MidnightRose
    | Unfiltered_X


type SendMessageWith
    = SendWithEnter
    | SendWithShiftEnter


type alias FrontendModel =
    { message : String
    , chatHistory : String
    , pendingResponses : SeqDict.SeqDict ResponseId PendingResponse
    , responseCounter : Int
    , showOptions : Bool
    , selectedModel : AiModel
    , userPrefix : String
    , botPrefix : String
    , debounceCounter : Int
    , sendMessageWith : SendMessageWith
    }


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
    | SelectedAiModel AiModel
    | SelectedSendMessageWith SendMessageWith
    | TypedUserPrefix String
    | TypedBotPrefix String
    | CheckDebounce Int
    | GotLocalStorage String
    | EditedResponse ResponseId String
    | NoOpFrontendMsg


type ToBackend
    = AiMessageRequest AiModel ResponseId String


type BackendMsg
    = GotAiMessage Effect.Lamdera.ClientId ResponseId (Result Effect.Http.Error String)


type ToFrontend
    = AiMessageResponse ResponseId (Result Effect.Http.Error String)
