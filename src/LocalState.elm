module LocalState exposing
    ( AdminData
    , AdminData_DeletedGuild
    , AdminData_DiscordChannel
    , AdminData_DiscordDmChannel
    , AdminData_DiscordGuild
    , AdminData_DmChannel
    , AdminData_Guild
    , AdminData_GuildChannel
    , AdminStatus(..)
    , Archived
    , BackendChannel
    , BackendGuild
    , CallStatus(..)
    , ChannelStatus(..)
    , ConnectionData
    , DeletedBackendGuild
    , DiscordBackendChannel
    , DiscordBackendGuild
    , DiscordChannelReload
    , DiscordFrontendChannel
    , DiscordFrontendGuild
    , DiscordMessageAlreadyExists(..)
    , DiscordRole
    , DiscordThreadReload
    , DiscordUserData_ForAdmin(..)
    , FrontendChannel
    , FrontendGuild
    , JoinGuildError(..)
    , LastRequest(..)
    , LoadingDiscordChannel(..)
    , LoadingDiscordChannelStep(..)
    , LocalState
    , LogWithTime
    , PrivateVapidKey(..)
    , ServerSecretStatus(..)
    , WebsocketClosedEvent(..)
    , WordSpellingGameStatus(..)
    , addEmbedBackend
    , addEmbedFrontend
    , addInvite
    , addMemberBackend
    , addMemberFrontend
    , addReactionEmoji
    , addReactionEmojiFrontend
    , addReactionEmojiFrontendHelper
    , addReactionEmojiHelper
    , announcementChannel
    , callStartedText
    , canSendDiscordMessage
    , canViewDiscordChannel
    , createChannel
    , createChannelFrontend
    , createChannelMessageBackend
    , createChannelMessageFrontend
    , createDiscordChannelMessageBackend
    , createDiscordDmChannelMessageBackend
    , createDiscordThreadMessageBackend
    , createGuild
    , createThreadMessageBackend
    , createThreadMessageFrontend
    , deleteChannel
    , deleteChannelFrontend
    , deleteForumPostFrontend
    , deleteMessageBackend
    , deleteMessageBackendHelper
    , deleteMessageBackendHelperNoThread
    , deleteMessageFrontend
    , deleteMessageFrontendHelper
    , deleteMessageFrontendNoThread
    , discordAnnouncementChannel
    , discordChannelReloadAttachmentCount
    , discordChannelReloadMessages
    , discordChannelToFrontend
    , discordDmChannelWithUser
    , discordGuildAvailableStickersAndCustomEmojis
    , discordGuildOrDmIdToLatestMessages
    , discordGuildOrDmIdToMessage
    , discordTopicToDescription
    , drawingHandleChangeFrontend
    , drawingHandleChangeHelperBackend
    , drawingHandleChangeNoThreadBackend
    , drawingHandleDateDivider
    , editChannel
    , editGuildName
    , editMessageFrontendHelper
    , editMessageFrontendHelperNoThread
    , editMessageHelper
    , editMessageHelperNoThread
    , gameStartedText
    , getDiscordGuildAndChannel
    , getGuildAndChannel
    , guildOrDmIdToLatestMessages
    , guildOrDmIdToMessage
    , guildOrDmIdToMessagesCount
    , guildToFrontend
    , guildToFrontendForUser
    , incrementLastViewedMessageBackend
    , incrementLastViewedMessageFrontend
    , isDiscordDmChannelReloading
    , isDiscordGuildChannelReloading
    , loadingDiscordChannelMap
    , markAllChannelsAndThreadsAsViewedBackend
    , markAllChannelsAndThreadsAsViewedFrontend
    , markAllDiscordChannelsAndThreadsAsViewedBackend
    , markAllDiscordChannelsAndThreadsAsViewedFrontend
    , markCallMessageAsEndedBackend
    , markCallMessageAsEndedFrontend
    , markDiscordDmAsViewedBackend
    , markDiscordDmAsViewedFrontend
    , memberIsEditTypingBackend
    , memberIsEditTypingBackendHelper
    , memberIsEditTypingBackendHelperNoThread
    , memberIsEditTypingFrontend
    , memberIsEditTypingFrontendHelper
    , memberIsEditTypingFrontendHelperNoThread
    , memberIsTyping
    , memberIsTypingHelper
    , messageDeleted
    , messageReactions
    , messageReactionsHelper
    , messageReactionsNoThread
    , messageToString
    , ownMessageIsReadFrontend
    , removeInvite
    , removeReactionEmoji
    , removeReactionEmojiFrontend
    , removeReactionEmojiFrontendHelper
    , removeReactionEmojiHelper
    , routeToViewing
    , sentEnoughDiscordDmMessages
    , updateChannel
    , userIsLoadingDiscordChannel
    , usersMentionedOrRepliedToBackend
    , usersMentionedOrRepliedToFrontend
    )

import Array exposing (Array)
import Call
import ChannelDescription exposing (ChannelDescription)
import ChannelName exposing (ChannelName)
import Date exposing (Date)
import Discord exposing (OptionalData)
import DiscordUserData exposing (DiscordUserLoadingData)
import DmChannel exposing (DiscordDmChannel, DiscordFrontendDmChannel, FrontendDmChannel)
import DmChannelId exposing (DmChannelId, GuildOrFullDmId(..))
import Drawing exposing (Drawing)
import Effect.Http as Http
import Effect.Lamdera exposing (ClientId)
import Effect.Time as Time
import Effect.Websocket as Websocket
import Embed exposing (EmbedData)
import Emoji exposing (EmojiOrCustomEmoji)
import FileStatus exposing (FileHash)
import Game
import GuildName exposing (GuildName)
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, CustomEmojiId, DiscordGuildOrDmId(..), GamePublicId, GuildId, GuildOrDmId(..), Id, InviteLinkId, StickerId, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId, Viewing_ChannelId, Viewing_DiscordChannelId)
import IdArray exposing (IdArray)
import LinkedAndOtherDiscordUsers
import List.Extra
import List.Nonempty exposing (Nonempty)
import Log exposing (Log)
import Maybe.Extra
import MembersAndOwner exposing (IsMember(..), MembersAndOwner)
import Message exposing (ChangeAttachments, Message(..), MessageNoReply(..), UserTextMessageDataNoReply)
import MessageArray exposing (MessageArray)
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import OneToOne exposing (OneToOne)
import Pagination exposing (Pagination)
import PersonName exposing (PersonName)
import Postmark
import RichText exposing (RichText)
import Route exposing (ChannelRoute(..), ChannelsVisibleOnMobile(..), DiscordChannelRoute(..), Route(..), ThreadRouteWithFriends(..))
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqDictHelper
import SeqSet exposing (SeqSet)
import SessionIdHash exposing (SessionIdHash)
import Slack
import TextEditor
import Thread exposing (BackendThread, DiscordBackendThread, DiscordFrontendThread, FrontendGenericThread, FrontendThread, LastTypedAt)
import ToBackendLog exposing (ToBackendLogData)
import UInt64
import Unsafe
import Url exposing (Url)
import User exposing (BackendUser, FrontendCurrentUser, LocalUser)
import UserSession exposing (ChannelHeaderTab, FrontendUserSession, PreviouslyLastViewedMessage(..), SetViewing(..), ToBeFilledInByBackend(..), UserSession)
import VisibleMessages exposing (VisibleMessages)


type alias LocalState =
    { adminData : AdminStatus
    , guilds : SeqDict (Id GuildId) FrontendGuild
    , discordGuilds : SeqDict (Discord.Id Discord.GuildId) DiscordFrontendGuild
    , dmChannels : SeqDict (Id UserId) FrontendDmChannel
    , discordDmChannels : SeqDict (Discord.Id Discord.PrivateChannelId) DiscordFrontendDmChannel
    , joinGuildError : Maybe JoinGuildError
    , localUser : LocalUser
    , otherSessions : SeqDict SessionIdHash FrontendUserSession
    , publicVapidKey : String
    , textEditor : TextEditor.LocalState
    , calls : Call.Local
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias BackendGuild =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe FileHash
    , channels : SeqDict (Id ChannelId) BackendChannel
    , membersAndOwner : MembersAndOwner (Id UserId) { joinedAt : Time.Posix }
    , invites : SeqDict (SecretId InviteLinkId) { createdAt : Time.Posix, createdBy : Id UserId }
    }


type alias DeletedBackendGuild =
    { guild : BackendGuild, deletedAt : Time.Posix }


type alias DiscordBackendGuild =
    { name : GuildName
    , icon : Maybe FileHash
    , channels : SeqDict (Discord.Id Discord.ChannelId) DiscordBackendChannel
    , membersAndOwner : MembersAndOwner (Discord.Id Discord.UserId) { joinedAt : Maybe Time.Posix, roles : SeqSet (Discord.Id Discord.RoleId) }
    , stickers : SeqSet (Id StickerId)
    , customEmojis : SeqSet (Id CustomEmojiId)
    , roles : SeqDict (Discord.Id Discord.RoleId) DiscordRole
    }


type alias FrontendGuild =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe FileHash
    , channels : SeqDict (Id ChannelId) FrontendChannel
    , membersAndOwner : MembersAndOwner (Id UserId) { joinedAt : Time.Posix }
    , invites : SeqDict (SecretId InviteLinkId) { createdAt : Time.Posix, createdBy : Id UserId }
    }


type alias DiscordFrontendGuild =
    { name : GuildName
    , icon : Maybe FileHash
    , channels : SeqDict (Discord.Id Discord.ChannelId) DiscordFrontendChannel
    , membersAndOwner : MembersAndOwner (Discord.Id Discord.UserId) { joinedAt : Maybe Time.Posix, roles : SeqSet (Discord.Id Discord.RoleId) }
    , stickers : SeqSet (Id StickerId)
    , customEmojis : SeqSet (Id CustomEmojiId)
    , roles : SeqDict (Discord.Id Discord.RoleId) DiscordRole
    }


type alias DiscordRole =
    { name : String
    , description : Maybe String
    , permissions : Discord.Permissions
    }


guildToFrontendForUser :
    Id GuildId
    -> Maybe ( Id ChannelId, ( ThreadRoute, Maybe ChannelHeaderTab ) )
    -> Id UserId
    -> OneToOne (SecretId GamePublicId) ( GuildOrFullDmId, Id ChannelMessageId )
    -> BackendGuild
    -> Maybe FrontendGuild
guildToFrontendForUser guildId requestMessagesFor userId goMatchPublicIds guild =
    case MembersAndOwner.isMember userId guild.membersAndOwner of
        IsNotMember ->
            Nothing

        _ ->
            { createdAt = guild.createdAt
            , createdBy = guild.createdBy
            , name = guild.name
            , icon = guild.icon
            , channels =
                SeqDict.filterMap
                    (\channelId channel ->
                        channelToFrontend
                            guildId
                            channelId
                            (case requestMessagesFor of
                                Just ( channelIdB, threadRoute ) ->
                                    if channelId == channelIdB then
                                        Just threadRoute

                                    else
                                        Nothing

                                _ ->
                                    Nothing
                            )
                            goMatchPublicIds
                            channel
                    )
                    guild.channels
            , membersAndOwner = guild.membersAndOwner
            , invites = guild.invites
            }
                |> Just


guildToFrontend :
    Id GuildId
    -> Maybe ( Id ChannelId, ( ThreadRoute, Maybe ChannelHeaderTab ) )
    -> OneToOne (SecretId GamePublicId) ( GuildOrFullDmId, Id ChannelMessageId )
    -> BackendGuild
    -> FrontendGuild
guildToFrontend guildId requestMessagesFor goMatchPublicIds guild =
    { createdAt = guild.createdAt
    , createdBy = guild.createdBy
    , name = guild.name
    , icon = guild.icon
    , channels =
        SeqDict.filterMap
            (\channelId channel ->
                channelToFrontend
                    guildId
                    channelId
                    (case requestMessagesFor of
                        Just ( channelIdB, threadRoute ) ->
                            if channelId == channelIdB then
                                Just threadRoute

                            else
                                Nothing

                        _ ->
                            Nothing
                    )
                    goMatchPublicIds
                    channel
            )
            guild.channels
    , membersAndOwner = guild.membersAndOwner
    , invites = guild.invites
    }


type alias BackendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , description : ChannelDescription
    , messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    , games : SeqDict (Id ChannelMessageId) Game.BackendGameData
    }


type alias DiscordBackendChannel =
    { name : ChannelName
    , description : ChannelDescription
    , isForum : Bool
    , messages : IdArray ChannelMessageId (Message ChannelMessageId (Discord.Id Discord.UserId))
    , status : ChannelStatus
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
    , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) DiscordBackendThread
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    , permissionOverwrites : List Discord.Overwrite
    }


type alias FrontendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , description : ChannelDescription
    , messages : MessageArray ChannelMessageId (Message ChannelMessageId (Id UserId))
    , visibleMessages : VisibleMessages ChannelMessageId
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) FrontendThread
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    , games : SeqDict (Id ChannelMessageId) Game.MatchData
    }


type alias DiscordFrontendChannel =
    { name : ChannelName
    , description : ChannelDescription
    , isForum : Bool
    , messages : MessageArray ChannelMessageId (Message ChannelMessageId (Discord.Id Discord.UserId))
    , visibleMessages : VisibleMessages ChannelMessageId
    , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) DiscordFrontendThread
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    , permissionOverwrites : List Discord.Overwrite
    }


