module UserSession exposing
    ( ChannelHeaderTab(..)
    , DiscordFrontendUser
    , FrontendUserSession
    , NotificationMode(..)
    , PreviouslyLastViewedMessage(..)
    , PushSubscription(..)
    , SetViewing(..)
    , ToBeFilledInByBackend(..)
    , UnreadOverviewData
    , UserOptionSection(..)
    , UserSession
    , ViewDiscordGuildData
    , Viewing(..)
    , Viewing_ChannelData
    , Viewing_ChannelThreadData
    , Viewing_DiscordChannelData
    , Viewing_DiscordChannelThreadData
    , Viewing_DiscordDmData
    , Viewing_DmData
    , Viewing_DmThreadData
    , collapseUserOptionSection
    , expandUserOptionSection
    , init
    , isViewing
    , isViewingGame
    , setPreviouslyLastViewedChannelMessage
    , setPreviouslyLastViewedThreadMessage
    , setSheepGameQuestions
    , setViewingToCurrentlyViewing
    , toFrontend
    , unreadOverviewMessageLimit
    )

import Array exposing (Array)
import Discord
import Effect.Http as Http
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Time as Time
import FileStatus exposing (FileHash)
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadMessageId, ThreadRoute(..), UserId, Viewing_ChannelId, Viewing_ChannelThreadId, Viewing_DiscordChannelId, Viewing_DiscordChannelThreadId, Viewing_DiscordDmId, Viewing_DmId, Viewing_DmThreadId)
import Message exposing (Message)
import PersonName exposing (PersonName)
import Ports exposing (SubscribeData)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SessionIdHash exposing (SessionIdHash)
import UserAgent exposing (UserAgent)


type alias UserSession =
    { userId : Id UserId
    , notificationMode : NotificationMode
    , pushSubscription : PushSubscription
    , userAgent : UserAgent
    , sessionIdHash : SessionIdHash
    , signedInAt : Time.Posix
    , expandedUserOptions : SeqSet UserOptionSection
    , -- Setting a sheep game up takes a while, so the questions the host has written are
      -- kept here. That way an accidental refresh doesn't cost them the lot.
      sheepGameQuestions : Array String
    }


type UserOptionSection
    = UserOption_TwoFactorAuthentication
    | UserOption_Settings
    | UserOption_WhitelistedDomains
    | UserOption_Discord
    | UserOption_ConnectedDevices
    | UserOption_Debug


type alias FrontendUserSession =
    { notificationMode : NotificationMode
    , currentlyViewing : SeqDict ClientId Viewing
    , userAgent : UserAgent
    }


type ChannelHeaderTab
    = ChannelHeaderTab_VoiceChat
    | ChannelHeaderTab_Games (Maybe (Id ChannelMessageId))
    | ChannelHeaderTab_ChannelDescription
    | ChannelHeaderTab_Draw


type PushSubscription
    = NotSubscribed
    | Subscribed SubscribeData Time.Posix
    | SubscriptionError SubscribeData Http.Error
    | SubscriptionJsException String Time.Posix


type NotificationMode
    = NoNotifications
    | NotifyWhenRunning
    | PushNotifications


type SetViewing
    = ViewDm Viewing_DmData (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | ViewDmThread Viewing_DmThreadData (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | ViewDiscordDm Viewing_DiscordDmData (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id Discord.UserId))))
    | ViewChannel Viewing_ChannelData (ToBeFilledInByBackend (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId))))
    | ViewChannelThread Viewing_ChannelThreadData (ToBeFilledInByBackend (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId))))
    | ViewDiscordChannel Viewing_DiscordChannelData (ToBeFilledInByBackend (ViewDiscordGuildData ChannelMessageId))
    | ViewDiscordChannelThread Viewing_DiscordChannelThreadData (ToBeFilledInByBackend (ViewDiscordGuildData ThreadMessageId))
    | StopViewingChannel
    | ViewOverview (ToBeFilledInByBackend UnreadOverviewData)


type Viewing
    = Viewing_Dm Viewing_DmData
    | Viewing_DmThread Viewing_DmThreadData
    | Viewing_DiscordDm Viewing_DiscordDmData
    | Viewing_Channel Viewing_ChannelData
    | Viewing_ChannelThread Viewing_ChannelThreadData
    | Viewing_DiscordChannel Viewing_DiscordChannelData
    | Viewing_DiscordChannelThread Viewing_DiscordChannelThreadData
    | Viewing_None
    | Viewing_Overview


type PreviouslyLastViewedMessage messageId
    = DontCare
    | PreviouslyLastViewedMessage (Id messageId)


type alias Viewing_DmData =
    { id : Viewing_DmId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage ChannelMessageId
    }


type alias Viewing_DmThreadData =
    { id : Viewing_DmThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage ThreadMessageId
    }


type alias Viewing_DiscordDmData =
    { id : Viewing_DiscordDmId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage ChannelMessageId
    }


