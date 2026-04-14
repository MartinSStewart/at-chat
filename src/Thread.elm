module Thread exposing
    ( BackendThread
    , DiscordBackendThread
    , DiscordFrontendThread
    , FrontendGenericThread
    , FrontendThread
    , LastTypedAt
    , backendInit
    , discordBackendInit
    , discordFrontendInit
    , discordToFrontend
    , frontendInit
    , loadMessages
    , toFrontend
    )

import Array exposing (Array)
import ArrayWithOffset exposing (ArrayWithOffset)
import Dict
import Discord
import Effect.Time as Time
import Id exposing (Id, ThreadMessageId, UserId)
import Message exposing (Message, MessageState(..))
import OneToOne exposing (OneToOne)
import SeqDict exposing (SeqDict)
import VisibleMessages exposing (VisibleMessages)


type alias BackendThread =
    { messages : Array (Message ThreadMessageId (Id UserId))
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    }


type alias DiscordBackendThread =
    { messages : Array (Message ThreadMessageId (Discord.Id Discord.UserId))
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ThreadMessageId)
    , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id ThreadMessageId)
    }


type alias FrontendGenericThread userId =
    { messages : ArrayWithOffset ThreadMessageId userId
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId)
    }


type alias FrontendThread =
    { messages : ArrayWithOffset ThreadMessageId (Id UserId)
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ThreadMessageId)
    }


type alias DiscordFrontendThread =
    { messages : ArrayWithOffset ThreadMessageId (Discord.Id Discord.UserId)
    , visibleMessages : VisibleMessages ThreadMessageId
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ThreadMessageId)
    }


type alias LastTypedAt messageId =
    { time : Time.Posix, messageIndex : Maybe (Id messageId) }


backendInit : BackendThread
backendInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    }


frontendInit : FrontendGenericThread userId
frontendInit =
    { messages = ArrayWithOffset.init
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    }


discordBackendInit : DiscordBackendThread
discordBackendInit =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    }


discordFrontendInit : DiscordFrontendThread
discordFrontendInit =
    { messages = ArrayWithOffset.init
    , visibleMessages = VisibleMessages.empty
    , lastTypedAt = SeqDict.empty
    }


toFrontend : Bool -> BackendThread -> FrontendThread
toFrontend preloadMessages thread =
    { messages = loadMessages preloadMessages thread.messages
    , visibleMessages = VisibleMessages.init preloadMessages thread
    , lastTypedAt = thread.lastTypedAt
    }


discordToFrontend : Bool -> DiscordBackendThread -> DiscordFrontendThread
discordToFrontend preloadMessages thread =
    { messages = loadMessages preloadMessages thread.messages
    , visibleMessages = VisibleMessages.init preloadMessages thread
    , lastTypedAt = thread.lastTypedAt
    }


loadMessages : Bool -> Array (Message messageId userId) -> ArrayWithOffset messageId userId
loadMessages preloadMessages messages =
    let
        messageCount : Int
        messageCount =
            Array.length messages
    in
    if preloadMessages then
        ArrayWithOffset.initFromSlice (messageCount - VisibleMessages.pageSize) messageCount messages

    else
        -- Load the latest message for each channel/thread in case it's needed for a preview somewhere
        ArrayWithOffset.initFromSlice (messageCount - 1) messageCount messages