messageReactions : GuildOrDmId -> ThreadRouteWithMessage -> LocalState -> SeqDict EmojiOrCustomEmoji (NonemptySet (Id UserId))
messageReactions guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId_Guild id ->
            case getGuildAndChannel id local of
                Just ( _, channel ) ->
                    messageReactionsHelper channel threadRoute

                Nothing ->
                    SeqDict.empty

        GuildOrDmId_Dm { otherUserId } ->
            case SeqDict.get otherUserId local.dmChannels of
                Just channel ->
                    messageReactionsHelper channel threadRoute

                Nothing ->
                    SeqDict.empty


messageReactionsHelper :
    { a
        | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
        , threads : SeqDict (Id ChannelMessageId) { b | messages : MessageArray ThreadMessageId (Message ThreadMessageId userId) }
    }
    -> ThreadRouteWithMessage
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
messageReactionsHelper channel threadRoute2 =
    case threadRoute2 of
        NoThreadWithMessage messageId ->
            messageReactionsNoThread messageId channel

        ViewThreadWithMessage threadId messageId ->
            case SeqDict.get threadId channel.threads of
                Just thread ->
                    messageReactionsNoThread messageId thread

                Nothing ->
                    SeqDict.empty


messageReactionsNoThread :
    Id messageId
    -> { a | messages : MessageArray messageId (Message messageId userId) }
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
messageReactionsNoThread messageId channel =
    case MessageArray.get messageId channel.messages of
        Just message ->
            Message.reactionEmojis message

        _ ->
            SeqDict.empty


messageToString : Time.Zone -> SeqDict userId { a | name : PersonName } -> Message messageId userId -> String
messageToString timezone allUsers3 message =
    case message of
        UserTextMessage a ->
            RichText.toString timezone False allUsers3 a.content

        UserJoinedMessage _ userId _ _ ->
            User.toString userId allUsers3
                ++ " joined!"

        DeletedMessage _ ->
            messageDeleted

        CallStarted callStarted ->
            callStartedText callStarted.endedAt

        GameStarted gameStarted ->
            gameStartedText gameStarted.gameType


callStartedText : Maybe Time.Posix -> String
callStartedText endedAt =
    case endedAt of
        Just _ ->
            "Call ended"

        Nothing ->
            "Call started"


gameStartedText : Message.GameType -> String
gameStartedText game =
    case game of
        Message.GameType_Go ->
            "Go match started"

        Message.GameType_WordSpellingGame ->
            "Word Spelling Game started"

        Message.GameType_SheepGame ->
            "Sheep Game started"


messageDeleted : String
messageDeleted =
    "Message deleted"


channelToFrontend :
    Id GuildId
    -> Id ChannelId
    -> Maybe ( ThreadRoute, Maybe ChannelHeaderTab )
    -> OneToOne (SecretId GamePublicId) ( GuildOrFullDmId, Id ChannelMessageId )
    -> BackendChannel
    -> Maybe FrontendChannel
channelToFrontend guildId channelId threadRoute goMatchPublicIds channel =
    case channel.status of
        ChannelActive ->
            let
                preloadMessages =
                    Just NoThread == Maybe.map Tuple.first threadRoute
            in
            { createdAt = channel.createdAt
            , createdBy = channel.createdBy
            , name = channel.name
            , description = channel.description
            , messages = DmChannel.toFrontendHelper preloadMessages channel
            , visibleMessages = VisibleMessages.init preloadMessages (IdArray.length channel.messages)
            , isArchived = Nothing
            , lastTypedAt = channel.lastTypedAt
            , threads =
                SeqDict.map
                    (\threadId thread ->
                        Thread.toFrontend (Just (ViewThread threadId) == Maybe.map Tuple.first threadRoute) thread
                    )
                    channel.threads
            , dateDividerDrawings = channel.dateDividerDrawings
            , games =
                DmChannel.gamesToFrontend
                    (GuildOrFullDmId_Guild guildId channelId)
                    threadRoute
                    goMatchPublicIds
                    channel
            }
                |> Just

        ChannelDeleted _ ->
            Nothing


canViewDiscordChannel :
    Discord.Id Discord.GuildId
    -> { a | permissionOverwrites : List Discord.Overwrite }
    ->
        { b
            | membersAndOwner : MembersAndOwner (Discord.Id Discord.UserId) { c | roles : SeqSet (Discord.Id Discord.RoleId) }
            , roles : SeqDict (Discord.Id Discord.RoleId) DiscordRole
        }
    -> Discord.Id Discord.UserId
    -> Bool
canViewDiscordChannel guildId channel guild userId =
    Discord.memberHasChannelPermission
        .viewChannel
        guildId
        (MembersAndOwner.owner guild.membersAndOwner)
        (List.map
            (\( roleId, role ) -> { id = roleId, permissions = role.permissions })
            (SeqDict.toList guild.roles)
        )
        { userId = userId
        , roles =
            case SeqDict.get userId (MembersAndOwner.members guild.membersAndOwner) of
                Just memberData ->
                    SeqSet.toList memberData.roles

                Nothing ->
                    []
        }
        channel.permissionOverwrites


discordChannelToFrontend :
    Discord.Id Discord.GuildId
    -> DiscordBackendGuild
    -> SeqDict (Discord.Id Discord.UserId) a
    -> Maybe ThreadRoute
    -> DiscordBackendChannel
    -> Maybe DiscordFrontendChannel
discordChannelToFrontend guildId guild linkedDiscordUsers threadRoute channel =
    let
        canView =
            List.any
                (canViewDiscordChannel guildId channel guild)
                (SeqDict.keys linkedDiscordUsers)
    in
    case ( canView, channel.status ) of
        ( True, ChannelActive ) ->
            let
                preloadMessages =
                    Just NoThread == threadRoute
            in
            { name = channel.name
            , description = channel.description
            , isForum = channel.isForum
            , messages = DmChannel.toDiscordFrontendHelper preloadMessages channel
            , visibleMessages = VisibleMessages.init preloadMessages (IdArray.length channel.messages)
            , lastTypedAt = channel.lastTypedAt
            , threads =
                SeqDict.map
                    (\threadId thread -> Thread.discordToFrontend (Just (ViewThread threadId) == threadRoute) thread)
                    channel.threads
            , dateDividerDrawings = channel.dateDividerDrawings
            , permissionOverwrites = channel.permissionOverwrites
            }
                |> Just

        _ ->
            Nothing


type alias Archived =
    { archivedAt : Time.Posix, archivedBy : Id UserId }


type ChannelStatus
    = ChannelActive
    | ChannelDeleted { deletedAt : Time.Posix, deletedBy : Id UserId }


type AdminStatus
    = IsAdmin AdminData
    | IsAdminButDataNotLoaded
    | IsNotAdmin


type alias LogWithTime =
    { time : Time.Posix, log : Log, isHidden : Bool }


type alias AdminData =
    { users : NonemptyDict (Id UserId) BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict (Id UserId) Time.Posix
    , privateVapidKey : PrivateVapidKey
    , slackClientSecret : Maybe Slack.ClientSecret
    , openRouterKey : Maybe String
    , postmarkKey : Postmark.ApiKey
    , dmChannels : SeqDict DmChannelId AdminData_DmChannel
    , discordDmChannels :
        SeqDict
            (Discord.Id Discord.PrivateChannelId)
            AdminData_DiscordDmChannel
    , discordUsers : SeqDict (Discord.Id Discord.UserId) DiscordUserData_ForAdmin
    , discordGuilds : SeqDict (Discord.Id Discord.GuildId) AdminData_DiscordGuild
    , guilds : SeqDict (Id GuildId) AdminData_Guild
    , deletedGuilds : SeqDict (Id GuildId) AdminData_DeletedGuild
    , loadingDiscordChannels : SeqDict (Discord.Id Discord.UserId) (LoadingDiscordChannel Int)
    , signupsEnabled : Bool
    , discordLinkingEnabled : Bool
    , logs : Pagination LogWithTime
    , connections : SeqDict SessionIdHash (NonemptyDict ClientId ConnectionData)
    , filesCount : Int
    , toBackendLogs : Array ToBackendLogData
    , vulnerabilityChecks : String
    , serverSecretRefreshedAt : ServerSecretStatus
    , websocketCloseEvents : Array WebsocketClosedEvent
    , sessions : SeqDict SessionIdHash UserSession
    , wordSpellingGameEnglish : WordSpellingGameStatus
    , wordSpellingGameSwedish : WordSpellingGameStatus
    }


{-| A summary of the backend's word spelling game word list state, suitable for showing in the
admin page without sending the entire word list to the frontend.
-}
type WordSpellingGameStatus
    = WordSpellingGameStatus_NotLoaded
    | WordSpellingGameStatus_Loading
    | WordSpellingGameStatus_Error Http.Error
    | WordSpellingGameStatus_Loaded


type WebsocketClosedEvent
    = WebsocketClosed_CloseAndReopenForUser (Discord.Id Discord.UserId) Time.Posix
    | WebsocketClosed_UnlinkDiscordUser (Discord.Id Discord.UserId) Time.Posix
    | WebsocketClosed_ClosedByBackendForUser (Discord.Id Discord.UserId) Time.Posix
    | WebsocketClosed_ListenCloseEvent (Discord.Id Discord.UserId) Websocket.CloseEventCode String Time.Posix


type alias ConnectionData =
    { lastRequest : LastRequest
    , call : CallStatus
    , remoteCallData : Call.RemoteCallData
    , currentlyViewing : UserSession.Viewing
    }


type CallStatus
    = NotInCall
    | ConnectedToCall Call.CallId


type ServerSecretStatus
    = NotBeingRegenerated (Maybe Time.Posix)
    | BeingRegenerated
    | RegenerationFailed Http.Error


type LastRequest
    = NoRequestsMade
    | LastRequest Time.Posix


type LoadingDiscordChannel messages
    = LoadingDiscordDmChannel Time.Posix (Discord.Id Discord.PrivateChannelId) (LoadingDiscordChannelStep messages)
    | LoadingDiscordGuildChannel Time.Posix (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId) (LoadingDiscordChannelStep messages)


type LoadingDiscordChannelStep messages
    = LoadingDiscordChannelMessages
    | LoadingDiscordChannelMessagesFailed Discord.HttpError
    | LoadingDiscordChannelAttachments Time.Posix messages


{-| Everything that was loaded from Discord when a channel gets reloaded. `messages` and
each thread's messages are in the order Discord returns them, newest first. DM channels
have no threads.
-}
type alias DiscordChannelReload =
    { messages : List Discord.Message
    , threads : List DiscordThreadReload
    }


{-| The messages of a thread that hangs off the message with the same id as `threadId`.
-}
type alias DiscordThreadReload =
    { threadId : Discord.Id Discord.ChannelId
    , messages : List Discord.Message
    }


{-| Every message that was loaded, so that the attachments of a channel and its threads can
be uploaded in one go.
-}
discordChannelReloadMessages : DiscordChannelReload -> List Discord.Message
discordChannelReloadMessages reload =
    reload.messages ++ List.concatMap .messages reload.threads


{-| How many attachments have to be uploaded for everything that was loaded when a Discord
channel is reloaded. The admin page shows it while it waits for the uploads to finish.
-}
discordChannelReloadAttachmentCount : DiscordChannelReload -> Int
discordChannelReloadAttachmentCount reload =
    List.foldl
        (\message count -> count + List.length message.attachments)
        0
        (discordChannelReloadMessages reload)


userIsLoadingDiscordChannel : Discord.Id Discord.UserId -> SeqDict (Discord.Id Discord.UserId) (LoadingDiscordChannel a) -> Bool
userIsLoadingDiscordChannel userId loadingDiscordChannels =
    case SeqDict.get userId loadingDiscordChannels of
        Just (LoadingDiscordGuildChannel _ _ _ step) ->
            case step of
                LoadingDiscordChannelMessages ->
                    True

                LoadingDiscordChannelMessagesFailed _ ->
                    False

                LoadingDiscordChannelAttachments _ _ ->
                    True

        Just (LoadingDiscordDmChannel _ _ step) ->
            case step of
                LoadingDiscordChannelMessages ->
                    True

                LoadingDiscordChannelMessagesFailed _ ->
                    False

                LoadingDiscordChannelAttachments _ _ ->
                    True

        Nothing ->
            False


isDiscordGuildChannelReloading :
    Discord.Id Discord.ChannelId
    -> SeqDict (Discord.Id Discord.UserId) (LoadingDiscordChannel a)
    -> Maybe (LoadingDiscordChannelStep a)
isDiscordGuildChannelReloading channelId loadingDiscordChannels =
    List.Extra.findMap
        (\( _, loading ) ->
            case loading of
                LoadingDiscordGuildChannel _ _ otherChannelId step ->
                    if channelId == otherChannelId then
                        Just step

                    else
                        Nothing

                LoadingDiscordDmChannel _ _ _ ->
                    Nothing
        )
        (SeqDict.toList loadingDiscordChannels)


{-| The one-on-one Discord DM channel we share with the given user, paired with whichever
of our linked Discord accounts that channel belongs to. Group DMs are skipped since they
aren't a conversation with just that user.
-}
discordDmChannelWithUser :
    Discord.Id Discord.UserId
    -> LocalState
    -> Maybe ( Discord.Id Discord.UserId, Discord.Id Discord.PrivateChannelId )
discordDmChannelWithUser otherUserId local =
    List.Extra.findMap
        (\( channelId, channel ) ->
            if NonemptyDict.size channel.members == 2 && NonemptyDict.member otherUserId channel.members then
                List.Extra.findMap
                    (\currentUserId ->
                        if currentUserId /= otherUserId && NonemptyDict.member currentUserId channel.members then
                            Just ( currentUserId, channelId )

                        else
                            Nothing
                    )
                    (SeqDict.keys (LinkedAndOtherDiscordUsers.linkedUsers local.localUser.discordUsers))

            else
                Nothing
        )
        (SeqDict.toList local.discordDmChannels)