type alias Viewing_ChannelData =
    { id : Viewing_ChannelId
    , channelHeaderTab : Maybe ChannelHeaderTab
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage ChannelMessageId
    }


type alias Viewing_ChannelThreadData =
    { id : Viewing_ChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage ThreadMessageId
    }


type alias Viewing_DiscordChannelData =
    { id : Viewing_DiscordChannelId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadData =
    { id : Viewing_DiscordChannelThreadId
    , previouslyLastViewedMessage : PreviouslyLastViewedMessage ThreadMessageId
    }


{-| How many of a channel's unread messages the unread overview shows. A channel that has
gone unread for a long time can hold thousands of messages, and the overview is a summary,
so only this many of the newest ones are sent and shown.
-}
unreadOverviewMessageLimit : number
unreadOverviewMessageLimit =
    3


{-| What the unread overview needs from the backend: the unread messages of every channel
the user hasn't read to the end, keyed by the index they sit at in that channel. Only the
newest `unreadOverviewMessageLimit` messages of a channel are included, since a channel
that has gone unread for a long time can hold thousands of them.

The frontend holds the newest message of every channel already, but nothing older than
that for channels the user hasn't opened, and it never has the Discord users of a guild
it isn't looking at, so those come along too.

The threads of a channel are unread separately from the channel itself, so they come
along as well, keyed by the message they were started from. Discord DM channels can't
contain threads, so there's nothing to send for those.

-}
type alias UnreadOverviewData =
    { guildChannels :
        SeqDict
            ( Id GuildId, Id ChannelId )
            (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId)))
    , guildThreads :
        SeqDict
            ( Id GuildId, Id ChannelId, Id ChannelMessageId )
            (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId)))
    , dmChannels : SeqDict (Id UserId) (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId)))
    , dmThreads :
        SeqDict
            ( Id UserId, Id ChannelMessageId )
            (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId)))
    , discordGuildChannels :
        SeqDict
            ( Discord.Id Discord.GuildId, Discord.Id Discord.ChannelId )
            (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id Discord.UserId)))
    , discordGuildThreads :
        SeqDict
            ( Discord.Id Discord.GuildId, Discord.Id Discord.ChannelId, Id ChannelMessageId )
            (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Discord.Id Discord.UserId)))
    , discordDmChannels :
        SeqDict
            (Discord.Id Discord.PrivateChannelId)
            (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id Discord.UserId)))
    , discordUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    }


type alias ViewDiscordGuildData messageId =
    { messages : SeqDict (Id messageId) (Message messageId (Discord.Id Discord.UserId))
    , newUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    }


type alias DiscordFrontendUser =
    { name : PersonName
    , icon : Maybe FileHash
    }


setViewingToCurrentlyViewing : SetViewing -> Viewing
setViewingToCurrentlyViewing viewing =
    case viewing of
        ViewDm data _ ->
            Viewing_Dm data

        ViewDmThread data _ ->
            Viewing_DmThread data

        ViewDiscordDm data _ ->
            Viewing_DiscordDm data

        ViewChannel data _ ->
            Viewing_Channel data

        ViewChannelThread data _ ->
            Viewing_ChannelThread data

        ViewDiscordChannel data _ ->
            Viewing_DiscordChannel data

        ViewDiscordChannelThread data _ ->
            Viewing_DiscordChannelThread data

        StopViewingChannel ->
            Viewing_None

        ViewOverview _ ->
            Viewing_Overview


isViewing : AnyGuildOrDmId -> ThreadRoute -> Viewing -> Bool
isViewing guildOrDmId threadRoute viewing =
    case ( viewing, threadRoute ) of
        ( Viewing_Dm data, NoThread ) ->
            guildOrDmId == GuildOrDmId (GuildOrDmId_Dm data.id)

        ( Viewing_DmThread data, ViewThread threadId ) ->
            guildOrDmId == GuildOrDmId (GuildOrDmId_Dm { otherUserId = data.id.otherUserId }) && data.id.threadId == threadId

        ( Viewing_DiscordDm data, NoThread ) ->
            guildOrDmId == DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId = data.id.currentUserId, channelId = data.id.channelId })

        ( Viewing_Channel data, NoThread ) ->
            guildOrDmId == GuildOrDmId (GuildOrDmId_Guild data.id)

        ( Viewing_ChannelThread data, ViewThread threadId ) ->
            (guildOrDmId == GuildOrDmId (GuildOrDmId_Guild { guildId = data.id.guildId, channelId = data.id.channelId }))
                && (data.id.threadId == threadId)

        ( Viewing_DiscordChannel data, NoThread ) ->
            guildOrDmId == DiscordGuildOrDmId (DiscordGuildOrDmId_Guild data.id)

        ( Viewing_DiscordChannelThread data, ViewThread threadId ) ->
            guildOrDmId
                == DiscordGuildOrDmId
                    (DiscordGuildOrDmId_Guild
                        { currentUserId = data.id.currentUserId
                        , guildId = data.id.guildId
                        , channelId = data.id.channelId
                        }
                    )
                && (data.id.threadId == threadId)

        _ ->
            False