isDiscordDmChannelReloading :
    Discord.Id Discord.PrivateChannelId
    -> SeqDict (Discord.Id Discord.UserId) (LoadingDiscordChannel a)
    -> Maybe (LoadingDiscordChannelStep a)
isDiscordDmChannelReloading channelId loadingDiscordChannels =
    List.Extra.findMap
        (\( _, loading ) ->
            case loading of
                LoadingDiscordGuildChannel _ _ _ _ ->
                    Nothing

                LoadingDiscordDmChannel _ otherChannelId step ->
                    if channelId == otherChannelId then
                        Just step

                    else
                        Nothing
        )
        (SeqDict.toList loadingDiscordChannels)


loadingDiscordChannelMap : (a -> b) -> LoadingDiscordChannel a -> LoadingDiscordChannel b
loadingDiscordChannelMap mapFunc channel =
    case channel of
        LoadingDiscordDmChannel startTime channelId step ->
            (case step of
                LoadingDiscordChannelMessages ->
                    LoadingDiscordChannelMessages

                LoadingDiscordChannelMessagesFailed error ->
                    LoadingDiscordChannelMessagesFailed error

                LoadingDiscordChannelAttachments time messages ->
                    LoadingDiscordChannelAttachments time (mapFunc messages)
            )
                |> LoadingDiscordDmChannel startTime channelId

        LoadingDiscordGuildChannel startTime guildId channelId step ->
            (case step of
                LoadingDiscordChannelMessages ->
                    LoadingDiscordChannelMessages

                LoadingDiscordChannelMessagesFailed error ->
                    LoadingDiscordChannelMessagesFailed error

                LoadingDiscordChannelAttachments time messages ->
                    LoadingDiscordChannelAttachments time (mapFunc messages)
            )
                |> LoadingDiscordGuildChannel startTime guildId channelId


type alias AdminData_DiscordDmChannel =
    { members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
    , messageCount : Int
    , firstMessage : Maybe (Message ChannelMessageId (Discord.Id Discord.UserId))
    }


type alias AdminData_DmChannel =
    { messageCount : Int
    , threadCount : Int
    }


type alias AdminData_Guild =
    { name : GuildName
    , channels : SeqDict (Id ChannelId) AdminData_GuildChannel
    , memberCount : Int
    , owner : Id UserId
    }


type alias AdminData_DeletedGuild =
    { name : GuildName
    , owner : Id UserId
    , memberCount : Int
    , deletedAt : Time.Posix
    }


type alias AdminData_GuildChannel =
    { name : ChannelName
    , messageCount : Int
    }


type alias AdminData_DiscordGuild =
    { name : GuildName
    , channels : SeqDict (Discord.Id Discord.ChannelId) AdminData_DiscordChannel
    , membersAndOwner :
        MembersAndOwner
            (Discord.Id Discord.UserId)
            { joinedAt : Maybe Time.Posix
            , roles : SeqSet (Discord.Id Discord.RoleId)
            }
    , roles : SeqDict (Discord.Id Discord.RoleId) DiscordRole
    }


type alias AdminData_DiscordChannel =
    { name : ChannelName
    , messageCount : Int
    , threadCount : Int
    , firstMessage : Maybe (Message ChannelMessageId (Discord.Id Discord.UserId))
    , permissionOverwrites : List Discord.Overwrite
    }


type DiscordUserData_ForAdmin
    = BasicData_ForAdmin { user : Discord.PartialUser, icon : Maybe FileHash }
    | FullData_ForAdmin
        { user : Discord.User
        , linkedTo : Id UserId
        , icon : Maybe FileHash
        , linkedAt : Time.Posix
        , isLoadingData : DiscordUserLoadingData
        }
    | NeedsAuthAgain_ForAdmin
        { user : Discord.User
        , linkedTo : Id UserId
        , icon : Maybe FileHash
        , linkedAt : Time.Posix
        }


type PrivateVapidKey
    = PrivateVapidKey String



--getMessages : GuildOrDmId -> LocalState -> Maybe ( ThreadRoute, IdArray messageId (Message messageId) )
--getMessages ( guildOrDmId, threadRoute ) local =
--    case guildOrDmId of
--        GuildOrDmId_Guild_NoThread guildId channelId ->
--            case getGuildAndChannel { guildId = guildId, channelId = channelId } local of
--                Just ( _, channel ) ->
--                    case threadRoute of
--                        ViewThread threadMessageIndex ->
--                            case SeqDict.get threadMessageIndex channel.threads of
--                                Just thread ->
--                                    Just ( threadRoute, thread.messages )
--
--                                Nothing ->
--                                    Nothing
--
--                        NoThread ->
--                            Just ( threadRoute, channel.messages )
--
--                Nothing ->
--                    Nothing
--
--        GuildOrDmId_Dm_NoThread otherUserId ->
--            case SeqDict.get otherUserId local.dmChannels of
--                Just dmChannel ->
--                    case threadRoute of
--                        ViewThread threadMessageIndex ->
--                            case SeqDict.get threadMessageIndex dmChannel.threads of
--                                Just thread ->
--                                    Just ( threadRoute, thread.messages )
--
--                                Nothing ->
--                                    Nothing
--
--                        NoThread ->
--                            Just ( threadRoute, dmChannel.messages )
--
--                Nothing ->
--                    Nothing


createThreadMessageBackend :
    Id ChannelMessageId
    -> Message ThreadMessageId (Id UserId)
    ->
        { d
            | messages : IdArray messageId (Message messageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
            , threads : SeqDict (Id ChannelMessageId) BackendThread
        }
    ->
        ( Id ThreadMessageId
        , { d
            | messages : IdArray messageId (Message messageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
            , threads : SeqDict (Id ChannelMessageId) BackendThread
          }
        )
createThreadMessageBackend threadId message channel =
    let
        thread =
            SeqDict.get threadId channel.threads |> Maybe.withDefault Thread.backendInit

        ( messageId, thread2 ) =
            createMessageBackend message thread
    in
    ( messageId, { channel | threads = SeqDict.insert threadId thread2 channel.threads } )


createChannelMessageBackend :
    Message ChannelMessageId (Id UserId)
    ->
        { d
            | messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
        }
    ->
        ( Id ChannelMessageId
        , { d
            | messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
          }
        )
createChannelMessageBackend message channel =
    createMessageBackend message channel


createMessageBackend :
    Message messageId (Id UserId)
    ->
        { d
            | messages : IdArray messageId (Message messageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
        }
    ->
        ( Id messageId
        , { d
            | messages : IdArray messageId (Message messageId (Id UserId))
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt messageId)
          }
        )
createMessageBackend message channel =
    ( IdArray.length channel.messages |> Id.fromInt
    , { channel
        | messages = IdArray.push message channel.messages
        , lastTypedAt =
            case message of
                UserTextMessage { createdBy } ->
                    SeqDict.remove createdBy channel.lastTypedAt

                UserJoinedMessage _ _ _ _ ->
                    channel.lastTypedAt

                DeletedMessage _ ->
                    channel.lastTypedAt

                CallStarted _ ->
                    channel.lastTypedAt

                GameStarted _ ->
                    channel.lastTypedAt
      }
    )


type DiscordMessageAlreadyExists
    = DiscordMessageAlreadyExists


createDiscordChannelMessageBackend :
    Discord.Id Discord.MessageId
    -> Message ChannelMessageId (Discord.Id Discord.UserId)
    -> DiscordBackendChannel
    -> Result DiscordMessageAlreadyExists ( Id ChannelMessageId, DiscordBackendChannel )
createDiscordChannelMessageBackend messageId message channel =
    createDiscordMessageBackend messageId message channel


createDiscordThreadMessageBackend :
    Discord.Id Discord.MessageId
    -> Id ChannelMessageId
    -> Message ThreadMessageId (Discord.Id Discord.UserId)
    -> DiscordBackendChannel
    -> Result DiscordMessageAlreadyExists ( Id ThreadMessageId, DiscordBackendChannel )
createDiscordThreadMessageBackend messageId threadId message channel =
    let
        thread : DiscordBackendThread
        thread =
            SeqDict.get threadId channel.threads |> Maybe.withDefault Thread.discordBackendInit
    in
    case createDiscordMessageBackend messageId message thread of
        Ok ( messageId2, thread2 ) ->
            Ok ( messageId2, { channel | threads = SeqDict.insert threadId thread2 channel.threads } )

        Err err ->
            Err err


createDiscordDmChannelMessageBackend :
    Discord.Id Discord.MessageId
    -> Message ChannelMessageId (Discord.Id Discord.UserId)
    -> DiscordDmChannel
    -> Result DiscordMessageAlreadyExists ( Id ChannelMessageId, DiscordDmChannel )
createDiscordDmChannelMessageBackend messageId message channel =
    case createDiscordMessageBackend messageId message channel of
        Ok ( messageId2, channel2 ) ->
            case message of
                UserTextMessage message2 ->
                    ( messageId2
                    , { channel2
                        | members =
                            NonemptyDict.updateIfExists
                                message2.createdBy
                                (\a -> { a | messagesSent = a.messagesSent + 1 })
                                channel2.members
                      }
                    )
                        |> Ok

                UserJoinedMessage _ _ _ _ ->
                    Ok ( messageId2, channel2 )

                DeletedMessage _ ->
                    Ok ( messageId2, channel2 )

                CallStarted _ ->
                    Ok ( messageId2, channel2 )

                GameStarted _ ->
                    Ok ( messageId2, channel2 )

        Err error ->
            Err error


createDiscordMessageBackend :
    Discord.Id Discord.MessageId
    -> Message messageId (Discord.Id Discord.UserId)
    ->
        { d
            | messages : IdArray messageId (Message messageId (Discord.Id Discord.UserId))
            , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt messageId)
            , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id messageId)
        }
    ->
        Result
            DiscordMessageAlreadyExists
            ( Id messageId
            , { d
                | messages : IdArray messageId (Message messageId (Discord.Id Discord.UserId))
                , lastTypedAt : SeqDict (Discord.Id Discord.UserId) (LastTypedAt messageId)
                , linkedMessageIds : OneToOne (Discord.Id Discord.MessageId) (Id messageId)
              }
            )
createDiscordMessageBackend messageId message channel =
    if OneToOne.memberFirst messageId channel.linkedMessageIds then
        Err DiscordMessageAlreadyExists

    else
        ( IdArray.length channel.messages |> Id.fromInt
        , { channel
            | messages = IdArray.push message channel.messages
            , lastTypedAt =
                case message of
                    UserTextMessage { createdBy } ->
                        SeqDict.remove createdBy channel.lastTypedAt

                    UserJoinedMessage _ _ _ _ ->
                        channel.lastTypedAt

                    DeletedMessage _ ->
                        channel.lastTypedAt

                    CallStarted _ ->
                        channel.lastTypedAt

                    GameStarted _ ->
                        channel.lastTypedAt
            , linkedMessageIds =
                OneToOne.insert messageId (IdArray.length channel.messages |> Id.fromInt) channel.linkedMessageIds
          }
        )
            |> Ok


createThreadMessageFrontend :
    Id ChannelMessageId
    -> Message ThreadMessageId userId
    ->
        { d
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
        }
    ->
        { d
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
        }
createThreadMessageFrontend threadId message channel =
    { channel
        | threads =
            SeqDict.update
                threadId
                (\maybe ->
                    Maybe.withDefault Thread.frontendInit maybe
                        |> createMessageFrontend message
                        |> Just
                )
                channel.threads
    }


createChannelMessageFrontend :
    Message ChannelMessageId userId
    ->
        { d
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
        }
    ->
        { d
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , visibleMessages : VisibleMessages ChannelMessageId
            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
        }
createChannelMessageFrontend message channel =
    createMessageFrontend message channel


createMessageFrontend :
    Message messageId userId
    ->
        { d
            | messages : MessageArray messageId (Message messageId userId)
            , visibleMessages : VisibleMessages messageId
            , lastTypedAt : SeqDict userId (LastTypedAt messageId)
        }
    ->
        { d
            | messages : MessageArray messageId (Message messageId userId)
            , visibleMessages : VisibleMessages messageId
            , lastTypedAt : SeqDict userId (LastTypedAt messageId)
        }
createMessageFrontend message channel =
    { channel
        | messages = MessageArray.push message channel.messages
        , visibleMessages = VisibleMessages.increment (MessageArray.length channel.messages) channel.visibleMessages
        , lastTypedAt =
            case message of
                UserTextMessage { createdBy } ->
                    SeqDict.remove createdBy channel.lastTypedAt

                UserJoinedMessage _ _ _ _ ->
                    channel.lastTypedAt

                DeletedMessage _ ->
                    channel.lastTypedAt

                CallStarted _ ->
                    channel.lastTypedAt

                GameStarted _ ->
                    channel.lastTypedAt
    }


createGuild : Time.Posix -> Id UserId -> GuildName -> BackendGuild
createGuild time userId guildName =
    { createdAt = time
    , createdBy = userId
    , name = guildName
    , icon = Nothing
    , channels =
        SeqDict.fromList
            [ ( Id.fromInt 0
              , { createdAt = time
                , createdBy = userId
                , name = defaultChannelName
                , description = ChannelDescription.empty
                , messages = IdArray.empty
                , status = ChannelActive
                , lastTypedAt = SeqDict.empty
                , threads = SeqDict.empty
                , dateDividerDrawings = SeqDict.empty
                , games = SeqDict.empty
                }
              )
            ]
    , membersAndOwner = MembersAndOwner.init SeqDict.empty userId
    , invites = SeqDict.empty
    }


defaultChannelName : ChannelName
defaultChannelName =
    Unsafe.channelName "general"


createChannel : Time.Posix -> Id UserId -> ChannelName -> ChannelDescription -> BackendGuild -> BackendGuild
createChannel time userId channelName channelDescription guild =
    let
        channelId : Id ChannelId
        channelId =
            Id.nextId guild.channels
    in
    { guild
        | channels =
            SeqDict.insert
                channelId
                { createdAt = time
                , createdBy = userId
                , name = channelName
                , description = channelDescription
                , messages = IdArray.empty
                , status = ChannelActive
                , lastTypedAt = SeqDict.empty
                , threads = SeqDict.empty
                , dateDividerDrawings = SeqDict.empty
                , games = SeqDict.empty
                }
                guild.channels
    }


discordTopicToDescription : OptionalData (Maybe String) -> ChannelDescription -> ChannelDescription
discordTopicToDescription topic existingDescription =
    case topic of
        Discord.Included (Just topic2) ->
            ChannelDescription.fromStringLossy topic2

        Discord.Included Nothing ->
            ChannelDescription.empty

        Discord.Missing ->
            existingDescription


createChannelFrontend : Time.Posix -> Id UserId -> ChannelName -> ChannelDescription -> FrontendGuild -> FrontendGuild
createChannelFrontend time userId channelName channelDescription guild =
    { guild
        | channels =
            SeqDict.insert
                (Id.nextId guild.channels)
                { createdAt = time
                , createdBy = userId
                , name = channelName
                , description = channelDescription
                , messages = MessageArray.empty
                , visibleMessages = VisibleMessages.empty
                , isArchived = Nothing
                , lastTypedAt = SeqDict.empty
                , threads = SeqDict.empty
                , dateDividerDrawings = SeqDict.empty
                , games = SeqDict.empty
                }
                guild.channels
    }


editChannel :
    ChannelName
    -> ChannelDescription
    -> Id ChannelId
    -> { c | channels : SeqDict (Id ChannelId) { d | name : ChannelName, description : ChannelDescription } }
    -> { c | channels : SeqDict (Id ChannelId) { d | name : ChannelName, description : ChannelDescription } }
editChannel channelName channelDescription channelId guild =
    updateChannel (\channel -> { channel | name = channelName, description = channelDescription }) channelId guild


editGuildName : GuildName -> { a | name : GuildName } -> { a | name : GuildName }
editGuildName guildName guild =
    { guild | name = guildName }


deleteChannel : Time.Posix -> Id UserId -> Id ChannelId -> BackendGuild -> BackendGuild
deleteChannel time userId channelId guild =
    updateChannel
        (\channel -> { channel | status = ChannelDeleted { deletedAt = time, deletedBy = userId } })
        channelId
        guild


deleteChannelFrontend : Id ChannelId -> FrontendGuild -> FrontendGuild
deleteChannelFrontend channelId guild =
    { guild | channels = SeqDict.remove channelId guild.channels }


memberIsTyping :
    userId
    -> Time.Posix
    -> ThreadRoute
    ->
        { e
            | lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) { f | lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId) }
        }
    ->
        { e
            | lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) { f | lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId) }
        }
memberIsTyping userId time threadRoute channel =
    case threadRoute of
        ViewThread threadMessageIndex ->
            { channel
                | threads =
                    SeqDict.updateIfExists threadMessageIndex (memberIsTypingHelper userId time) channel.threads
            }

        NoThread ->
            memberIsTypingHelper userId time channel


memberIsTypingHelper :
    userId
    -> Time.Posix
    -> { e | lastTypedAt : SeqDict userId (LastTypedAt messageId) }
    -> { e | lastTypedAt : SeqDict userId (LastTypedAt messageId) }
memberIsTypingHelper userId time channel =
    { channel
        | lastTypedAt =
            SeqDict.insert userId { time = time, messageIndex = Nothing } channel.lastTypedAt
    }


memberIsEditTypingBackend :
    userId
    -> Time.Posix
    -> channelId
    -> ThreadRouteWithMessage
    ->
        { d
            | channels :
                SeqDict
                    channelId
                    { e
                        | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
                        , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
                        , threads :
                            SeqDict
                                (Id ChannelMessageId)
                                { f
                                    | messages : IdArray ThreadMessageId (Message ThreadMessageId userId)
                                    , lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId)
                                }
                    }
        }
    ->
        Result
            ()
            { d
                | channels :
                    SeqDict
                        channelId
                        { e
                            | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
                            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
                            , threads :
                                SeqDict
                                    (Id ChannelMessageId)
                                    { f
                                        | messages : IdArray ThreadMessageId (Message ThreadMessageId userId)
                                        , lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId)
                                    }
                        }
            }
memberIsEditTypingBackend userId time channelId threadRoute guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case memberIsEditTypingBackendHelper time userId threadRoute channel of
                Ok channel2 ->
                    Ok { guild | channels = SeqDict.insert channelId channel2 guild.channels }

                _ ->
                    Err ()

        Nothing ->
            Err ()


memberIsEditTypingFrontend :
    userId
    -> Time.Posix
    -> channelId
    -> ThreadRouteWithMessage
    ->
        { d
            | channels :
                SeqDict
                    channelId
                    { e
                        | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
                        , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
                        , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
                    }
        }
    ->
        Result
            ()
            { d
                | channels :
                    SeqDict
                        channelId
                        { e
                            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
                            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
                            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
                        }
            }
memberIsEditTypingFrontend userId time channelId threadRoute guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case memberIsEditTypingFrontendHelper time userId threadRoute channel of
                Ok channel2 ->
                    Ok { guild | channels = SeqDict.insert channelId channel2 guild.channels }

                _ ->
                    Err ()

        Nothing ->
            Err ()


memberIsEditTypingBackendHelper :
    Time.Posix
    -> userId
    -> ThreadRouteWithMessage
    ->
        { a
            | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
            , threads :
                SeqDict
                    (Id ChannelMessageId)
                    { f
                        | messages : IdArray ThreadMessageId (Message ThreadMessageId userId)
                        , lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId)
                    }
        }
    ->
        Result
            ()
            { a
                | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
                , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
                , threads :
                    SeqDict
                        (Id ChannelMessageId)
                        { f
                            | messages : IdArray ThreadMessageId (Message ThreadMessageId userId)
                            , lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId)
                        }
            }
memberIsEditTypingBackendHelper time userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadId messageId ->
            case SeqDict.get threadId channel.threads of
                Just thread ->
                    case memberIsEditTypingBackendHelperNoThread time userId messageId thread of
                        Ok thread2 ->
                            Ok { channel | threads = SeqDict.insert threadId thread2 channel.threads }

                        Err () ->
                            Err ()

                Nothing ->
                    Err ()

        NoThreadWithMessage messageId ->
            memberIsEditTypingBackendHelperNoThread time userId messageId channel


memberIsEditTypingBackendHelperNoThread :
    Time.Posix
    -> userId
    -> Id messageId
    ->
        { c
            | messages : IdArray messageId (Message messageId userId)
            , lastTypedAt : SeqDict userId { time : Time.Posix, messageIndex : Maybe (Id messageId) }
        }
    ->
        Result
            ()
            { c
                | messages : IdArray messageId (Message messageId userId)
                , lastTypedAt : SeqDict userId { time : Time.Posix, messageIndex : Maybe (Id messageId) }
            }
memberIsEditTypingBackendHelperNoThread time userId messageId channel =
    case IdArray.get messageId channel.messages of
        Just (UserTextMessage data) ->
            if data.createdBy == userId then
                { channel
                    | lastTypedAt =
                        SeqDict.insert userId { time = time, messageIndex = Just messageId } channel.lastTypedAt
                }
                    |> Ok

            else
                Err ()

        _ ->
            Err ()


memberIsEditTypingFrontendHelper :
    Time.Posix
    -> userId
    -> ThreadRouteWithMessage
    ->
        { a
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
        }
    ->
        Result
            ()
            { a
                | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
                , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
                , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
            }
memberIsEditTypingFrontendHelper time userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadMessageIndex messageIndex ->
            case SeqDict.get threadMessageIndex channel.threads of
                Just thread ->
                    case memberIsEditTypingFrontendHelperNoThread time userId messageIndex thread of
                        Ok thread2 ->
                            Ok { channel | threads = SeqDict.insert threadMessageIndex thread2 channel.threads }

                        Err () ->
                            Err ()

                Nothing ->
                    Err ()

        NoThreadWithMessage messageIndex ->
            memberIsEditTypingFrontendHelperNoThread time userId messageIndex channel


memberIsEditTypingFrontendHelperNoThread :
    Time.Posix
    -> userId
    -> Id messageId
    -> { a | lastTypedAt : SeqDict userId (LastTypedAt messageId), messages : MessageArray messageId (Message messageId userId) }
    -> Result () { a | lastTypedAt : SeqDict userId (LastTypedAt messageId), messages : MessageArray messageId (Message messageId userId) }
memberIsEditTypingFrontendHelperNoThread time userId messageIndex channel =
    case MessageArray.get messageIndex channel.messages of
        Just (UserTextMessage data) ->
            if data.createdBy == userId then
                { channel
                    | lastTypedAt =
                        SeqDict.insert userId { time = time, messageIndex = Just messageIndex } channel.lastTypedAt
                }
                    |> Ok

            else
                Err ()

        _ ->
            Err ()


addInvite :
    SecretId InviteLinkId
    -> Id UserId
    -> Time.Posix
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
addInvite inviteId userId time guild =
    { guild | invites = SeqDict.insert inviteId { createdBy = userId, createdAt = time } guild.invites }


removeInvite :
    SecretId InviteLinkId
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
removeInvite inviteId guild =
    { guild | invites = SeqDict.remove inviteId guild.invites }


addMemberBackend : Time.Posix -> Id UserId -> BackendGuild -> Result () BackendGuild
addMemberBackend time userId guild =
    case MembersAndOwner.addMember userId { joinedAt = time } guild.membersAndOwner of
        Ok membersAndOwner ->
            { guild
                | membersAndOwner = membersAndOwner
                , channels =
                    SeqDict.updateIfExists
                        (announcementChannel guild)
                        (\channel ->
                            createChannelMessageBackend (Message.userJoined time userId) channel
                                |> Tuple.second
                        )
                        guild.channels
            }
                |> Ok

        Err () ->
            Err ()


addMemberFrontend : Time.Posix -> Id UserId -> FrontendGuild -> Result () FrontendGuild
addMemberFrontend time userId guild =
    case MembersAndOwner.addMember userId { joinedAt = time } guild.membersAndOwner of
        Ok membersAndOwner ->
            { guild
                | membersAndOwner = membersAndOwner
                , channels =
                    SeqDict.updateIfExists
                        (announcementChannel guild)
                        (createChannelMessageFrontend (Message.userJoined time userId))
                        guild.channels
            }
                |> Ok

        Err () ->
            Err ()


announcementChannel : { a | channels : SeqDict (Id ChannelId) b } -> Id ChannelId
announcementChannel guild =
    SeqDict.keys guild.channels |> List.head |> Maybe.withDefault (Id.fromInt 0)


discordAnnouncementChannel :
    { a | channels : SeqDict (Discord.Id Discord.ChannelId) b }
    -> Discord.Id Discord.ChannelId
discordAnnouncementChannel guild =
    SeqDict.keys guild.channels |> List.head |> Maybe.withDefault (Discord.idFromUInt64 (UInt64.fromInt 0))


addReactionEmoji :
    EmojiOrCustomEmoji
    -> userId
    -> ThreadRouteWithMessage
    ->
        { b
            | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
        }
    ->
        { b
            | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
        }
addReactionEmoji emoji userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadId messageId ->
            { channel
                | threads =
                    SeqDict.updateIfExists threadId (addReactionEmojiHelper emoji userId messageId) channel.threads
            }

        NoThreadWithMessage messageId ->
            addReactionEmojiHelper emoji userId messageId channel


addReactionEmojiHelper :
    EmojiOrCustomEmoji
    -> userId
    -> Id messageId
    -> { a | messages : IdArray messageId (Message messageId userId) }
    -> { a | messages : IdArray messageId (Message messageId userId) }
addReactionEmojiHelper emoji userId messageId channel =
    { channel | messages = DmChannel.updateArray messageId (Message.addReactionEmoji userId emoji) channel.messages }


addReactionEmojiFrontend :
    EmojiOrCustomEmoji
    -> userId
    -> ThreadRouteWithMessage
    ->
        { b
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : MessageArray ThreadMessageId (Message ThreadMessageId userId) }
        }
    ->
        { b
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : MessageArray ThreadMessageId (Message ThreadMessageId userId) }
        }
addReactionEmojiFrontend emoji userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadId messageId ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadId
                        (addReactionEmojiFrontendHelper emoji userId messageId)
                        channel.threads
            }

        NoThreadWithMessage messageId ->
            addReactionEmojiFrontendHelper emoji userId messageId channel


addReactionEmojiFrontendHelper :
    EmojiOrCustomEmoji
    -> userId
    -> Id messageId
    -> { a | messages : MessageArray messageId (Message messageId userId) }
    -> { a | messages : MessageArray messageId (Message messageId userId) }
addReactionEmojiFrontendHelper emoji userId messageId channel =
    { channel
        | messages =
            MessageArray.updateIfExists
                messageId
                (Message.addReactionEmoji userId emoji)
                channel.messages
    }