{-| Move the unread divider of the conversation being looked at onto a channel message.
The thread kinds count their messages separately, so they keep the divider they already had.
-}
setPreviouslyLastViewedChannelMessage : Id ChannelMessageId -> Viewing -> Viewing
setPreviouslyLastViewedChannelMessage messageId viewing =
    case viewing of
        Viewing_Dm data ->
            Viewing_Dm { data | previouslyLastViewedMessage = PreviouslyLastViewedMessage messageId }

        Viewing_DiscordDm data ->
            Viewing_DiscordDm { data | previouslyLastViewedMessage = PreviouslyLastViewedMessage messageId }

        Viewing_Channel data ->
            Viewing_Channel { data | previouslyLastViewedMessage = PreviouslyLastViewedMessage messageId }

        Viewing_DiscordChannel data ->
            Viewing_DiscordChannel { data | previouslyLastViewedMessage = PreviouslyLastViewedMessage messageId }

        Viewing_DmThread _ ->
            viewing

        Viewing_ChannelThread _ ->
            viewing

        Viewing_DiscordChannelThread _ ->
            viewing

        Viewing_None ->
            viewing

        Viewing_Overview ->
            viewing


{-| Move the unread divider of the conversation being looked at onto a thread message.
-}
setPreviouslyLastViewedThreadMessage : Id ThreadMessageId -> Viewing -> Viewing
setPreviouslyLastViewedThreadMessage messageId viewing =
    case viewing of
        Viewing_DmThread data ->
            Viewing_DmThread { data | previouslyLastViewedMessage = PreviouslyLastViewedMessage messageId }

        Viewing_ChannelThread data ->
            Viewing_ChannelThread { data | previouslyLastViewedMessage = PreviouslyLastViewedMessage messageId }

        Viewing_DiscordChannelThread data ->
            Viewing_DiscordChannelThread { data | previouslyLastViewedMessage = PreviouslyLastViewedMessage messageId }

        Viewing_Dm _ ->
            viewing

        Viewing_DiscordDm _ ->
            viewing

        Viewing_Channel _ ->
            viewing

        Viewing_DiscordChannel _ ->
            viewing

        Viewing_None ->
            viewing

        Viewing_Overview ->
            viewing


isViewingGame : GuildOrDmId -> Id ChannelMessageId -> Viewing -> Bool
isViewingGame guildOrDmId matchId viewing =
    case viewing of
        Viewing_None ->
            False

        Viewing_Dm data ->
            case data.channelHeaderTab of
                Just (ChannelHeaderTab_Games (Just viewingMatchId)) ->
                    isViewing (GuildOrDmId guildOrDmId) NoThread viewing && (matchId == viewingMatchId)

                _ ->
                    False

        Viewing_DmThread _ ->
            False

        Viewing_DiscordDm _ ->
            False

        Viewing_Channel data ->
            case data.channelHeaderTab of
                Just (ChannelHeaderTab_Games (Just viewingMatchId)) ->
                    isViewing (GuildOrDmId guildOrDmId) NoThread viewing && (matchId == viewingMatchId)

                _ ->
                    False

        Viewing_ChannelThread _ ->
            False

        Viewing_DiscordChannel _ ->
            False

        Viewing_DiscordChannelThread _ ->
            False

        Viewing_Overview ->
            False


type ToBeFilledInByBackend a
    = EmptyPlaceholder
    | FilledInByBackend a


init : Time.Posix -> SessionId -> Id UserId -> UserAgent -> UserSession
init time sessionId userId userAgent =
    { userId = userId
    , notificationMode = NoNotifications
    , pushSubscription = NotSubscribed
    , userAgent = userAgent
    , sessionIdHash = SessionIdHash.fromSessionId sessionId
    , signedInAt = time
    , expandedUserOptions = SeqSet.fromList [ UserOption_Settings ]
    , sheepGameQuestions = Array.empty
    }


expandUserOptionSection : UserOptionSection -> UserSession -> UserSession
expandUserOptionSection section session =
    { session | expandedUserOptions = SeqSet.insert section session.expandedUserOptions }


collapseUserOptionSection : UserOptionSection -> UserSession -> UserSession
collapseUserOptionSection section session =
    { session | expandedUserOptions = SeqSet.remove section session.expandedUserOptions }


setSheepGameQuestions : Array String -> UserSession -> UserSession
setSheepGameQuestions questions session =
    { session | sheepGameQuestions = questions }


toFrontend : Id UserId -> SeqDict ClientId Viewing -> UserSession -> Maybe FrontendUserSession
toFrontend currentUserId currentlyViewing userSession =
    if currentUserId == userSession.userId then
        { notificationMode = userSession.notificationMode
        , currentlyViewing = currentlyViewing
        , userAgent = userSession.userAgent
        }
            |> Just

    else
        Nothing