updateChannel :
    (v -> v)
    -> channelId
    -> { a | channels : SeqDict channelId v }
    -> { a | channels : SeqDict channelId v }
updateChannel updateFunc channelId guild =
    { guild | channels = SeqDict.updateIfExists channelId updateFunc guild.channels }


editMessageHelper :
    Time.Posix
    -> userId
    -> Nonempty (RichText userId)
    -> ChangeAttachments
    -> ThreadRouteWithMessage
    ->
        { b
            | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
            , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
            , threads :
                SeqDict
                    (Id ChannelMessageId)
                    { c
                        | messages : IdArray ThreadMessageId (Message ThreadMessageId userId)
                        , lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId)
                    }
        }
    ->
        Result
            ()
            { b
                | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
                , lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId)
                , threads :
                    SeqDict
                        (Id ChannelMessageId)
                        { c
                            | messages : IdArray ThreadMessageId (Message ThreadMessageId userId)
                            , lastTypedAt : SeqDict userId (LastTypedAt ThreadMessageId)
                        }
            }
editMessageHelper time editedBy newContent attachedFiles threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadMessageIndex messageId ->
            case SeqDict.get threadMessageIndex channel.threads of
                Just thread ->
                    case editMessageHelperNoThread time editedBy newContent attachedFiles messageId thread of
                        Ok thread2 ->
                            Ok { channel | threads = SeqDict.insert threadMessageIndex thread2 channel.threads }

                        Err () ->
                            Err ()

                Nothing ->
                    Err ()

        NoThreadWithMessage messageId ->
            editMessageHelperNoThread time editedBy newContent attachedFiles messageId channel


editMessageHelperNoThread :
    Time.Posix
    -> userId
    -> Nonempty (RichText userId)
    -> ChangeAttachments
    -> Id messageId
    -> { b | messages : IdArray messageId (Message messageId userId), lastTypedAt : SeqDict userId (LastTypedAt messageId) }
    -> Result () { b | messages : IdArray messageId (Message messageId userId), lastTypedAt : SeqDict userId (LastTypedAt messageId) }
editMessageHelperNoThread time editedBy newContent attachedFiles messageIndex channel =
    case IdArray.get messageIndex channel.messages of
        Just (UserTextMessage data) ->
            if data.createdBy == editedBy && data.content /= newContent then
                { channel
                    | messages =
                        IdArray.set
                            messageIndex
                            (UserTextMessage (Message.editUserTextMessage time newContent attachedFiles data))
                            channel.messages
                    , lastTypedAt =
                        SeqDict.update
                            editedBy
                            (\maybe ->
                                case maybe of
                                    Just a ->
                                        if a.messageIndex == Just messageIndex then
                                            Nothing

                                        else
                                            maybe

                                    Nothing ->
                                        Nothing
                            )
                            channel.lastTypedAt
                }
                    |> Ok

            else
                Err ()

        _ ->
            Err ()


editMessageFrontendHelper :
    Time.Posix
    -> userId
    -> Nonempty (RichText userId)
    -> ChangeAttachments
    -> ThreadRouteWithMessage
    -> { b | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId), lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId) }
    -> Result () { b | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId), lastTypedAt : SeqDict userId (LastTypedAt ChannelMessageId), threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId) }
editMessageFrontendHelper time editedBy newContent attachedFiles threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadMessageIndex messageId ->
            case SeqDict.get threadMessageIndex channel.threads of
                Just thread ->
                    case editMessageFrontendHelperNoThread time editedBy newContent attachedFiles messageId thread of
                        Ok thread2 ->
                            Ok { channel | threads = SeqDict.insert threadMessageIndex thread2 channel.threads }

                        Err () ->
                            Err ()

                Nothing ->
                    Err ()

        NoThreadWithMessage messageId ->
            editMessageFrontendHelperNoThread time editedBy newContent attachedFiles messageId channel


editMessageFrontendHelperNoThread :
    Time.Posix
    -> userId
    -> Nonempty (RichText userId)
    -> ChangeAttachments
    -> Id messageId
    -> { b | messages : MessageArray messageId (Message messageId userId), lastTypedAt : SeqDict userId (LastTypedAt messageId) }
    -> Result () { b | messages : MessageArray messageId (Message messageId userId), lastTypedAt : SeqDict userId (LastTypedAt messageId) }
editMessageFrontendHelperNoThread time editedBy newContent attachedFiles messageIndex channel =
    case MessageArray.get messageIndex channel.messages of
        Just (UserTextMessage data) ->
            if data.createdBy == editedBy && data.content /= newContent then
                { channel
                    | messages =
                        MessageArray.set
                            messageIndex
                            (UserTextMessage (Message.editUserTextMessage time newContent attachedFiles data))
                            channel.messages
                    , lastTypedAt =
                        SeqDict.update
                            editedBy
                            (\maybe ->
                                case maybe of
                                    Just a ->
                                        if a.messageIndex == Just messageIndex then
                                            Nothing

                                        else
                                            maybe

                                    Nothing ->
                                        Nothing
                            )
                            channel.lastTypedAt
                }
                    |> Ok

            else
                Err ()

        _ ->
            Err ()


removeReactionEmoji :
    EmojiOrCustomEmoji
    -> userId
    -> ThreadRouteWithMessage
    ->
        { b
            | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
        }
    ->
        { b
            | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
        }
removeReactionEmoji emoji userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadMessageIndex messageId ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadMessageIndex
                        (removeReactionEmojiHelper emoji userId messageId)
                        channel.threads
            }

        NoThreadWithMessage messageId ->
            removeReactionEmojiHelper emoji userId messageId channel


removeReactionEmojiHelper :
    EmojiOrCustomEmoji
    -> userId
    -> Id messageId
    -> { a | messages : IdArray messageId (Message messageId userId) }
    -> { a | messages : IdArray messageId (Message messageId userId) }
removeReactionEmojiHelper emoji userId messageId channel =
    { channel | messages = DmChannel.updateArray messageId (Message.removeReactionEmoji userId emoji) channel.messages }


removeReactionEmojiFrontend :
    EmojiOrCustomEmoji
    -> userId
    -> ThreadRouteWithMessage
    ->
        { b
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : MessageArray ThreadMessageId (Message ThreadMessageId userId) }
        }
    ->
        { b
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : MessageArray ThreadMessageId (Message ThreadMessageId userId) }
        }
removeReactionEmojiFrontend emoji userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadId messageId ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadId
                        (removeReactionEmojiFrontendHelper emoji userId messageId)
                        channel.threads
            }

        NoThreadWithMessage messageId ->
            removeReactionEmojiFrontendHelper emoji userId messageId channel


removeReactionEmojiFrontendHelper :
    EmojiOrCustomEmoji
    -> userId
    -> Id messageId
    -> { a | messages : MessageArray messageId (Message messageId userId) }
    -> { a | messages : MessageArray messageId (Message messageId userId) }
removeReactionEmojiFrontendHelper emoji userId messageId channel =
    { channel
        | messages =
            MessageArray.updateIfExists
                messageId
                (Message.removeReactionEmoji userId emoji)
                channel.messages
    }


markAllChannelsAndThreadsAsViewedBackend : Id GuildId -> BackendGuild -> BackendUser -> BackendUser
markAllChannelsAndThreadsAsViewedBackend guildId guild user =
    { user
        | lastViewedMessage =
            SeqDict.foldl
                (\channelId channel state ->
                    SeqDict.insert
                        (GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId }))
                        (DmChannel.latestMessageId channel)
                        state
                )
                user.lastViewedMessage
                guild.channels
        , lastViewedThreadMessage =
            SeqDict.foldl
                (\channelId channel state ->
                    SeqDict.foldl
                        (\threadId thread state2 ->
                            SeqDict.insert
                                ( GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId }), threadId )
                                (DmChannel.latestThreadMessageId thread)
                                state2
                        )
                        state
                        channel.threads
                )
                user.lastViewedThreadMessage
                guild.channels
    }


markAllChannelsAndThreadsAsViewedFrontend : Id GuildId -> FrontendGuild -> FrontendCurrentUser -> FrontendCurrentUser
markAllChannelsAndThreadsAsViewedFrontend guildId guild user =
    { user
        | lastViewedMessage =
            SeqDict.foldl
                (\channelId channel state ->
                    SeqDict.insert
                        (GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId }))
                        (DmChannel.latestFrontendMessageId channel)
                        state
                )
                user.lastViewedMessage
                guild.channels
        , lastViewedThreadMessage =
            SeqDict.foldl
                (\channelId channel state ->
                    SeqDict.foldl
                        (\threadId thread state2 ->
                            SeqDict.insert
                                ( GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId }), threadId )
                                (DmChannel.latestFrontendThreadMessageId thread)
                                state2
                        )
                        state
                        channel.threads
                )
                user.lastViewedThreadMessage
                guild.channels
    }


{-| Discord content that a user has never had access to before should start out read.
Otherwise linking a Discord account or joining a Discord guild floods the app with unread
markers for messages that were written long before the user could see them.
-}
markAllDiscordChannelsAndThreadsAsViewedBackend :
    Discord.Id Discord.UserId
    -> Discord.Id Discord.GuildId
    -> DiscordBackendGuild
    -> BackendUser
    -> BackendUser
markAllDiscordChannelsAndThreadsAsViewedBackend currentUserId guildId guild user =
    SeqDict.foldl
        (\channelId channel user2 ->
            if canViewDiscordChannel guildId channel guild currentUserId then
                let
                    guildOrDmId : AnyGuildOrDmId
                    guildOrDmId =
                        DiscordGuildOrDmId
                            (DiscordGuildOrDmId_Guild
                                { guildId = guildId, channelId = channelId, currentUserId = currentUserId }
                            )
                in
                { user2
                    | lastViewedMessage =
                        SeqDict.insert guildOrDmId (DmChannel.latestMessageId channel) user2.lastViewedMessage
                    , lastViewedThreadMessage =
                        SeqDict.foldl
                            (\threadId thread state ->
                                SeqDict.insert
                                    ( guildOrDmId, threadId )
                                    (DmChannel.latestThreadMessageId thread)
                                    state
                            )
                            user2.lastViewedThreadMessage
                            channel.threads
                }

            else
                user2
        )
        user
        guild.channels


markAllDiscordChannelsAndThreadsAsViewedFrontend :
    Discord.Id Discord.UserId
    -> Discord.Id Discord.GuildId
    -> DiscordFrontendGuild
    -> FrontendCurrentUser
    -> FrontendCurrentUser
markAllDiscordChannelsAndThreadsAsViewedFrontend currentUserId guildId guild user =
    SeqDict.foldl
        (\channelId channel user2 ->
            let
                guildOrDmId : AnyGuildOrDmId
                guildOrDmId =
                    DiscordGuildOrDmId
                        (DiscordGuildOrDmId_Guild
                            { guildId = guildId, channelId = channelId, currentUserId = currentUserId }
                        )
            in
            { user2
                | lastViewedMessage =
                    SeqDict.insert guildOrDmId (DmChannel.latestFrontendMessageId channel) user2.lastViewedMessage
                , lastViewedThreadMessage =
                    SeqDict.foldl
                        (\threadId thread state ->
                            SeqDict.insert
                                ( guildOrDmId, threadId )
                                (DmChannel.latestFrontendThreadMessageId thread)
                                state
                        )
                        user2.lastViewedThreadMessage
                        channel.threads
            }
        )
        user
        guild.channels


markDiscordDmAsViewedBackend :
    Discord.Id Discord.UserId
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordDmChannel
    -> BackendUser
    -> BackendUser
markDiscordDmAsViewedBackend currentUserId channelId dmChannel user =
    { user
        | lastViewedMessage =
            SeqDict.insert
                (DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId = currentUserId, channelId = channelId }))
                (DmChannel.latestMessageId dmChannel)
                user.lastViewedMessage
    }


markDiscordDmAsViewedFrontend :
    Discord.Id Discord.UserId
    -> Discord.Id Discord.PrivateChannelId
    -> DiscordFrontendDmChannel
    -> FrontendCurrentUser
    -> FrontendCurrentUser
markDiscordDmAsViewedFrontend currentUserId channelId dmChannel user =
    { user
        | lastViewedMessage =
            SeqDict.insert
                (DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId = currentUserId, channelId = channelId }))
                (DmChannel.latestFrontendMessageId dmChannel)
                user.lastViewedMessage
    }


deleteMessageBackend :
    userId
    -> channelId
    -> ThreadRouteWithMessage
    ->
        { a
            | channels :
                SeqDict
                    channelId
                    { c
                        | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
                        , threads : SeqDict (Id ChannelMessageId) { thread | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
                    }
        }
    ->
        Result
            ()
            ( { a
                | channels :
                    SeqDict
                        channelId
                        { c
                            | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
                            , threads : SeqDict (Id ChannelMessageId) { thread | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
                        }
              }
            , { c
                | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
                , threads : SeqDict (Id ChannelMessageId) { thread | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
              }
            )
deleteMessageBackend userId channelId threadRoute guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case deleteMessageBackendHelper userId threadRoute channel of
                Ok channel2 ->
                    Ok ( { guild | channels = SeqDict.insert channelId channel2 guild.channels }, channel2 )

                _ ->
                    Err ()

        Nothing ->
            Err ()


deleteMessageBackendHelper :
    userId
    -> ThreadRouteWithMessage
    ->
        { a
            | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { thread | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
        }
    ->
        Result
            ()
            { a
                | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
                , threads : SeqDict (Id ChannelMessageId) { thread | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
            }
deleteMessageBackendHelper userId threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadId messageId ->
            case SeqDict.get threadId channel.threads of
                Just thread ->
                    case deleteMessageBackendHelperNoThread userId messageId thread of
                        Ok thread2 ->
                            { channel
                                | threads =
                                    SeqDict.insert
                                        threadId
                                        thread2
                                        channel.threads
                            }
                                |> Ok

                        Err () ->
                            Err ()

                Nothing ->
                    Err ()

        NoThreadWithMessage messageId ->
            deleteMessageBackendHelperNoThread userId messageId channel


deleteMessageBackendHelperNoThread :
    userId
    -> Id messageId
    -> { b | messages : IdArray messageId (Message messageId userId) }
    -> Result () { b | messages : IdArray messageId (Message messageId userId) }
deleteMessageBackendHelperNoThread userId messageId channel =
    case IdArray.get messageId channel.messages of
        Just (UserTextMessage message) ->
            if message.createdBy == userId then
                { channel | messages = IdArray.set messageId (DeletedMessage message.createdAt) channel.messages }
                    |> Ok

            else
                Err ()

        _ ->
            Err ()


deleteMessageFrontend :
    channelId
    -> ThreadRouteWithMessage
    ->
        { a
            | channels :
                SeqDict
                    channelId
                    { c
                        | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
                        , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
                    }
        }
    ->
        { a
            | channels :
                SeqDict
                    channelId
                    { c
                        | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
                        , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
                    }
        }
deleteMessageFrontend channelId threadRoute guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            { guild
                | channels =
                    SeqDict.insert
                        channelId
                        (deleteMessageFrontendHelper threadRoute channel)
                        guild.channels
            }

        Nothing ->
            guild


deleteMessageFrontendHelper :
    ThreadRouteWithMessage
    ->
        { a
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
        }
    ->
        { a
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
        }
deleteMessageFrontendHelper threadRoute channel =
    case threadRoute of
        ViewThreadWithMessage threadId messageId ->
            case SeqDict.get threadId channel.threads of
                Just thread ->
                    case MessageArray.get messageId thread.messages of
                        Just (UserTextMessage message) ->
                            { channel
                                | threads =
                                    SeqDict.insert
                                        threadId
                                        { thread
                                            | messages =
                                                MessageArray.set
                                                    messageId
                                                    (DeletedMessage message.createdAt)
                                                    thread.messages
                                        }
                                        channel.threads
                            }

                        _ ->
                            channel

                Nothing ->
                    channel

        NoThreadWithMessage messageId ->
            deleteMessageFrontendNoThread messageId channel


{-| Deleting a post in a guild forum deletes the post's title along with everything written
in it. Deleting the message a thread in a normal channel hangs off of leaves the thread
alone instead, which is why this isn't the same as deleting the title on its own.
-}
deleteForumPostFrontend :
    channelId
    -> Id ChannelMessageId
    ->
        { a
            | channels :
                SeqDict
                    channelId
                    { c
                        | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
                        , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
                    }
        }
    ->
        { a
            | channels :
                SeqDict
                    channelId
                    { c
                        | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
                        , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
                    }
        }
deleteForumPostFrontend channelId messageId guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            let
                channel2 :
                    { c
                        | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
                        , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
                    }
                channel2 =
                    deleteMessageFrontendNoThread messageId channel
            in
            { guild
                | channels =
                    SeqDict.insert
                        channelId
                        { channel2 | threads = SeqDict.remove messageId channel2.threads }
                        guild.channels
            }

        Nothing ->
            guild


deleteMessageFrontendNoThread :
    Id messageId
    -> { a | messages : MessageArray messageId (Message messageId userId) }
    -> { a | messages : MessageArray messageId (Message messageId userId) }
deleteMessageFrontendNoThread messageId channel =
    case MessageArray.get messageId channel.messages of
        Just (UserTextMessage message) ->
            { channel
                | messages =
                    MessageArray.set
                        messageId
                        (DeletedMessage message.createdAt)
                        channel.messages
            }

        _ ->
            channel


getGuildAndChannel : Viewing_ChannelId -> LocalState -> Maybe ( FrontendGuild, FrontendChannel )
getGuildAndChannel { guildId, channelId } local =
    case SeqDict.get guildId local.guilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    Just ( guild, channel )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


getDiscordGuildAndChannel :
    Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    ->
        { a
            | discordGuilds :
                SeqDict
                    (Discord.Id Discord.GuildId)
                    { b | channels : SeqDict (Discord.Id Discord.ChannelId) channel }
        }
    -> Maybe ( { b | channels : SeqDict (Discord.Id Discord.ChannelId) channel }, channel )
getDiscordGuildAndChannel guildId channelId local =
    case SeqDict.get guildId local.discordGuilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    Just ( guild, channel )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


{-| True when the reader had seen every message in a conversation and the one that just
arrived is the only one they haven't. `Nothing` means they have never opened it, so the
message sitting at index 0 is the only unseen one.
-}
onlyNewMessageIsUnread : Maybe (Id messageId) -> Id messageId -> Bool
onlyNewMessageIsUnread maybeLastViewed newMessageId =
    Id.toInt (Maybe.withDefault (Id.fromInt -1) maybeLastViewed) + 1 == Id.toInt newMessageId


{-| A message arriving in a conversation someone is looking at shouldn't leave them with
something unread, so their last viewed message moves onto it. Someone who was behind keeps
where they were, which is what stops a message they marked as unread from quietly being
marked as read again.
-}
incrementLastViewedMessageBackend : AnyGuildOrDmId -> ThreadRouteWithMessage -> BackendUser -> BackendUser
incrementLastViewedMessageBackend guildOrDmId threadRoute user =
    if hasCaughtUp guildOrDmId threadRoute user then
        User.setLastViewedMessage guildOrDmId threadRoute user

    else
        user


{-| The same as `incrementLastViewedMessageBackend`, plus the unread divider of the
conversation on screen, which moves onto the new message so that nothing appears unread
while the reader is still sitting in it.
-}
incrementLastViewedMessageFrontend :
    AnyGuildOrDmId
    -> ThreadRouteWithMessage
    -> ( UserSession.Viewing, BackendUser )
    -> ( UserSession.Viewing, BackendUser )
incrementLastViewedMessageFrontend guildOrDmId threadRoute ( viewing, user ) =
    if hasCaughtUp guildOrDmId threadRoute user then
        ( case threadRoute of
            NoThreadWithMessage messageId ->
                UserSession.setPreviouslyLastViewedChannelMessage messageId viewing

            ViewThreadWithMessage _ messageId ->
                UserSession.setPreviouslyLastViewedThreadMessage messageId viewing
        , User.setLastViewedMessage guildOrDmId threadRoute user
        )

    else
        ( viewing, user )


{-| A message the user made themselves is read the moment it exists, whether that's a
message they wrote or the card left behind by a call or a game they started. The unread
divider follows it down only when they had nothing unread above it, so that making one
doesn't quietly clear a divider they still have messages to read under.
-}
ownMessageIsReadFrontend :
    AnyGuildOrDmId
    -> ThreadRouteWithMessage
    -> ( UserSession.Viewing, BackendUser )
    -> ( UserSession.Viewing, BackendUser )
ownMessageIsReadFrontend guildOrDmId threadRoute ( viewing, user ) =
    ( if hasCaughtUp guildOrDmId threadRoute user then
        case threadRoute of
            NoThreadWithMessage messageId ->
                UserSession.setPreviouslyLastViewedChannelMessage messageId viewing

            ViewThreadWithMessage _ messageId ->
                UserSession.setPreviouslyLastViewedThreadMessage messageId viewing

      else
        viewing
    , User.setLastViewedMessage guildOrDmId threadRoute user
    )


hasCaughtUp : AnyGuildOrDmId -> ThreadRouteWithMessage -> BackendUser -> Bool
hasCaughtUp guildOrDmId threadRoute user =
    case threadRoute of
        NoThreadWithMessage messageId ->
            onlyNewMessageIsUnread (SeqDict.get guildOrDmId user.lastViewedMessage) messageId

        ViewThreadWithMessage threadId messageId ->
            onlyNewMessageIsUnread
                (SeqDict.get ( guildOrDmId, threadId ) user.lastViewedThreadMessage)
                messageId


addEmbedBackend :
    Id messageId
    -> ( Url, Result e EmbedData )
    -> { a | messages : IdArray messageId (Message messageId userId) }
    -> { a | messages : IdArray messageId (Message messageId userId) }
addEmbedBackend messageId embed channel =
    { channel | messages = DmChannel.updateArray messageId (Message.addEmbed embed) channel.messages }


addEmbedFrontend :
    Id messageId
    -> ( Url, Result e EmbedData )
    -> { a | messages : MessageArray messageId (Message messageId userId) }
    -> { a | messages : MessageArray messageId (Message messageId userId) }
addEmbedFrontend messageId embed channel =
    { channel
        | messages =
            MessageArray.updateIfExists messageId
                (Message.addEmbed embed)
                channel.messages
    }


usersMentionedOrRepliedToBackend :
    ThreadRouteWithMaybeMessage
    -> Nonempty (RichText userId)
    -> List userId
    ->
        { a
            | threads : SeqDict (Id ChannelMessageId) { b | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
            , messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
        }
    -> SeqSet userId
usersMentionedOrRepliedToBackend threadRouteWithRepliedTo content members channel =
    let
        userIds : SeqSet userId
        userIds =
            (case threadRouteWithRepliedTo of
                ViewThreadWithMaybeMessage threadId maybeRepliedTo ->
                    (case SeqDict.get threadId channel.threads of
                        Just thread ->
                            repliedToUserId maybeRepliedTo thread |> Maybe.Extra.toList

                        Nothing ->
                            []
                    )
                        ++ (case IdArray.get threadId channel.messages of
                                Just (UserTextMessage data) ->
                                    [ data.createdBy ]

                                Just (UserJoinedMessage _ userJoined _ _) ->
                                    [ userJoined ]

                                Just (DeletedMessage _) ->
                                    []

                                Just (CallStarted { startedBy }) ->
                                    [ startedBy ]

                                Just (GameStarted { startedBy }) ->
                                    [ startedBy ]

                                Nothing ->
                                    []
                           )

                NoThreadWithMaybeMessage maybeRepliedTo ->
                    repliedToUserId maybeRepliedTo channel |> Maybe.Extra.toList
            )
                |> List.foldl SeqSet.insert (RichText.mentionsUser content)
    in
    List.foldl
        (\userId validUserIds ->
            if SeqSet.member userId userIds then
                SeqSet.insert userId validUserIds

            else
                validUserIds
        )
        SeqSet.empty
        members


usersMentionedOrRepliedToFrontend :
    ThreadRouteWithMaybeMessage
    -> Nonempty (RichText userId)
    ->
        { a
            | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId)
        }
    -> SeqSet userId
usersMentionedOrRepliedToFrontend threadRouteWithRepliedTo content channel =
    (case threadRouteWithRepliedTo of
        ViewThreadWithMaybeMessage threadId maybeRepliedTo ->
            (case SeqDict.get threadId channel.threads of
                Just thread ->
                    repliedToUserIdFrontend maybeRepliedTo thread |> Maybe.Extra.toList

                Nothing ->
                    []
            )
                ++ (case MessageArray.get threadId channel.messages of
                        Just message ->
                            case message of
                                UserTextMessage data ->
                                    [ data.createdBy ]

                                UserJoinedMessage _ userJoined _ _ ->
                                    [ userJoined ]

                                DeletedMessage _ ->
                                    []

                                CallStarted { startedBy } ->
                                    [ startedBy ]

                                GameStarted { startedBy } ->
                                    [ startedBy ]

                        _ ->
                            []
                   )

        NoThreadWithMaybeMessage maybeRepliedTo ->
            repliedToUserIdFrontend maybeRepliedTo channel |> Maybe.Extra.toList
    )
        |> List.foldl SeqSet.insert (RichText.mentionsUser content)


repliedToUserId : Maybe (Id messageId) -> { a | messages : IdArray messageId (Message messageId userId) } -> Maybe userId
repliedToUserId maybeRepliedTo channel =
    case maybeRepliedTo of
        Just repliedTo ->
            case IdArray.get repliedTo channel.messages of
                Just message ->
                    case message of
                        UserTextMessage repliedToData ->
                            Just repliedToData.createdBy

                        UserJoinedMessage _ joinedUser _ _ ->
                            Just joinedUser

                        DeletedMessage _ ->
                            Nothing

                        CallStarted { startedBy } ->
                            Just startedBy

                        GameStarted { startedBy } ->
                            Just startedBy

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


repliedToUserIdFrontend : Maybe (Id messageId) -> { a | messages : MessageArray messageId (Message messageId userId) } -> Maybe userId
repliedToUserIdFrontend maybeRepliedTo channel =
    case maybeRepliedTo of
        Just repliedTo ->
            case MessageArray.get repliedTo channel.messages of
                Just message ->
                    case message of
                        UserTextMessage repliedToData ->
                            Just repliedToData.createdBy

                        UserJoinedMessage _ joinedUser _ _ ->
                            Just joinedUser

                        DeletedMessage _ ->
                            Nothing

                        CallStarted { startedBy } ->
                            Just startedBy

                        GameStarted { startedBy } ->
                            Just startedBy

                _ ->
                    Nothing

        Nothing ->
            Nothing


{-| False if Discord's spam bot heuristics is likely to get triggered by sending a message
-}
canSendDiscordMessage : LocalState -> DiscordGuildOrDmId -> Result String ()
canSendDiscordMessage local guildOrDmId =
    case guildOrDmId of
        DiscordGuildOrDmId_Guild _ ->
            Ok ()

        DiscordGuildOrDmId_Dm data ->
            case LinkedAndOtherDiscordUsers.getLinkedUser data.currentUserId local.localUser.discordUsers of
                Just linkedUser ->
                    if linkedUser.needsAuthAgain then
                        Err "Please link your Discord account again"

                    else
                        case SeqDict.get data.channelId local.discordDmChannels of
                            Just channel ->
                                if sentEnoughDiscordDmMessages data.currentUserId channel then
                                    Ok ()

                                else
                                    Err "Send at least 4 messages using Discord first"

                            Nothing ->
                                Err "Channel not found"

                Nothing ->
                    Err "This Discord user isn't linked to your account"


{-| Discord's spam bot heuristics are likely to trigger if we send messages on behalf of a
linked account in a DM channel it has barely used, so we require a few messages to have
been sent with Discord itself first.
-}
sentEnoughDiscordDmMessages :
    Discord.Id Discord.UserId
    -> { a | members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int } }
    -> Bool
sentEnoughDiscordDmMessages currentUserId channel =
    case NonemptyDict.get currentUserId channel.members of
        Just member ->
            member.messagesSent >= 4

        Nothing ->
            False


{-| Where the last viewed message of a channel sat before the user opened it. Entering a
channel marks it as read, so this is what keeps its unread messages visible while the user is
still looking at them.

A channel with no entry has never been opened, so the reader has seen nothing in it and the
divider belongs above everything rather than nowhere.

-}
previouslyLastViewedMessage : AnyGuildOrDmId -> LocalState -> PreviouslyLastViewedMessage ChannelMessageId
previouslyLastViewedMessage guildOrDmId local =
    SeqDict.get guildOrDmId local.localUser.user.lastViewedMessage
        |> Maybe.withDefault (Id.fromInt -1)
        |> PreviouslyLastViewedMessage


previouslyLastViewedThreadMessage :
    AnyGuildOrDmId
    -> Id ChannelMessageId
    -> LocalState
    -> PreviouslyLastViewedMessage ThreadMessageId
previouslyLastViewedThreadMessage guildOrDmId threadId local =
    SeqDict.get ( guildOrDmId, threadId ) local.localUser.user.lastViewedThreadMessage
        |> Maybe.withDefault (Id.fromInt -1)
        |> PreviouslyLastViewedMessage


routeToViewing : Bool -> Route -> LocalState -> SetViewing
routeToViewing isMobile route local =
    case route of
        HomePageRoute ->
            -- The home page shows the unread overview when no DM is selected
            ViewOverview EmptyPlaceholder

        AdminRoute _ ->
            StopViewingChannel

        NewGuildRoute ->
            StopViewingChannel

        GuildRoute guildId channelRoute channelsVisible ->
            -- Only mobile puts the channel list over the conversation, so only mobile can
            -- leave the reader looking at something other than the channel the route names
            if SeqDict.member guildId local.guilds && not (isMobile && channelsVisible == ChannelsVisibleOnMobile) then
                case channelRoute of
                    ChannelRoute channelId threadRoute tab ->
                        let
                            id =
                                { guildId = guildId, channelId = channelId }
                        in
                        case threadRoute of
                            NoThreadWithFriends _ _ ->
                                ViewChannel
                                    { id = id
                                    , channelHeaderTab = tab
                                    , previouslyLastViewedMessage =
                                        previouslyLastViewedMessage (GuildOrDmId (GuildOrDmId_Guild id)) local
                                    }
                                    EmptyPlaceholder

                            ViewThreadWithFriends threadId _ _ ->
                                ViewChannelThread
                                    { id = { guildId = guildId, channelId = channelId, threadId = threadId }
                                    , previouslyLastViewedMessage =
                                        previouslyLastViewedThreadMessage
                                            (GuildOrDmId (GuildOrDmId_Guild id))
                                            threadId
                                            local
                                    }
                                    EmptyPlaceholder

                    NewChannelRoute ->
                        StopViewingChannel

                    GuildSettingsRoute ->
                        StopViewingChannel

                    JoinRoute _ ->
                        StopViewingChannel

            else
                StopViewingChannel

        DiscordGuildRoute { currentDiscordUserId, guildId, channelRoute, channelsVisible } ->
            if SeqDict.member guildId local.discordGuilds && not (isMobile && channelsVisible == ChannelsVisibleOnMobile) then
                case channelRoute of
                    DiscordChannel_ChannelRoute channelId threadRoute _ ->
                        let
                            id : Viewing_DiscordChannelId
                            id =
                                { guildId = guildId
                                , channelId = channelId
                                , currentUserId = currentDiscordUserId
                                }
                        in
                        case threadRoute of
                            NoThreadWithFriends _ _ ->
                                ViewDiscordChannel
                                    { id = id
                                    , previouslyLastViewedMessage =
                                        previouslyLastViewedMessage
                                            (DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id))
                                            local
                                    }
                                    EmptyPlaceholder

                            ViewThreadWithFriends threadId _ _ ->
                                ViewDiscordChannelThread
                                    { id =
                                        { guildId = guildId
                                        , channelId = channelId
                                        , currentUserId = currentDiscordUserId
                                        , threadId = threadId
                                        }
                                    , previouslyLastViewedMessage =
                                        previouslyLastViewedThreadMessage
                                            (DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id))
                                            threadId
                                            local
                                    }
                                    EmptyPlaceholder

                    DiscordChannel_NewChannelRoute ->
                        StopViewingChannel

                    DiscordChannel_GuildSettingsRoute ->
                        StopViewingChannel

            else
                StopViewingChannel

        DmRoute { channelId, threadRoute, tab, channelsVisible } ->
            case DmChannelId.otherUserId local.localUser.session.userId channelId of
                Just otherUserId ->
                    -- We don't check `SeqDict.members otherUserId local.dmChannels` since it might not have any messages in it yet but still be valid
                    if isMobile && channelsVisible == ChannelsVisibleOnMobile then
                        StopViewingChannel

                    else
                        let
                            id =
                                { otherUserId = otherUserId }
                        in
                        case threadRoute of
                            NoThreadWithFriends _ _ ->
                                ViewDm
                                    { id = id
                                    , channelHeaderTab = tab
                                    , previouslyLastViewedMessage =
                                        previouslyLastViewedMessage (GuildOrDmId (GuildOrDmId_Dm id)) local
                                    }
                                    EmptyPlaceholder

                            ViewThreadWithFriends threadId _ _ ->
                                ViewDmThread
                                    { id = { otherUserId = otherUserId, threadId = threadId }
                                    , previouslyLastViewedMessage =
                                        previouslyLastViewedThreadMessage
                                            (GuildOrDmId (GuildOrDmId_Dm id))
                                            threadId
                                            local
                                    }
                                    EmptyPlaceholder

                Nothing ->
                    StopViewingChannel

        DiscordDmRoute data ->
            if SeqDict.member data.channelId local.discordDmChannels && not (isMobile && data.channelsVisible == ChannelsVisibleOnMobile) then
                ViewDiscordDm
                    { id = { currentUserId = data.currentDiscordUserId, channelId = data.channelId }
                    , previouslyLastViewedMessage =
                        previouslyLastViewedMessage
                            (DiscordGuildOrDmId
                                (DiscordGuildOrDmId_Dm
                                    { currentUserId = data.currentDiscordUserId, channelId = data.channelId }
                                )
                            )
                            local
                    }
                    EmptyPlaceholder

            else
                StopViewingChannel

        AiChatRoute ->
            StopViewingChannel

        SlackOAuthRedirect _ ->
            StopViewingChannel

        TextEditorRoute ->
            StopViewingChannel

        LinkDiscord _ ->
            StopViewingChannel

        PublicGoMatchRoute _ ->
            StopViewingChannel

        PostFinderRoute _ ->
            StopViewingChannel


guildOrDmIdToMessage :
    GuildOrDmId
    -> ThreadRouteWithMessage
    -> LocalState
    -> Maybe ( UserTextMessageDataNoReply (Id UserId), ThreadRouteWithMaybeMessage )
guildOrDmIdToMessage guildOrDmId threadRoute local =
    let
        helper :
            { a | messages : MessageArray ChannelMessageId (Message ChannelMessageId (Id UserId)), threads : SeqDict (Id ChannelMessageId) FrontendThread }
            -> Maybe ( UserTextMessageDataNoReply (Id UserId), ThreadRouteWithMaybeMessage )
        helper channel =
            case threadRoute of
                ViewThreadWithMessage threadId messageId ->
                    case
                        SeqDict.get threadId channel.threads
                            |> Maybe.withDefault Thread.frontendInit
                            |> .messages
                            |> MessageArray.get messageId
                    of
                        Just (UserTextMessage data) ->
                            ( { createdAt = data.createdAt
                              , createdBy = data.createdBy
                              , content = data.content
                              , reactions = data.reactions
                              , editedAt = data.editedAt
                              , attachedFiles = data.attachedFiles
                              }
                            , ViewThreadWithMaybeMessage threadId data.repliedTo
                            )
                                |> Just

                        _ ->
                            Nothing

                NoThreadWithMessage messageId ->
                    case MessageArray.get messageId channel.messages of
                        Just (UserTextMessage data) ->
                            ( { createdAt = data.createdAt
                              , createdBy = data.createdBy
                              , content = data.content
                              , reactions = data.reactions
                              , editedAt = data.editedAt
                              , attachedFiles = data.attachedFiles
                              }
                            , NoThreadWithMaybeMessage data.repliedTo
                            )
                                |> Just

                        _ ->
                            Nothing
    in
    case guildOrDmId of
        GuildOrDmId_Guild id ->
            case getGuildAndChannel id local of
                Just ( _, channel ) ->
                    helper channel

                Nothing ->
                    Nothing

        GuildOrDmId_Dm { otherUserId } ->
            case SeqDict.get otherUserId local.dmChannels of
                Just dmChannel ->
                    helper dmChannel

                Nothing ->
                    Nothing


discordGuildOrDmIdToMessage :
    DiscordGuildOrDmId
    -> ThreadRouteWithMessage
    -> LocalState
    -> Maybe ( UserTextMessageDataNoReply (Discord.Id Discord.UserId), ThreadRouteWithMaybeMessage )
discordGuildOrDmIdToMessage guildOrDmId threadRoute local =
    let
        helper messageId channel =
            case MessageArray.get messageId channel.messages of
                Just (UserTextMessage data) ->
                    ( { createdAt = data.createdAt
                      , createdBy = data.createdBy
                      , content = data.content
                      , reactions = data.reactions
                      , editedAt = data.editedAt
                      , attachedFiles = data.attachedFiles
                      }
                    , NoThreadWithMaybeMessage data.repliedTo
                    )
                        |> Just

                _ ->
                    Nothing
    in
    case guildOrDmId of
        DiscordGuildOrDmId_Guild id ->
            case getDiscordGuildAndChannel id.guildId id.channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThreadWithMessage threadId messageId ->
                            case
                                SeqDict.get threadId channel.threads
                                    |> Maybe.withDefault Thread.discordFrontendInit
                                    |> .messages
                                    |> MessageArray.get messageId
                            of
                                Just (UserTextMessage data) ->
                                    ( { createdAt = data.createdAt
                                      , createdBy = data.createdBy
                                      , content = data.content
                                      , reactions = data.reactions
                                      , editedAt = data.editedAt
                                      , attachedFiles = data.attachedFiles
                                      }
                                    , ViewThreadWithMaybeMessage threadId data.repliedTo
                                    )
                                        |> Just

                                _ ->
                                    Nothing

                        NoThreadWithMessage messageId ->
                            helper messageId channel

                Nothing ->
                    Nothing

        DiscordGuildOrDmId_Dm data ->
            case ( SeqDict.get data.channelId local.discordDmChannels, threadRoute ) of
                ( Just channel, NoThreadWithMessage messageId ) ->
                    helper messageId channel

                _ ->
                    Nothing


{-| The most recently sent messages in a channel or thread, oldest first.
`count` is how many of the newest message indices to look at. Messages within
that range which aren't loaded are left out.
-}
guildOrDmIdToLatestMessages :
    Int
    -> ( GuildOrDmId, ThreadRoute )
    -> LocalState
    -> Maybe (List ( Int, MessageNoReply (Id UserId) ))
guildOrDmIdToLatestMessages count ( guildOrDmId, threadRoute ) local =
    let
        helper channel =
            case threadRoute of
                ViewThread threadMessageIndex ->
                    SeqDict.get threadMessageIndex channel.threads
                        |> Maybe.withDefault Thread.frontendInit
                        |> latestMessagesHelper count
                        |> Just

                NoThread ->
                    latestMessagesHelper count channel |> Just
    in
    case guildOrDmId of
        GuildOrDmId_Guild id ->
            case getGuildAndChannel id local of
                Just ( _, channel ) ->
                    helper channel

                Nothing ->
                    Nothing

        GuildOrDmId_Dm { otherUserId } ->
            case SeqDict.get otherUserId local.dmChannels of
                Just dmChannel ->
                    helper dmChannel

                Nothing ->
                    Nothing


latestMessagesHelper :
    Int
    -> { a | messages : MessageArray messageId (Message messageId userId) }
    -> List ( Int, MessageNoReply userId )
latestMessagesHelper count channel =
    let
        messageCount : Int
        messageCount =
            MessageArray.length channel.messages
    in
    MessageArray.slice
        (messageCount - count |> max 0 |> Id.fromInt)
        (Id.fromInt messageCount)
        channel.messages
        |> MessageArray.toList
        |> List.map (\( messageId, message ) -> ( Id.toInt messageId, toMessageNoReply message ))


toMessageNoReply : Message messageId userId -> MessageNoReply userId
toMessageNoReply message =
    case message of
        UserTextMessage data ->
            { createdAt = data.createdAt
            , createdBy = data.createdBy
            , content = data.content
            , reactions = data.reactions
            , editedAt = data.editedAt
            , attachedFiles = data.attachedFiles
            }
                |> UserTextMessage_NoReply

        UserJoinedMessage time userId reactions _ ->
            UserJoinedMessage_NoReply time userId reactions

        DeletedMessage time ->
            DeletedMessage_NoReply time

        CallStarted { startedAt, startedBy, reactions } ->
            CallStarted_NoReply startedAt startedBy reactions

        GameStarted { startedAt, reactions } ->
            GoMatchStarted_NoReply startedAt reactions


discordGuildOrDmIdToLatestMessages :
    Int
    -> DiscordGuildOrDmId
    -> ThreadRoute
    -> LocalState
    -> Maybe (List ( Int, MessageNoReply (Discord.Id Discord.UserId) ))
discordGuildOrDmIdToLatestMessages count guildOrDmId threadRoute local =
    let
        helper2 :
            { a | messages : MessageArray messageId (Message messageId userId) }
            -> Maybe (List ( Int, MessageNoReply userId ))
        helper2 channel =
            latestMessagesHelper count channel |> Just
    in
    case guildOrDmId of
        DiscordGuildOrDmId_Guild id ->
            case getDiscordGuildAndChannel id.guildId id.channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            case SeqDict.get threadMessageIndex channel.threads of
                                Just thread ->
                                    helper2 thread

                                Nothing ->
                                    Nothing

                        NoThread ->
                            helper2 channel

                Nothing ->
                    Nothing

        DiscordGuildOrDmId_Dm id ->
            case SeqDict.get id.channelId local.discordDmChannels of
                Just dmChannel ->
                    helper2 dmChannel

                Nothing ->
                    Nothing


guildOrDmIdToMessagesCount : AnyGuildOrDmId -> ThreadRoute -> LocalState -> Maybe Int
guildOrDmIdToMessagesCount guildOrDmId threadRoute local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild id) ->
            case getGuildAndChannel id local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            SeqDict.get threadMessageIndex channel.threads
                                |> Maybe.withDefault Thread.frontendInit
                                |> .messages
                                |> MessageArray.length
                                |> Just

                        NoThread ->
                            Just (MessageArray.length channel.messages)

                Nothing ->
                    Nothing

        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
            case SeqDict.get otherUserId local.dmChannels of
                Just dmChannel ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            SeqDict.get threadMessageIndex dmChannel.threads
                                |> Maybe.withDefault Thread.frontendInit
                                |> .messages
                                |> MessageArray.length
                                |> Just

                        NoThread ->
                            Just (MessageArray.length dmChannel.messages)

                Nothing ->
                    Nothing

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild id) ->
            case getDiscordGuildAndChannel id.guildId id.channelId local of
                Just ( _, channel ) ->
                    case threadRoute of
                        ViewThread threadMessageIndex ->
                            SeqDict.get threadMessageIndex channel.threads
                                |> Maybe.withDefault Thread.discordFrontendInit
                                |> .messages
                                |> MessageArray.length
                                |> Just

                        NoThread ->
                            Just (MessageArray.length channel.messages)

                Nothing ->
                    Nothing

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
            case SeqDict.get data.channelId local.discordDmChannels of
                Just dmChannel ->
                    Just (MessageArray.length dmChannel.messages)

                Nothing ->
                    Nothing


discordGuildAvailableStickersAndCustomEmojis : LocalUser -> DiscordFrontendGuild -> ( SeqSet (Id CustomEmojiId), SeqSet (Id StickerId) )
discordGuildAvailableStickersAndCustomEmojis localUser guild =
    ( SeqSet.intersect localUser.user.availableCustomEmojis guild.customEmojis
    , SeqSet.intersect localUser.user.availableStickers guild.stickers
    )


drawingHandleChangeFrontend :
    AnyGuildOrDmId
    -> Drawing.AnchorType
    -> Id UserId
    -> Drawing.LocalChange
    -> LocalState
    -> LocalState
drawingHandleChangeFrontend guildOrDmId anchor changedBy change local =
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
            { local
                | guilds =
                    SeqDict.updateIfExists
                        guildId
                        (updateChannel
                            (\channel ->
                                case anchor of
                                    Drawing.MessageAnchor threadRoute anchor2 ->
                                        case threadRoute of
                                            NoThreadWithMessage messageId ->
                                                drawingHandleChangeNoThreadFrontend changedBy anchor2 change messageId channel

                                            ViewThreadWithMessage threadId messageId ->
                                                { channel
                                                    | threads =
                                                        SeqDict.updateIfExists
                                                            threadId
                                                            (drawingHandleChangeNoThreadFrontend changedBy anchor2 change messageId)
                                                            channel.threads
                                                }

                                    Drawing.DateDividerAnchor threadRoute date ->
                                        drawingHandleDateDivider threadRoute date changedBy change channel
                            )
                            channelId
                        )
                        local.guilds
            }

        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
            { local
                | dmChannels =
                    SeqDict.updateIfExists
                        otherUserId
                        (\dmChannel ->
                            case anchor of
                                Drawing.MessageAnchor threadRoute anchor2 ->
                                    drawingHandleChangeHelperFrontend changedBy anchor2 change threadRoute dmChannel

                                Drawing.DateDividerAnchor threadRoute date ->
                                    drawingHandleDateDivider threadRoute date changedBy change dmChannel
                        )
                        local.dmChannels
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId }) ->
            { local
                | discordGuilds =
                    SeqDict.updateIfExists
                        guildId
                        (updateChannel
                            (\channel ->
                                case anchor of
                                    Drawing.MessageAnchor threadRoute anchor2 ->
                                        drawingHandleChangeHelperFrontend currentUserId anchor2 change threadRoute channel

                                    Drawing.DateDividerAnchor threadRoute date ->
                                        drawingHandleDateDivider threadRoute date currentUserId change channel
                            )
                            channelId
                        )
                        local.discordGuilds
            }

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
            { local
                | discordDmChannels =
                    SeqDict.updateIfExists
                        data.channelId
                        (\channel ->
                            case anchor of
                                Drawing.MessageAnchor (NoThreadWithMessage messageId) anchor2 ->
                                    drawingHandleChangeNoThreadFrontend data.currentUserId anchor2 change messageId channel

                                Drawing.DateDividerAnchor NoThread date ->
                                    { channel
                                        | dateDividerDrawings =
                                            SeqDictHelper.updateOrInsert
                                                date
                                                (\maybe ->
                                                    Maybe.withDefault Drawing.emptyDrawing maybe
                                                        |> Drawing.handleLocalChange data.currentUserId change
                                                )
                                                channel.dateDividerDrawings
                                    }

                                _ ->
                                    channel
                        )
                        local.discordDmChannels
            }


drawingHandleDateDivider :
    ThreadRoute
    -> Date
    -> userId
    -> Drawing.LocalChange
    ->
        { a
            | dateDividerDrawings : SeqDict Date (Drawing userId)
            , threads : SeqDict (Id ChannelMessageId) { d | dateDividerDrawings : SeqDict Date (Drawing userId) }
        }
    ->
        { a
            | dateDividerDrawings : SeqDict Date (Drawing userId)
            , threads : SeqDict (Id ChannelMessageId) { d | dateDividerDrawings : SeqDict Date (Drawing userId) }
        }
drawingHandleDateDivider threadRoute date changedBy change channel =
    case threadRoute of
        NoThread ->
            { channel
                | dateDividerDrawings =
                    SeqDictHelper.updateOrInsert
                        date
                        (\maybe ->
                            Maybe.withDefault Drawing.emptyDrawing maybe
                                |> Drawing.handleLocalChange changedBy change
                        )
                        channel.dateDividerDrawings
            }

        ViewThread threadId ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadId
                        (\thread ->
                            { thread
                                | dateDividerDrawings =
                                    SeqDictHelper.updateOrInsert
                                        date
                                        (\maybe ->
                                            Maybe.withDefault Drawing.emptyDrawing maybe
                                                |> Drawing.handleLocalChange changedBy change
                                        )
                                        thread.dateDividerDrawings
                            }
                        )
                        channel.threads
            }


drawingHandleChangeHelperFrontend :
    userId
    -> Drawing.MessageAnchor
    -> Drawing.LocalChange
    -> ThreadRouteWithMessage
    -> { b | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId), threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId) }
    -> { b | messages : MessageArray ChannelMessageId (Message ChannelMessageId userId), threads : SeqDict (Id ChannelMessageId) (FrontendGenericThread userId) }
drawingHandleChangeHelperFrontend changeBy anchor change threadRoute channel =
    case threadRoute of
        NoThreadWithMessage messageId ->
            drawingHandleChangeNoThreadFrontend changeBy anchor change messageId channel

        ViewThreadWithMessage threadId messageId ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadId
                        (drawingHandleChangeNoThreadFrontend changeBy anchor change messageId)
                        channel.threads
            }


drawingHandleChangeNoThreadFrontend :
    userId
    -> Drawing.MessageAnchor
    -> Drawing.LocalChange
    -> Id messageId
    -> { b | messages : MessageArray messageId (Message messageId userId) }
    -> { b | messages : MessageArray messageId (Message messageId userId) }
drawingHandleChangeNoThreadFrontend changedBy anchor change messageId channel =
    { channel
        | messages =
            MessageArray.updateIfExists
                messageId
                (Message.handleDrawingChange changedBy anchor change)
                channel.messages
    }


drawingHandleChangeHelperBackend :
    userId
    -> Drawing.LocalChange
    -> ThreadRouteWithMessage
    -> Drawing.MessageAnchor
    ->
        { b
            | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
        }
    ->
        { b
            | messages : IdArray ChannelMessageId (Message ChannelMessageId userId)
            , threads : SeqDict (Id ChannelMessageId) { c | messages : IdArray ThreadMessageId (Message ThreadMessageId userId) }
        }
drawingHandleChangeHelperBackend changeBy change threadRoute anchor channel =
    case threadRoute of
        NoThreadWithMessage messageId ->
            drawingHandleChangeNoThreadBackend changeBy anchor change messageId channel

        ViewThreadWithMessage threadId messageId ->
            { channel
                | threads =
                    SeqDict.updateIfExists
                        threadId
                        (drawingHandleChangeNoThreadBackend changeBy anchor change messageId)
                        channel.threads
            }


drawingHandleChangeNoThreadBackend :
    userId
    -> Drawing.MessageAnchor
    -> Drawing.LocalChange
    -> Id messageId
    -> { b | messages : IdArray messageId (Message messageId userId) }
    -> { b | messages : IdArray messageId (Message messageId userId) }
drawingHandleChangeNoThreadBackend changedBy anchor change messageId channel =
    { channel
        | messages = DmChannel.updateArray messageId (Message.handleDrawingChange changedBy anchor change) channel.messages
    }


arrayFindIndexRight : (a -> Bool) -> IdArray k a -> Maybe ( Int, a )
arrayFindIndexRight selectFunc array =
    arrayFindIndexRightHelper (IdArray.length array - 1) selectFunc array


arrayFindIndexRightHelper : Int -> (a -> Bool) -> IdArray k a -> Maybe ( Int, a )
arrayFindIndexRightHelper index selectFunc array =
    case IdArray.get (Id.fromInt index) array of
        Just value ->
            if selectFunc value then
                Just ( index, value )

            else
                arrayFindIndexRightHelper (index - 1) selectFunc array

        Nothing ->
            Nothing


markCallMessageAsEndedBackend : Time.Posix -> { a | messages : IdArray messageId (Message messageId userId) } -> { a | messages : IdArray messageId (Message messageId userId) }
markCallMessageAsEndedBackend time channel =
    let
        lastCallIndex : Maybe ( Int, Message messageId userId )
        lastCallIndex =
            arrayFindIndexRight
                (\message ->
                    case message of
                        CallStarted _ ->
                            True

                        _ ->
                            False
                )
                channel.messages
    in
    case lastCallIndex of
        Just ( lastCallIndex2, message ) ->
            case message of
                CallStarted callStarted ->
                    case callStarted.endedAt of
                        Nothing ->
                            { channel
                                | messages =
                                    IdArray.set (Id.fromInt lastCallIndex2) (CallStarted { callStarted | endedAt = Just time }) channel.messages
                            }

                        Just _ ->
                            channel

                _ ->
                    channel

        Nothing ->
            channel


markCallMessageAsEndedFrontend : Time.Posix -> { a | messages : MessageArray messageId (Message messageId userId) } -> { a | messages : MessageArray messageId (Message messageId userId) }
markCallMessageAsEndedFrontend time channel =
    let
        lastCallIndex : Maybe ( Id messageId, Message messageId userId )
        lastCallIndex =
            MessageArray.findRight
                (\message ->
                    case message of
                        CallStarted _ ->
                            True

                        _ ->
                            False
                )
                channel.messages
    in
    case lastCallIndex of
        Just ( lastCallIndex2, message ) ->
            case message of
                CallStarted callStarted ->
                    case callStarted.endedAt of
                        Nothing ->
                            { channel
                                | messages =
                                    MessageArray.set lastCallIndex2 (CallStarted { callStarted | endedAt = Just time }) channel.messages
                            }

                        Just _ ->
                            channel

                _ ->
                    channel

        Nothing ->
            channel
