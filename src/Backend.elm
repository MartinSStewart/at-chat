module Backend exposing
    ( adminUser
    , app
    , app_
    , emailToNotifyWhenErrorsAreLogged
    , loginEmailContent
    , loginEmailSubject
    )

import AiChat
import Array exposing (Array)
import Broadcast
import ChannelName
import Discord exposing (OptionalData(..))
import Discord.Id
import Discord.Markdown
import DiscordSync
import DmChannel exposing (DmChannel, DmChannelId, ExternalChannelId(..), ExternalMessageId(..), LastTypedAt, Thread)
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task
import Effect.Time as Time
import Effect.Websocket as Websocket
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import FileStatus exposing (FileData, FileHash, FileId)
import GuildName
import Hex
import Id exposing (ChannelId, ChannelMessageId, GuildId, GuildOrDmIdNoThread(..), Id, InviteLinkId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import Lamdera as LamderaCore
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId)
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), JoinGuildError(..), PrivateVapidKey(..))
import Log exposing (Log)
import LoginForm
import Message exposing (Message(..))
import NonemptyDict exposing (NonemptyDict)
import OneToOne exposing (OneToOne)
import Pages.Admin exposing (InitAdminData)
import Pagination
import PersonName
import Postmark
import Quantity
import RichText exposing (RichText)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Slack exposing (Channel(..))
import String.Nonempty exposing (NonemptyString(..))
import TOTP.Key
import Toop exposing (T4(..))
import TwoFactorAuthentication
import Types exposing (AdminStatusLoginData(..), BackendFileData, BackendModel, BackendMsg(..), LastRequest(..), LocalChange(..), LocalMsg(..), LoginData, LoginResult(..), LoginTokenData(..), ServerChange(..), ToBackend(..), ToFrontend(..))
import Unsafe
import User exposing (BackendUser, EmailStatus(..))
import UserAgent exposing (UserAgent)
import UserSession exposing (PushSubscription(..), SetViewing(..), ToBeFilledInByBackend(..), UserSession)
import VisibleMessages


app :
    { init : ( BackendModel, Cmd BackendMsg )
    , update : BackendMsg -> BackendModel -> ( BackendModel, Cmd BackendMsg )
    , updateFromFrontend : String -> String -> ToBackend -> BackendModel -> ( BackendModel, Cmd BackendMsg )
    , subscriptions : BackendModel -> Sub BackendMsg
    }
app =
    Lamdera.backend LamderaCore.broadcast LamderaCore.sendToFrontend app_


app_ :
    { init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
    , update : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
    , updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
    , subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
    }
app_ =
    { init = init
    , update = update
    , updateFromFrontend = updateFromFrontend
    , subscriptions = subscriptions
    }


adminUser : BackendUser
adminUser =
    LocalState.createNewUser
        (Time.millisToPosix 0)
        (Unsafe.personName "AT")
        (Unsafe.emailAddress Env.adminEmail |> RegisteredDirectly)
        True


init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
init =
    let
        guild : BackendGuild
        guild =
            { createdAt = Time.millisToPosix 0
            , createdBy = Broadcast.adminUserId
            , name = Unsafe.guildName "First guild"
            , icon = Nothing
            , channels =
                SeqDict.fromList
                    [ ( Id.fromInt 0
                      , { createdAt = Time.millisToPosix 0
                        , createdBy = Broadcast.adminUserId
                        , name = Unsafe.channelName "Welcome"
                        , messages = Array.empty
                        , status = ChannelActive
                        , lastTypedAt = SeqDict.empty
                        , linkedMessageIds = OneToOne.empty
                        , threads = SeqDict.empty
                        , linkedThreadIds = OneToOne.empty
                        }
                      )
                    , ( Id.fromInt 1
                      , { createdAt = Time.millisToPosix 0
                        , createdBy = Broadcast.adminUserId
                        , name = Unsafe.channelName "General"
                        , messages = Array.empty
                        , status = ChannelActive
                        , lastTypedAt = SeqDict.empty
                        , linkedMessageIds = OneToOne.empty
                        , threads = SeqDict.empty
                        , linkedThreadIds = OneToOne.empty
                        }
                      )
                    ]
            , linkedChannelIds = OneToOne.empty
            , members = SeqDict.fromList []
            , owner = Broadcast.adminUserId
            , invites = SeqDict.empty
            }
    in
    ( { users =
            Nonempty ( Broadcast.adminUserId, adminUser ) []
                |> NonemptyDict.fromNonemptyList
      , sessions = SeqDict.empty
      , connections = SeqDict.empty
      , secretCounter = 0
      , pendingLogins = SeqDict.empty
      , logs = Array.empty
      , emailNotificationsEnabled = True
      , lastErrorLogEmail = Time.millisToPosix -10000000000
      , twoFactorAuthentication = SeqDict.empty
      , twoFactorAuthenticationSetup = SeqDict.empty
      , guilds = SeqDict.fromList [ ( Id.fromInt 0, guild ) ]
      , discordModel = Discord.init
      , backendInitialized = True
      , discordGuilds = OneToOne.empty
      , discordUsers = OneToOne.empty
      , discordBotId = Nothing
      , dmChannels = SeqDict.empty
      , discordDms = OneToOne.empty
      , botToken = Nothing
      , slackWorkspaces = OneToOne.empty
      , slackUsers = OneToOne.empty
      , slackServers = OneToOne.empty
      , slackDms = OneToOne.empty
      , slackToken = Nothing
      , files = SeqDict.empty
      , publicVapidKey = ""
      , privateVapidKey = PrivateVapidKey ""
      , slackClientSecret = Nothing
      }
    , Command.none
    )


adminData : BackendModel -> Int -> InitAdminData
adminData model lastLogPageViewed =
    { lastLogPageViewed = lastLogPageViewed
    , users = model.users
    , emailNotificationsEnabled = model.emailNotificationsEnabled
    , twoFactorAuthentication = SeqDict.map (\_ a -> a.finishedAt) model.twoFactorAuthentication
    , botToken = model.botToken
    , privateVapidKey = model.privateVapidKey
    , slackClientSecret = model.slackClientSecret
    }


subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
subscriptions model =
    Subscription.batch
        [ Lamdera.onConnect UserConnected
        , Lamdera.onDisconnect UserDisconnected
        , Discord.subscription
            (\connection onData onClose -> Websocket.listen connection onData (\_ -> onClose))
            model.discordModel
            |> Maybe.withDefault Subscription.none
            |> Subscription.map DiscordWebsocketMsg
        ]


update : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
update msg model =
    case msg of
        UserConnected sessionId clientId ->
            ( { model
                | connections =
                    SeqDict.update
                        sessionId
                        (\maybeValue ->
                            case maybeValue of
                                Just value ->
                                    NonemptyDict.insert clientId NoRequestsMade value |> Just

                                Nothing ->
                                    NonemptyDict.singleton clientId NoRequestsMade |> Just
                        )
                        model.connections
              }
            , Lamdera.sendToFrontend clientId YouConnected
            )

        UserDisconnected sessionId clientId ->
            ( { model
                | connections =
                    SeqDict.update
                        sessionId
                        (Maybe.andThen
                            (\value ->
                                NonemptyDict.toSeqDict value
                                    |> SeqDict.remove clientId
                                    |> NonemptyDict.fromSeqDict
                            )
                        )
                        model.connections
              }
            , Command.none
            )

        BackendGotTime sessionId clientId toBackend time ->
            updateFromFrontendWithTime time sessionId clientId toBackend model

        SentLoginEmail time emailAddress result ->
            addLog time (Log.LoginEmail result emailAddress) model

        SentLogErrorEmail time email result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    addLog time (Log.SendLogErrorEmailFailed error email) model

        WebsocketCreatedHandle connection ->
            ( { model | discordModel = Discord.createdHandle connection model.discordModel }
            , Command.none
            )

        WebsocketSentData result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err Websocket.ConnectionClosed ->
                    let
                        _ =
                            Debug.log "WebsocketSentData" "ConnectionClosed"
                    in
                    ( model, Command.none )

        WebsocketClosedByBackend reopen ->
            ( model
            , if reopen then
                Websocket.createHandle WebsocketCreatedHandle Discord.websocketGatewayUrl

              else
                Command.none
            )

        DiscordWebsocketMsg discordMsg ->
            DiscordSync.discordWebsocketMsg discordMsg model

        GotDiscordGuilds time botUserId result ->
            case result of
                Ok data ->
                    let
                        users : SeqDict (Discord.Id.Id Discord.Id.UserId) Discord.GuildMember
                        users =
                            List.concatMap
                                (\( _, { members } ) ->
                                    List.map (\member -> ( member.user.id, member )) members
                                )
                                data
                                |> SeqDict.fromList
                    in
                    ( DiscordSync.addDiscordUsers time (SeqDict.remove botUserId users) model
                        |> DiscordSync.addDiscordGuilds time (SeqDict.fromList data)
                    , List.map
                        (\guildMember ->
                            Task.map
                                (\maybeAvatar -> ( guildMember.user.id, maybeAvatar ))
                                (case guildMember.user.avatar of
                                    Just avatar ->
                                        DiscordSync.loadImage
                                            (Discord.userAvatarUrl
                                                { size = Discord.DefaultImageSize
                                                , imageType = Discord.Choice1 Discord.Png
                                                }
                                                guildMember.user.id
                                                avatar
                                            )

                                    Nothing ->
                                        Task.succeed Nothing
                                )
                        )
                        (SeqDict.values users)
                        |> Task.sequence
                        |> Task.attempt GotDiscordUserAvatars
                    )

                Err error ->
                    let
                        _ =
                            Debug.log "GotDiscordGuilds" error
                    in
                    ( model, Command.none )

        GotSlackChannels time userId result ->
            case result of
                Ok data ->
                    ( addSlackUsers time userId data.currentUser data.users model
                        |> addSlackServer time userId data.team data.users data.channels
                    , Command.none
                    )

                Err error ->
                    let
                        _ =
                            Debug.log "GotSlackChannels" error
                    in
                    ( model, Command.none )

        GotCurrentUserGuilds time botToken result ->
            DiscordSync.gotCurrentUserGuilds time botToken result model

        SentGuildMessageToDiscord guildId channelId threadRoute result ->
            case result of
                Ok message ->
                    ( { model
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (\guild ->
                                    { guild
                                        | channels =
                                            SeqDict.updateIfExists
                                                channelId
                                                (\channel ->
                                                    case threadRoute of
                                                        ViewThreadWithMessage threadMessageIndex messageId ->
                                                            { channel
                                                                | threads =
                                                                    SeqDict.update
                                                                        threadMessageIndex
                                                                        (\maybe ->
                                                                            let
                                                                                thread : Thread
                                                                                thread =
                                                                                    Maybe.withDefault DmChannel.threadInit maybe
                                                                            in
                                                                            { thread
                                                                                | linkedMessageIds =
                                                                                    OneToOne.insert
                                                                                        (DiscordMessageId message.id)
                                                                                        messageId
                                                                                        thread.linkedMessageIds
                                                                            }
                                                                                |> Just
                                                                        )
                                                                        channel.threads
                                                                , linkedThreadIds =
                                                                    OneToOne.insert
                                                                        (DiscordChannelId message.channelId)
                                                                        threadMessageIndex
                                                                        channel.linkedThreadIds
                                                            }

                                                        NoThreadWithMessage messageId ->
                                                            { channel
                                                                | linkedMessageIds =
                                                                    OneToOne.insert
                                                                        (DiscordMessageId message.id)
                                                                        messageId
                                                                        channel.linkedMessageIds
                                                            }
                                                )
                                                guild.channels
                                    }
                                )
                                model.guilds
                      }
                    , Command.none
                    )

                Err _ ->
                    ( model, Command.none )

        DeletedDiscordMessage ->
            ( model, Command.none )

        EditedDiscordMessage ->
            ( model, Command.none )

        AiChatBackendMsg aiChatMsg ->
            ( model, Command.map AiChatToFrontend AiChatBackendMsg (AiChat.backendUpdate aiChatMsg) )

        SentDirectMessageToDiscord dmChannelId messageId result ->
            case result of
                Ok message ->
                    ( { model
                        | dmChannels =
                            SeqDict.updateIfExists
                                dmChannelId
                                (\dmChannel ->
                                    { dmChannel
                                        | linkedMessageIds =
                                            OneToOne.insert
                                                (DiscordMessageId message.id)
                                                messageId
                                                dmChannel.linkedMessageIds
                                    }
                                )
                                model.dmChannels
                      }
                    , Command.none
                    )

                Err _ ->
                    ( model, Command.none )

        GotDiscordUserAvatars result ->
            case result of
                Ok userAvatars ->
                    ( List.foldl
                        (\( discordUserId, maybeAvatar ) model2 ->
                            case OneToOne.second discordUserId model2.discordUsers of
                                Just userId ->
                                    { model2
                                        | users =
                                            NonemptyDict.updateIfExists
                                                userId
                                                (\user -> { user | icon = Maybe.map .fileHash maybeAvatar })
                                                model2.users
                                    }

                                Nothing ->
                                    model2
                        )
                        model
                        userAvatars
                    , Command.none
                    )

                Err _ ->
                    ( model, Command.none )

        SentNotification sessionId userId time result ->
            case result of
                Ok () ->
                    ( model, Command.none )

                Err error ->
                    addLogWithCmd
                        time
                        (Log.PushNotificationError userId error)
                        { model
                            | sessions =
                                SeqDict.updateIfExists
                                    sessionId
                                    (\session -> { session | pushSubscription = SubscriptionError error })
                                    model.sessions
                        }
                        (Broadcast.toSession
                            sessionId
                            (Server_PushNotificationFailed error)
                            model
                        )

        GotVapidKeys result ->
            ( case result of
                Ok keys ->
                    case String.split "," keys of
                        [ publicKey, privateKey ] ->
                            { model
                                | publicVapidKey = publicKey
                                , privateVapidKey = PrivateVapidKey privateKey
                            }

                        _ ->
                            model

                Err _ ->
                    model
            , Command.none
            )

        GotSlackOAuth time userId result ->
            case result of
                Ok ok ->
                    ( model
                    , Task.map4
                        T4
                        (Slack.getCurrentUser ok.userAccessToken)
                        (Slack.teamInfo ok.botAccessToken)
                        (Slack.listUsers ok.botAccessToken 100 Nothing)
                        (Slack.loadWorkspaceChannels ok.userAccessToken ok.teamId)
                        |> Task.andThen
                            (\(T4 currentUser teamInfo ( users, _ ) channels) ->
                                List.map
                                    (\channel ->
                                        Slack.loadMessages ok.userAccessToken (Slack.channelId channel) 100
                                            |> Task.map (\messages -> ( channel, messages ))
                                    )
                                    channels
                                    |> Task.sequence
                                    |> Task.map
                                        (\channels2 ->
                                            { currentUser = currentUser
                                            , team = teamInfo
                                            , users = users
                                            , channels = channels2
                                            }
                                        )
                            )
                        |> Task.attempt (GotSlackChannels time userId)
                    )

                Err _ ->
                    ( model, Command.none )


addSlackServer :
    Time.Posix
    -> Id UserId
    -> Slack.Team
    -> List Slack.User
    -> List ( Channel, List Slack.Message )
    -> BackendModel
    -> BackendModel
addSlackServer time currentUserId team slackUsers channels model =
    case OneToOne.second team.id model.slackServers of
        Just _ ->
            model

        Nothing ->
            let
                ownerId : Id UserId
                ownerId =
                    --case OneToOne.second data.guild.ownerId model.slackUsers of
                    --    Just ownerId2 ->
                    --        ownerId2
                    --
                    --    Nothing ->
                    Broadcast.adminUserId

                threads : SeqDict (Slack.Id Slack.ChannelId) (List ( Channel, List Slack.Message ))
                threads =
                    SeqDict.empty

                --List.foldl
                --    (\a dict ->
                --        case (Tuple.first a).parentId of
                --            Included (Just parentId) ->
                --                SeqDict.update
                --                    parentId
                --                    (\maybe ->
                --                        case maybe of
                --                            Just list ->
                --                                Just (a :: list)
                --
                --                            Nothing ->
                --                                Just [ a ]
                --                    )
                --                    dict
                --
                --            _ ->
                --                dict
                --    )
                --    SeqDict.empty
                --    data.threads
                members : SeqDict (Id UserId) { joinedAt : Time.Posix }
                members =
                    List.filterMap
                        (\guildMember ->
                            case OneToOne.second guildMember.id model.slackUsers of
                                Just userId ->
                                    if userId == ownerId then
                                        Nothing

                                    else
                                        Just ( userId, { joinedAt = time } )

                                Nothing ->
                                    Nothing
                        )
                        slackUsers
                        |> SeqDict.fromList

                newGuild : BackendGuild
                newGuild =
                    { createdAt = time
                    , createdBy = ownerId
                    , name = GuildName.fromStringLossy team.name
                    , icon = Nothing
                    , channels = SeqDict.empty
                    , linkedChannelIds = OneToOne.empty
                    , members = members
                    , owner = ownerId
                    , invites = SeqDict.empty
                    }

                newGuild2 =
                    List.foldl
                        (\( index, ( slackChannel, messages ) ) guild2 ->
                            case addSlackChannel time ownerId model threads index slackChannel messages of
                                Just ( slackChannelId, channelId, channel ) ->
                                    { newGuild
                                        | channels = SeqDict.insert channelId channel guild2.channels
                                        , linkedChannelIds =
                                            OneToOne.insert
                                                (SlackChannelId slackChannelId)
                                                channelId
                                                guild2.linkedChannelIds
                                    }

                                Nothing ->
                                    guild2
                        )
                        newGuild
                        (List.indexedMap Tuple.pair channels)

                newGuild3 : BackendGuild
                newGuild3 =
                    LocalState.addMember time Broadcast.adminUserId newGuild2
                        |> Result.withDefault newGuild2

                guildId : Id GuildId
                guildId =
                    Id.nextId model.guilds
            in
            { model
                | slackServers = OneToOne.insert team.id guildId model.slackServers
                , guilds = SeqDict.insert guildId newGuild3 model.guilds
                , users =
                    SeqDict.foldl
                        (\userId _ users ->
                            NonemptyDict.updateIfExists
                                userId
                                (\user ->
                                    SeqDict.foldl
                                        (\channelId channel user2 ->
                                            { user2
                                                | lastViewed =
                                                    SeqDict.insert
                                                        (GuildOrDmId_Guild guildId channelId)
                                                        (DmChannel.latestMessageId channel)
                                                        user2.lastViewed
                                                , lastViewedThreads =
                                                    SeqDict.foldl
                                                        (\threadId thread lastViewedThreads ->
                                                            SeqDict.insert
                                                                ( GuildOrDmId_Guild guildId channelId, threadId )
                                                                (DmChannel.latestThreadMessageId thread)
                                                                lastViewedThreads
                                                        )
                                                        user2.lastViewedThreads
                                                        channel.threads
                                            }
                                        )
                                        user
                                        newGuild3.channels
                                )
                                users
                        )
                        model.users
                        members
                , dmChannels =
                    List.foldl
                        (\( channel, messages ) dmChannels ->
                            case channel of
                                ImChannel data ->
                                    case OneToOne.second data.user model.slackUsers of
                                        Just otherUserId ->
                                            SeqDict.update
                                                (DmChannel.channelIdFromUserIds
                                                    currentUserId
                                                    otherUserId
                                                )
                                                (\maybe ->
                                                    case maybe of
                                                        Just dmChannel ->
                                                            dmChannel
                                                                |> addSlackMessages NoThread messages model
                                                                |> Just

                                                        Nothing ->
                                                            DmChannel.init
                                                                |> addSlackMessages NoThread messages model
                                                                |> Just
                                                )
                                                dmChannels

                                        Nothing ->
                                            dmChannels

                                NormalChannel _ ->
                                    dmChannels
                        )
                        model.dmChannels
                        channels
            }


addSlackUsers : Time.Posix -> Id UserId -> Slack.CurrentUser -> List Slack.User -> BackendModel -> BackendModel
addSlackUsers time currentUserId currentUser newUsers model =
    List.foldl
        (\slackUser model2 ->
            case ( OneToOne.second slackUser.id model2.slackUsers, slackUser.id == currentUser.userId ) of
                ( Nothing, False ) ->
                    let
                        userId : Id UserId
                        userId =
                            Id.nextId (NonemptyDict.toSeqDict model2.users)

                        user : BackendUser
                        user =
                            LocalState.createNewUser
                                time
                                (PersonName.fromStringLossy slackUser.name)
                                RegisteredFromSlack
                                False
                    in
                    { model2
                        | slackUsers = OneToOne.insert slackUser.id userId model2.slackUsers
                        , users = NonemptyDict.insert userId user model2.users
                    }

                _ ->
                    model2
        )
        { model | slackUsers = OneToOne.insert currentUser.userId currentUserId model.slackUsers }
        newUsers


addSlackChannel :
    Time.Posix
    -> Id UserId
    -> BackendModel
    -> SeqDict (Slack.Id Slack.ChannelId) (List ( Channel, List Slack.Message ))
    -> Int
    -> Channel
    -> List Slack.Message
    -> Maybe ( Slack.Id Slack.ChannelId, Id ChannelId, BackendChannel )
addSlackChannel time ownerId model _ index slackChannel messages =
    case slackChannel of
        NormalChannel slackChannel2 ->
            let
                channel : BackendChannel
                channel =
                    { createdAt = time
                    , createdBy = ownerId
                    , name = ChannelName.fromStringLossy slackChannel2.name
                    , messages = Array.empty
                    , status = ChannelActive
                    , lastTypedAt = SeqDict.empty
                    , linkedMessageIds = OneToOne.empty
                    , threads = SeqDict.empty
                    , linkedThreadIds = OneToOne.empty
                    }
                        |> addSlackMessages NoThread messages model
            in
            ( slackChannel2.id
            , Id.fromInt index
            , --List.foldl
              --    (\( thread, threadMessages ) channel2 ->
              --        case
              --            OneToOne.second
              --                (Discord.Id.toUInt64 thread.id |> Discord.Id.fromUInt64)
              --                channel2.linkedMessageIds
              --        of
              --            Just messageIndex ->
              --                addDiscordMessages (ViewThread messageIndex) threadMessages model channel2
              --
              --            Nothing ->
              --                channel2
              --    )
              channel
              --(SeqDict.get slackChannel.id threads |> Maybe.withDefault [])
            )
                |> Just

        ImChannel _ ->
            Nothing


addSlackMessages :
    ThreadRoute
    -> List Slack.Message
    -> BackendModel
    ->
        { d
            | messages : Array (Message ChannelMessageId)
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , linkedMessageIds : OneToOne ExternalMessageId (Id ChannelMessageId)
        }
    ->
        { d
            | messages : Array (Message ChannelMessageId)
            , lastTypedAt : SeqDict (Id UserId) (LastTypedAt ChannelMessageId)
            , linkedMessageIds : OneToOne ExternalMessageId (Id ChannelMessageId)
        }
addSlackMessages _ messages model channel =
    List.foldr
        (\message channel2 ->
            case ( message.messageType, OneToOne.second message.createdBy model.slackUsers ) of
                ( Slack.UserJoinedMessage, Nothing ) ->
                    channel2

                ( Slack.JoinerNotificationForInviter, Nothing ) ->
                    channel2

                ( Slack.BotMessage, Nothing ) ->
                    channel2

                ( Slack.UserMessage messageId data, Just userId ) ->
                    case OneToOne.second (SlackMessageId messageId) channel2.linkedMessageIds of
                        Just _ ->
                            channel2

                        Nothing ->
                            LocalState.createChannelMessageBackend
                                (Just (SlackMessageId messageId))
                                (UserTextMessage
                                    { createdAt = message.createdAt
                                    , createdBy = userId
                                    , content = RichText.fromSlack model.slackUsers data
                                    , reactions = SeqDict.empty
                                    , editedAt = Nothing
                                    , repliedTo = Nothing --maybeReplyTo
                                    , attachedFiles = SeqDict.empty
                                    }
                                )
                                channel2

                --handleDiscordCreateGuildMessageHelper
                --    message.id
                --    message.channelId
                --    (case threadRoute of
                --        ViewThread threadId ->
                --            ViewThreadWithMaybeMessage
                --                threadId
                --                Nothing
                --
                --        --(discordReplyTo message channel2 |> Maybe.map Id.changeType)
                --        NoThread ->
                --            NoThreadWithMaybeMessage Nothing
                --     --(discordReplyTo message channel2)
                --    )
                --    userId
                --    (RichText.fromDiscord model.discordUsers message.content)
                --    message
                --    channel2
                _ ->
                    channel2
        )
        channel
        messages


updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    ( model, Task.perform (BackendGotTime sessionId clientId msg) Time.now )


getLoginData :
    SessionId
    -> UserSession
    -> BackendUser
    -> Maybe ( GuildOrDmIdNoThread, ThreadRoute )
    -> BackendModel
    -> LoginData
getLoginData sessionId session user requestMessagesFor model =
    { session = session
    , adminData =
        if user.isAdmin then
            IsAdminLoginData (adminData model user.lastLogPageViewed)

        else
            IsNotAdminLoginData
    , twoFactorAuthenticationEnabled =
        SeqDict.get session.userId model.twoFactorAuthentication |> Maybe.map .finishedAt
    , guilds =
        SeqDict.filterMap
            (\guildId guild ->
                LocalState.guildToFrontendForUser
                    (case requestMessagesFor of
                        Just ( GuildOrDmId_Guild guildIdB channelId, threadRoute ) ->
                            if guildId == guildIdB then
                                Just ( channelId, threadRoute )

                            else
                                Nothing

                        _ ->
                            Nothing
                    )
                    session.userId
                    guild
            )
            model.guilds
    , dmChannels =
        SeqDict.foldl
            (\dmChannelId dmChannel dict ->
                case DmChannel.otherUserId session.userId dmChannelId of
                    Just otherUserId ->
                        SeqDict.insert otherUserId
                            (DmChannel.toFrontend
                                (case requestMessagesFor of
                                    Just ( GuildOrDmId_Dm otherUserIdB, threadRoute ) ->
                                        if otherUserId == otherUserIdB then
                                            Just threadRoute

                                        else
                                            Nothing

                                    _ ->
                                        Nothing
                                )
                                dmChannel
                            )
                            dict

                    Nothing ->
                        dict
            )
            SeqDict.empty
            model.dmChannels
    , user = user
    , otherUsers =
        NonemptyDict.toList model.users
            |> List.filterMap
                (\( otherUserId, otherUser ) ->
                    if otherUserId == session.userId then
                        Nothing

                    else
                        Just ( otherUserId, User.backendToFrontendForUser otherUser )
                )
            |> SeqDict.fromList
    , sessionId = sessionId
    , otherSessions =
        SeqDict.filterMap
            (\_ otherSession -> UserSession.toFrontend session.userId otherSession)
            (SeqDict.remove sessionId model.sessions)
    , publicVapidKey = model.publicVapidKey
    }


updateFromFrontendWithTime :
    Time.Posix
    -> SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendWithTime time sessionId clientId msg model =
    let
        model2 : BackendModel
        model2 =
            { model
                | connections =
                    SeqDict.updateIfExists
                        sessionId
                        (NonemptyDict.updateIfExists clientId (\_ -> LastRequest time))
                        model.connections
            }
    in
    case msg of
        CheckLoginRequest requestMessagesFor ->
            let
                cmd : Command BackendOnly ToFrontend backendMsg
                cmd =
                    case Broadcast.getUserFromSessionId sessionId model2 of
                        Just ( session, user ) ->
                            getLoginData sessionId session user requestMessagesFor model2
                                |> Ok
                                |> CheckLoginResponse
                                |> Lamdera.sendToFrontend clientId

                        Nothing ->
                            CheckLoginResponse (Err ()) |> Lamdera.sendToFrontend clientId
            in
            if model2.backendInitialized then
                ( { model2 | backendInitialized = False }
                , Command.batch
                    [ Websocket.createHandle WebsocketCreatedHandle Discord.websocketGatewayUrl
                    , Http.get
                        { url = FileStatus.domain ++ "/file/vapid"
                        , expect = Http.expectString GotVapidKeys
                        }
                    , cmd
                    ]
                )

            else
                ( model2, cmd )

        LoginWithTokenRequest requestMessagesFor loginCode userAgent ->
            loginWithToken time sessionId clientId loginCode requestMessagesFor userAgent model2

        FinishUserCreationRequest requestMessagesFor personName userAgent ->
            case SeqDict.get sessionId model2.pendingLogins of
                Just (WaitingForUserDataForSignup pendingLogin) ->
                    if
                        NonemptyDict.values model2.users
                            |> List.Nonempty.any (\a -> a.email == RegisteredDirectly pendingLogin.emailAddress)
                    then
                        -- It's maybe possible to end up here if a user initiates two account creations for the same email address and then completes both. We'll just silently fail in that case, not worth the effort to give a good error message.
                        ( model2, Command.none )

                    else
                        let
                            userId : Id UserId
                            userId =
                                Id.nextId (NonemptyDict.toSeqDict model2.users)

                            session : UserSession
                            session =
                                UserSession.init userId requestMessagesFor userAgent

                            newUser : BackendUser
                            newUser =
                                LocalState.createNewUser
                                    time
                                    personName
                                    (RegisteredDirectly pendingLogin.emailAddress)
                                    False

                            model3 : BackendModel
                            model3 =
                                { model2
                                    | sessions = SeqDict.insert sessionId session model2.sessions
                                    , pendingLogins = SeqDict.remove sessionId model2.pendingLogins
                                    , users = NonemptyDict.insert userId newUser model2.users
                                }
                        in
                        ( model3
                        , getLoginData sessionId session newUser requestMessagesFor model3
                            |> LoginSuccess
                            |> LoginWithTokenResponse
                            |> Lamdera.sendToFrontends sessionId
                        )

                _ ->
                    ( model2, Command.none )

        LoginWithTwoFactorRequest requestMessagesFor loginCode userAgent ->
            case SeqDict.get sessionId model2.pendingLogins of
                Just (WaitingForTwoFactorToken pendingLogin) ->
                    if
                        (pendingLogin.loginAttempts < LoginForm.maxLoginAttempts)
                            && (Duration.from pendingLogin.creationTime time |> Quantity.lessThan Duration.hour)
                    then
                        case
                            ( NonemptyDict.get pendingLogin.userId model2.users
                            , SeqDict.get pendingLogin.userId model2.twoFactorAuthentication
                            )
                        of
                            ( Just user, Just { secret } ) ->
                                if TwoFactorAuthentication.isValidCode time loginCode secret then
                                    let
                                        session : UserSession
                                        session =
                                            UserSession.init pendingLogin.userId requestMessagesFor userAgent
                                    in
                                    ( { model2
                                        | sessions = SeqDict.insert sessionId session model2.sessions
                                        , pendingLogins = SeqDict.remove sessionId model2.pendingLogins
                                      }
                                    , Command.batch
                                        [ getLoginData sessionId session user requestMessagesFor model2
                                            |> LoginSuccess
                                            |> LoginWithTokenResponse
                                            |> Lamdera.sendToFrontends sessionId
                                        , Broadcast.toUser
                                            (Just clientId)
                                            Nothing
                                            pendingLogin.userId
                                            (Server_NewSession
                                                sessionId
                                                { notificationMode = session.notificationMode
                                                , currentlyViewing = session.currentlyViewing
                                                , userAgent = session.userAgent
                                                }
                                                |> ServerChange
                                            )
                                            model2
                                        ]
                                    )

                                else
                                    ( { model2
                                        | pendingLogins =
                                            SeqDict.insert
                                                sessionId
                                                (WaitingForTwoFactorToken
                                                    { pendingLogin | loginAttempts = pendingLogin.loginAttempts + 1 }
                                                )
                                                model2.pendingLogins
                                      }
                                    , LoginTokenInvalid loginCode
                                        |> LoginWithTokenResponse
                                        |> Lamdera.sendToFrontend clientId
                                    )

                            _ ->
                                ( model2
                                , LoginTokenInvalid loginCode
                                    |> LoginWithTokenResponse
                                    |> Lamdera.sendToFrontend clientId
                                )

                    else
                        ( model2
                        , LoginTokenInvalid loginCode
                            |> LoginWithTokenResponse
                            |> Lamdera.sendToFrontend clientId
                        )

                _ ->
                    ( model2
                    , LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId
                    )

        GetLoginTokenRequest email ->
            let
                ( model3, result ) =
                    getLoginCode time model2
            in
            case
                ( NonemptyDict.toList model3.users
                    |> List.Extra.find (\( _, user ) -> user.email == RegisteredDirectly email)
                , result
                )
            of
                ( Just ( userId, user ), Ok loginCode ) ->
                    if shouldRateLimit time user then
                        let
                            ( model4, cmd ) =
                                addLog time (Log.LoginsRateLimited userId) model3
                        in
                        ( model4
                        , Command.batch [ cmd, Lamdera.sendToFrontend clientId GetLoginTokenRateLimited ]
                        )

                    else
                        ( { model3
                            | pendingLogins =
                                SeqDict.insert
                                    sessionId
                                    (WaitingForLoginToken
                                        { creationTime = time
                                        , userId = userId
                                        , loginAttempts = 0
                                        , loginCode = loginCode
                                        }
                                    )
                                    model3.pendingLogins
                            , users =
                                NonemptyDict.insert
                                    userId
                                    { user | recentLoginEmails = time :: List.take 100 user.recentLoginEmails }
                                    model3.users
                          }
                        , sendLoginEmail (SentLoginEmail time email) email loginCode
                        )

                ( Nothing, Ok loginCode ) ->
                    ( { model3
                        | pendingLogins =
                            SeqDict.insert
                                sessionId
                                (WaitingForLoginTokenForSignup
                                    { creationTime = time
                                    , loginAttempts = 0
                                    , emailAddress = email
                                    , loginCode = loginCode
                                    }
                                )
                                model3.pendingLogins
                      }
                    , sendLoginEmail (SentLoginEmail time email) email loginCode
                    )

                ( _, Err () ) ->
                    ( model3, Command.none )

        AdminToBackend adminToBackend ->
            asAdmin
                model2
                sessionId
                (\_ _ -> updateFromFrontendAdmin clientId adminToBackend model2)

        LogOutRequest ->
            asUser
                model2
                sessionId
                (\session _ ->
                    ( { model2 | sessions = SeqDict.remove sessionId model2.sessions }
                    , Command.batch
                        [ Lamdera.sendToFrontends sessionId LoggedOutSession
                        , Broadcast.toUser
                            Nothing
                            (Just sessionId)
                            session.userId
                            (Server_LoggedOut sessionId |> ServerChange)
                            model2
                        ]
                    )
                )

        LocalModelChangeRequest changeId localMsg ->
            case localMsg of
                Local_Invalid ->
                    ( model2, invalidChangeResponse changeId clientId )

                Local_Admin adminChange ->
                    asAdmin
                        model2
                        sessionId
                        (adminChangeUpdate clientId changeId adminChange model2 time)

                Local_SendMessage _ guildOrDmId text threadRoute attachedFiles ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (sendGuildMessage
                                    model2
                                    time
                                    clientId
                                    changeId
                                    guildId
                                    channelId
                                    threadRoute
                                    text
                                    (validateAttachedFiles model2.files attachedFiles)
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (sendDirectMessage
                                    model2
                                    time
                                    clientId
                                    changeId
                                    otherUserId
                                    threadRoute
                                    text
                                    (validateAttachedFiles model2.files attachedFiles)
                                )

                Local_NewChannel _ guildId channelName ->
                    asGuildOwner
                        model2
                        sessionId
                        guildId
                        (\userId _ guild ->
                            ( { model2
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.createChannel time userId channelName guild)
                                        model2.guilds
                              }
                            , Command.batch
                                [ Local_NewChannel time guildId channelName
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_NewChannel time guildId channelName |> ServerChange)
                                    model2
                                ]
                            )
                        )

                Local_EditChannel guildId channelId channelName ->
                    asGuildOwner
                        model2
                        sessionId
                        guildId
                        (\_ _ guild ->
                            ( { model2
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.editChannel channelName channelId guild)
                                        model2.guilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_EditChannel guildId channelId channelName |> ServerChange)
                                    model2
                                ]
                            )
                        )

                Local_DeleteChannel guildId channelId ->
                    asGuildOwner
                        model2
                        sessionId
                        guildId
                        (\userId _ guild ->
                            ( { model2
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.deleteChannel time userId channelId guild)
                                        model2.guilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_DeleteChannel guildId channelId |> ServerChange)
                                    model2
                                ]
                            )
                        )

                Local_NewInviteLink _ guildId _ ->
                    asGuildMember
                        model2
                        sessionId
                        guildId
                        (\{ userId } _ guild ->
                            let
                                ( model3, id ) =
                                    SecretId.getShortUniqueId time model2
                            in
                            ( { model3
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        (LocalState.addInvite id userId time guild)
                                        model3.guilds
                              }
                            , Command.batch
                                [ Local_NewInviteLink time guildId (FilledInByBackend id)
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_NewInviteLink time userId guildId id |> ServerChange)
                                    model3
                                ]
                            )
                        )

                Local_NewGuild _ guildName _ ->
                    asUser
                        model2
                        sessionId
                        (\{ userId } _ ->
                            let
                                guildId : Id GuildId
                                guildId =
                                    Id.nextId model2.guilds

                                newGuild : BackendGuild
                                newGuild =
                                    LocalState.createGuild time userId guildName
                            in
                            ( { model2
                                | guilds = SeqDict.insert guildId newGuild model2.guilds
                              }
                            , Command.batch
                                [ Local_NewGuild time guildName (FilledInByBackend guildId)
                                    |> LocalChangeResponse changeId
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    userId
                                    (Local_NewGuild time guildName (FilledInByBackend guildId) |> LocalChange userId)
                                    model2
                                ]
                            )
                        )

                Local_MemberTyping _ ( guildOrDmId, threadRoute ) ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    ( { model2
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                (LocalState.updateChannel
                                                    (LocalState.memberIsTyping userId time threadRoute)
                                                    channelId
                                                    guild
                                                )
                                                model2.guilds
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toGuildExcludingOne
                                            clientId
                                            guildId
                                            (Server_MemberTyping time userId ( guildOrDmId, threadRoute ) |> ServerChange)
                                            model2
                                        ]
                                    )
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    ( { model2
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.memberIsTyping userId time threadRoute)
                                                model2.dmChannels
                                      }
                                    , Command.batch
                                        [ Local_MemberTyping time ( guildOrDmId, threadRoute )
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toUser
                                            (Just clientId)
                                            Nothing
                                            otherUserId
                                            (Server_MemberTyping time userId ( GuildOrDmId_Dm userId, threadRoute ) |> ServerChange)
                                            model2
                                        ]
                                    )
                                )

                Local_AddReactionEmoji guildOrDmId threadRoute emoji ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    DiscordSync.addReactionEmoji
                                        guildId
                                        guild
                                        channelId
                                        threadRoute
                                        userId
                                        emoji
                                        model2
                                        (Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg))
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    ( { model2
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.addReactionEmoji emoji userId threadRoute)
                                                model2.dmChannels
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDmChannel
                                            clientId
                                            userId
                                            otherUserId
                                            (\otherUserId2 ->
                                                Server_AddReactionEmoji
                                                    userId
                                                    (GuildOrDmId_Dm otherUserId2)
                                                    threadRoute
                                                    emoji
                                            )
                                            model2
                                        ]
                                    )
                                )

                Local_RemoveReactionEmoji guildOrDmId threadRoute emoji ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    ( { model2
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                (LocalState.updateChannel
                                                    (LocalState.removeReactionEmoji emoji userId threadRoute)
                                                    channelId
                                                    guild
                                                )
                                                model2.guilds
                                      }
                                    , Command.batch
                                        [ Local_RemoveReactionEmoji guildOrDmId threadRoute emoji
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toGuildExcludingOne
                                            clientId
                                            guildId
                                            (Server_RemoveReactionEmoji userId guildOrDmId threadRoute emoji
                                                |> ServerChange
                                            )
                                            model2
                                        ]
                                    )
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId : DmChannelId
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    ( { model2
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.removeReactionEmoji emoji userId threadRoute)
                                                model2.dmChannels
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , Broadcast.toDmChannel
                                            clientId
                                            userId
                                            otherUserId
                                            (\otherUserId2 ->
                                                Server_RemoveReactionEmoji
                                                    userId
                                                    (GuildOrDmId_Dm otherUserId2)
                                                    threadRoute
                                                    emoji
                                            )
                                            model2
                                        ]
                                    )
                                )

                Local_SendEditMessage _ guildOrDmId threadRoute newContent attachedFiles ->
                    let
                        attachedFiles2 : SeqDict (Id FileId) FileData
                        attachedFiles2 =
                            validateAttachedFiles model2.files attachedFiles
                    in
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    sendEditMessage
                                        clientId
                                        changeId
                                        time
                                        newContent
                                        attachedFiles2
                                        guildId
                                        channelId
                                        threadRoute
                                        model2
                                        userId
                                        guild
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId : DmChannelId
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    case SeqDict.get dmChannelId model2.dmChannels of
                                        Just dmChannel ->
                                            case
                                                LocalState.editMessageHelper
                                                    time
                                                    userId
                                                    newContent
                                                    attachedFiles2
                                                    threadRoute
                                                    dmChannel
                                            of
                                                Ok dmChannel2 ->
                                                    ( { model2
                                                        | dmChannels =
                                                            SeqDict.insert dmChannelId dmChannel2 model2.dmChannels
                                                      }
                                                    , Command.batch
                                                        [ Local_SendEditMessage
                                                            time
                                                            guildOrDmId
                                                            threadRoute
                                                            newContent
                                                            attachedFiles2
                                                            |> LocalChangeResponse changeId
                                                            |> Lamdera.sendToFrontend clientId
                                                        , Broadcast.toDmChannel
                                                            clientId
                                                            userId
                                                            otherUserId
                                                            (\otherUserId2 ->
                                                                Server_SendEditMessage
                                                                    time
                                                                    userId
                                                                    (GuildOrDmId_Dm otherUserId2)
                                                                    threadRoute
                                                                    newContent
                                                                    attachedFiles2
                                                            )
                                                            model2
                                                        , case ( threadRoute, OneToOne.first dmChannelId model2.discordDms ) of
                                                            ( NoThreadWithMessage messageIndex, Just discordDmId ) ->
                                                                case
                                                                    ( OneToOne.first messageIndex dmChannel2.linkedMessageIds
                                                                    , model2.botToken
                                                                    )
                                                                of
                                                                    ( Just (DiscordMessageId discordMessageId), Just botToken ) ->
                                                                        Discord.editMessage
                                                                            (DiscordSync.botTokenToAuth botToken)
                                                                            { channelId = discordDmId
                                                                            , messageId = discordMessageId
                                                                            , content = toDiscordContent model2 attachedFiles2 newContent
                                                                            }
                                                                            |> Task.attempt (\_ -> EditedDiscordMessage)

                                                                    _ ->
                                                                        Command.none

                                                            _ ->
                                                                Command.none
                                                        ]
                                                    )

                                                Err () ->
                                                    ( model2
                                                    , LocalChangeResponse changeId Local_Invalid
                                                        |> Lamdera.sendToFrontend clientId
                                                    )

                                        Nothing ->
                                            ( model2
                                            , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
                                            )
                                )

                Local_MemberEditTyping _ guildOrDmId threadRoute ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    case
                                        LocalState.memberIsEditTyping
                                            userId
                                            time
                                            channelId
                                            threadRoute
                                            guild
                                    of
                                        Ok guild2 ->
                                            ( { model2 | guilds = SeqDict.insert guildId guild2 model2.guilds }
                                            , Command.batch
                                                [ Local_MemberEditTyping time guildOrDmId threadRoute
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , Broadcast.toGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_MemberEditTyping time userId guildOrDmId threadRoute
                                                        |> ServerChange
                                                    )
                                                    model2
                                                ]
                                            )

                                        Err () ->
                                            ( model2
                                            , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
                                            )
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId : DmChannelId
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    case SeqDict.get dmChannelId model2.dmChannels of
                                        Just dmChannel ->
                                            case LocalState.memberIsEditTypingHelper time userId threadRoute dmChannel of
                                                Ok dmChannel2 ->
                                                    ( { model2
                                                        | dmChannels =
                                                            SeqDict.insert dmChannelId dmChannel2 model2.dmChannels
                                                      }
                                                    , Command.batch
                                                        [ Local_MemberEditTyping time guildOrDmId threadRoute
                                                            |> LocalChangeResponse changeId
                                                            |> Lamdera.sendToFrontend clientId
                                                        , Broadcast.toUser
                                                            (Just clientId)
                                                            Nothing
                                                            otherUserId
                                                            (Server_MemberEditTyping
                                                                time
                                                                userId
                                                                (GuildOrDmId_Dm userId)
                                                                threadRoute
                                                                |> ServerChange
                                                            )
                                                            model2
                                                        ]
                                                    )

                                                _ ->
                                                    ( model2
                                                    , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
                                                    )

                                        Nothing ->
                                            ( model2
                                            , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
                                            )
                                )

                Local_SetLastViewed guildOrDmId threadRoute ->
                    asUser
                        model2
                        sessionId
                        (\{ userId } user ->
                            ( { model2
                                | users =
                                    NonemptyDict.insert
                                        userId
                                        (case threadRoute of
                                            ViewThreadWithMessage threadMessageId messageId ->
                                                { user
                                                    | lastViewedThreads =
                                                        SeqDict.insert
                                                            ( guildOrDmId, threadMessageId )
                                                            messageId
                                                            user.lastViewedThreads
                                                }

                                            NoThreadWithMessage messageId ->
                                                { user
                                                    | lastViewed = SeqDict.insert guildOrDmId messageId user.lastViewed
                                                }
                                        )
                                        model2.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser (Just clientId) Nothing userId (LocalChange userId localMsg) model2
                                ]
                            )
                        )

                Local_DeleteMessage guildOrDmId threadRoute ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\{ userId } _ guild ->
                                    case LocalState.deleteMessageBackend userId channelId threadRoute guild of
                                        Ok ( maybeDiscordMessageId, guild2 ) ->
                                            ( { model2 | guilds = SeqDict.insert guildId guild2 model2.guilds }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend
                                                    clientId
                                                    (LocalChangeResponse changeId localMsg)
                                                , Broadcast.toGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_DeleteMessage userId guildOrDmId threadRoute |> ServerChange)
                                                    model2
                                                , case
                                                    ( OneToOne.first channelId guild2.linkedChannelIds
                                                    , maybeDiscordMessageId
                                                    , model2.botToken
                                                    )
                                                  of
                                                    ( Just (DiscordChannelId discordChannelId), Just (DiscordMessageId discordMessageId), Just botToken ) ->
                                                        Discord.deleteMessage
                                                            (DiscordSync.botTokenToAuth botToken)
                                                            { channelId = discordChannelId
                                                            , messageId = discordMessageId
                                                            }
                                                            |> Task.attempt (\_ -> DeletedDiscordMessage)

                                                    _ ->
                                                        Command.none
                                                ]
                                            )

                                        Err _ ->
                                            ( model2
                                            , Lamdera.sendToFrontend
                                                clientId
                                                (LocalChangeResponse changeId Local_Invalid)
                                            )
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    let
                                        dmChannelId : DmChannelId
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    case SeqDict.get dmChannelId model2.dmChannels of
                                        Just dmChannel ->
                                            case LocalState.deleteMessageBackendHelper userId threadRoute dmChannel of
                                                Ok ( maybeDiscordMessageId, dmChannel2 ) ->
                                                    ( { model2 | dmChannels = SeqDict.insert dmChannelId dmChannel2 model2.dmChannels }
                                                    , Command.batch
                                                        [ Lamdera.sendToFrontend
                                                            clientId
                                                            (LocalChangeResponse changeId localMsg)
                                                        , Broadcast.toDmChannel
                                                            clientId
                                                            userId
                                                            otherUserId
                                                            (\otherUserId2 ->
                                                                Server_DeleteMessage
                                                                    userId
                                                                    (GuildOrDmId_Dm otherUserId2)
                                                                    threadRoute
                                                            )
                                                            model2
                                                        , case
                                                            ( OneToOne.first dmChannelId model2.discordDms
                                                            , maybeDiscordMessageId
                                                            , model2.botToken
                                                            )
                                                          of
                                                            ( Just discordChannelId, Just (DiscordMessageId discordMessageId), Just botToken ) ->
                                                                Discord.deleteMessage
                                                                    (DiscordSync.botTokenToAuth botToken)
                                                                    { channelId = discordChannelId
                                                                    , messageId = discordMessageId
                                                                    }
                                                                    |> Task.attempt (\_ -> DeletedDiscordMessage)

                                                            _ ->
                                                                Command.none
                                                        ]
                                                    )

                                                Err _ ->
                                                    ( model2
                                                    , Lamdera.sendToFrontend
                                                        clientId
                                                        (LocalChangeResponse changeId Local_Invalid)
                                                    )

                                        Nothing ->
                                            ( model2
                                            , Lamdera.sendToFrontend
                                                clientId
                                                (LocalChangeResponse changeId Local_Invalid)
                                            )
                                )

                Local_CurrentlyViewing viewing ->
                    let
                        viewingChannel : Maybe ( GuildOrDmIdNoThread, ThreadRoute )
                        viewingChannel =
                            UserSession.setViewingToCurrentlyViewing viewing

                        updateSession : UserSession -> UserSession
                        updateSession session =
                            UserSession.setCurrentlyViewing viewingChannel session

                        broadcastCmd : UserSession -> Command BackendOnly ToFrontend msg
                        broadcastCmd session =
                            Broadcast.toUser
                                Nothing
                                (Just sessionId)
                                session.userId
                                (Server_CurrentlyViewing viewingChannel |> ServerChange)
                                model2
                    in
                    case viewing of
                        ViewDm otherUserId _ ->
                            asUser
                                model2
                                sessionId
                                (\session user ->
                                    case SeqDict.get (DmChannel.channelIdFromUserIds otherUserId session.userId) model2.dmChannels of
                                        Just channel ->
                                            ( { model2
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastDmViewed otherUserId NoThread user)
                                                        model2.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model2.sessions
                                              }
                                            , Command.batch
                                                [ ViewDm otherUserId (loadMessagesHelper channel)
                                                    |> Local_CurrentlyViewing
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastCmd session
                                                ]
                                            )

                                        Nothing ->
                                            ( model2
                                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId Local_Invalid)
                                            )
                                )

                        ViewDmThread otherUserId threadId _ ->
                            asUser
                                model2
                                sessionId
                                (\session user ->
                                    case SeqDict.get (DmChannel.channelIdFromUserIds session.userId otherUserId) model2.dmChannels of
                                        Just dmChannel ->
                                            ( { model2
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastDmViewed otherUserId (ViewThread threadId) user)
                                                        model2.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model2.sessions
                                              }
                                            , Command.batch
                                                [ ViewDmThread
                                                    otherUserId
                                                    threadId
                                                    (SeqDict.get threadId dmChannel.threads
                                                        |> Maybe.withDefault DmChannel.threadInit
                                                        |> loadMessagesHelper
                                                    )
                                                    |> Local_CurrentlyViewing
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastCmd session
                                                ]
                                            )

                                        Nothing ->
                                            ( model2
                                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId Local_Invalid)
                                            )
                                )

                        ViewChannel guildId channelId _ ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\session user guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model2
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastChannelViewed guildId channelId NoThread user)
                                                        model2.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model2.sessions
                                              }
                                            , Command.batch
                                                [ ViewChannel guildId channelId (loadMessagesHelper channel)
                                                    |> Local_CurrentlyViewing
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastCmd session
                                                ]
                                            )

                                        Nothing ->
                                            ( model2
                                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId Local_Invalid)
                                            )
                                )

                        ViewChannelThread guildId channelId threadId _ ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\session user guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            ( { model2
                                                | users =
                                                    NonemptyDict.insert
                                                        session.userId
                                                        (User.setLastChannelViewed
                                                            guildId
                                                            channelId
                                                            (ViewThread threadId)
                                                            user
                                                        )
                                                        model2.users
                                                , sessions =
                                                    SeqDict.insert sessionId (updateSession session) model2.sessions
                                              }
                                            , Command.batch
                                                [ ViewChannelThread
                                                    guildId
                                                    channelId
                                                    threadId
                                                    (SeqDict.get threadId channel.threads
                                                        |> Maybe.withDefault DmChannel.threadInit
                                                        |> loadMessagesHelper
                                                    )
                                                    |> Local_CurrentlyViewing
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastCmd session
                                                ]
                                            )

                                        Nothing ->
                                            ( model2
                                            , Command.batch
                                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId Local_Invalid)
                                                , broadcastCmd session
                                                ]
                                            )
                                )

                        StopViewingChannel ->
                            asUser
                                model2
                                sessionId
                                (\session _ ->
                                    ( { model2
                                        | sessions = SeqDict.insert sessionId (updateSession session) model2.sessions
                                      }
                                    , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_SetName name ->
                    asUser
                        model2
                        sessionId
                        (\{ userId } user ->
                            ( { model2
                                | users = NonemptyDict.insert userId { user | name = name } model2.users
                              }
                            , Command.batch
                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                , Broadcast.toEveryoneWhoCanSeeUser
                                    clientId
                                    userId
                                    (ServerChange (Server_SetName userId name))
                                    model2
                                ]
                            )
                        )

                Local_LoadChannelMessages guildOrDmId oldestVisibleMessage _ ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\_ _ guild ->
                                    ( model2
                                    , case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            handleMessagesRequest oldestVisibleMessage channel
                                                |> Local_LoadChannelMessages guildOrDmId oldestVisibleMessage
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            LocalChangeResponse changeId Local_Invalid
                                                |> Lamdera.sendToFrontend clientId
                                    )
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    ( model2
                                    , SeqDict.get (DmChannel.channelIdFromUserIds userId otherUserId) model2.dmChannels
                                        |> Maybe.withDefault DmChannel.init
                                        |> handleMessagesRequest oldestVisibleMessage
                                        |> Local_LoadChannelMessages guildOrDmId oldestVisibleMessage
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage _ ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\_ _ guild ->
                                    ( model2
                                    , case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            SeqDict.get threadId channel.threads
                                                |> Maybe.withDefault DmChannel.threadInit
                                                |> handleMessagesRequest oldestVisibleMessage
                                                |> Local_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage
                                                |> LocalChangeResponse changeId
                                                |> Lamdera.sendToFrontend clientId

                                        Nothing ->
                                            LocalChangeResponse changeId Local_Invalid
                                                |> Lamdera.sendToFrontend clientId
                                    )
                                )

                        GuildOrDmId_Dm otherUserId ->
                            asUser
                                model2
                                sessionId
                                (\{ userId } _ ->
                                    ( model2
                                    , SeqDict.get (DmChannel.channelIdFromUserIds userId otherUserId) model2.dmChannels
                                        |> Maybe.withDefault DmChannel.init
                                        |> .threads
                                        |> SeqDict.get threadId
                                        |> Maybe.withDefault DmChannel.threadInit
                                        |> handleMessagesRequest oldestVisibleMessage
                                        |> Local_LoadThreadMessages guildOrDmId threadId oldestVisibleMessage
                                        |> LocalChangeResponse changeId
                                        |> Lamdera.sendToFrontend clientId
                                    )
                                )

                Local_SetGuildNotificationLevel guildId notificationLevel ->
                    asUser
                        model2
                        sessionId
                        (\{ userId } user ->
                            ( { model
                                | users =
                                    NonemptyDict.insert
                                        userId
                                        (User.setGuildNotificationLevel guildId notificationLevel user)
                                        model2.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    userId
                                    (Server_SetGuildNotificationLevel guildId notificationLevel |> ServerChange)
                                    model2
                                ]
                            )
                        )

                Local_SetNotificationMode notificationMode ->
                    asUser
                        model2
                        sessionId
                        (\session _ ->
                            ( { model2
                                | sessions =
                                    SeqDict.insert
                                        sessionId
                                        { session | notificationMode = notificationMode }
                                        model2.sessions
                              }
                            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                            )
                        )

                Local_RegisterPushSubscription pushSubscription ->
                    asUser
                        model2
                        sessionId
                        (\session _ ->
                            ( { model2
                                | sessions =
                                    SeqDict.insert
                                        sessionId
                                        { session | pushSubscription = Subscribed pushSubscription }
                                        model2.sessions
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                , Broadcast.pushNotification
                                    sessionId
                                    session.userId
                                    time
                                    "Success!"
                                    "Push notifications enabled"
                                    "https://at-chat.app/at-logo-no-background.png"
                                    pushSubscription
                                    model2
                                ]
                            )
                        )

        TwoFactorToBackend toBackend2 ->
            asUser
                model2
                sessionId
                (twoFactorAuthenticationUpdateFromFrontend clientId time toBackend2 model2)

        AiChatToBackend aiChatToBackend ->
            ( model2
            , Command.map
                AiChatToFrontend
                AiChatBackendMsg
                (AiChat.updateFromFrontend clientId aiChatToBackend)
            )

        JoinGuildByInviteRequest guildId inviteLinkId ->
            asUser
                model2
                sessionId
                (joinGuildByInvite inviteLinkId time sessionId clientId guildId model2)

        ReloadDataRequest requestMessagesFor ->
            ( model2
            , case Broadcast.getUserFromSessionId sessionId model2 of
                Just ( userId, user ) ->
                    getLoginData sessionId userId user requestMessagesFor model2
                        |> Ok
                        |> ReloadDataResponse
                        |> Lamdera.sendToFrontend clientId

                Nothing ->
                    Lamdera.sendToFrontend clientId (ReloadDataResponse (Err ()))
            )

        LinkSlackOAuthCode oAuthCode sessionId2 ->
            asUser
                model2
                sessionId2
                (\{ userId } _ ->
                    ( model2
                    , case model2.slackClientSecret of
                        Just clientSecret ->
                            Slack.exchangeCodeForToken clientSecret Env.slackClientId oAuthCode
                                |> Task.attempt (GotSlackOAuth time userId)

                        Nothing ->
                            Command.none
                    )
                )


loadMessagesHelper :
    { a | messages : Array (Message messageId) }
    -> ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId))
loadMessagesHelper channel =
    let
        messageCount : Int
        messageCount =
            Array.length channel.messages

        indexStart : Int
        indexStart =
            max (messageCount - VisibleMessages.pageSize) 0
    in
    FilledInByBackend
        (Array.slice indexStart messageCount channel.messages
            |> Array.toList
            |> List.indexedMap
                (\index message ->
                    ( index + indexStart |> Id.fromInt, message )
                )
            |> SeqDict.fromList
        )


handleMessagesRequest :
    Id messageId
    -> { b | messages : Array (Message messageId) }
    -> ToBeFilledInByBackend (SeqDict (Id messageId) (Message messageId))
handleMessagesRequest oldestVisibleMessage channel =
    let
        oldestVisibleMessage2 =
            Id.toInt oldestVisibleMessage

        nextOldestVisible =
            max (oldestVisibleMessage2 - VisibleMessages.pageSize) 0
    in
    Array.slice nextOldestVisible oldestVisibleMessage2 channel.messages
        |> Array.toList
        |> List.indexedMap (\index message -> ( Id.fromInt (index + nextOldestVisible), message ))
        |> SeqDict.fromList
        |> FilledInByBackend


sendEditMessage :
    ClientId
    -> ChangeId
    -> Time.Posix
    -> Nonempty RichText
    -> SeqDict (Id FileId) FileData
    -> Id GuildId
    -> Id ChannelId
    -> ThreadRouteWithMessage
    -> BackendModel
    -> Id UserId
    -> BackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendEditMessage clientId changeId time newContent attachedFiles2 guildId channelId threadRoute model2 userId guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case
                LocalState.editMessageHelper
                    time
                    userId
                    newContent
                    attachedFiles2
                    threadRoute
                    channel
            of
                Ok channel2 ->
                    ( { model2
                        | guilds =
                            SeqDict.updateIfExists
                                guildId
                                (LocalState.updateChannel (\_ -> channel2) channelId)
                                model2.guilds
                      }
                    , Command.batch
                        [ Local_SendEditMessage
                            time
                            (GuildOrDmId_Guild guildId channelId)
                            threadRoute
                            newContent
                            attachedFiles2
                            |> LocalChangeResponse changeId
                            |> Lamdera.sendToFrontend clientId
                        , Broadcast.toGuildExcludingOne
                            clientId
                            guildId
                            (Server_SendEditMessage
                                time
                                userId
                                (GuildOrDmId_Guild guildId channelId)
                                threadRoute
                                newContent
                                attachedFiles2
                                |> ServerChange
                            )
                            model2
                        , case ( threadRoute, model2.botToken ) of
                            ( ViewThreadWithMessage threadMessageIndex messageIndex, Just botToken ) ->
                                case
                                    ( OneToOne.first threadMessageIndex channel2.linkedThreadIds
                                    , SeqDict.get threadMessageIndex channel2.threads
                                    )
                                of
                                    ( Just (DiscordChannelId discordChannelId), Just thread ) ->
                                        case OneToOne.first messageIndex thread.linkedMessageIds of
                                            Just (DiscordMessageId discordMessageId) ->
                                                Discord.editMessage
                                                    (DiscordSync.botTokenToAuth botToken)
                                                    { channelId = discordChannelId
                                                    , messageId = discordMessageId
                                                    , content = toDiscordContent model2 attachedFiles2 newContent
                                                    }
                                                    |> Task.attempt (\_ -> EditedDiscordMessage)

                                            Just (SlackMessageId _) ->
                                                Command.none

                                            Nothing ->
                                                Command.none

                                    _ ->
                                        Command.none

                            ( NoThreadWithMessage messageIndex, Just botToken ) ->
                                case
                                    ( OneToOne.first channelId guild.linkedChannelIds
                                    , OneToOne.first messageIndex channel2.linkedMessageIds
                                    )
                                of
                                    ( Just (DiscordChannelId discordChannelId), Just (DiscordMessageId discordMessageId) ) ->
                                        Discord.editMessage
                                            (DiscordSync.botTokenToAuth botToken)
                                            { channelId = discordChannelId
                                            , messageId = discordMessageId
                                            , content = toDiscordContent model2 attachedFiles2 newContent
                                            }
                                            |> Task.attempt (\_ -> EditedDiscordMessage)

                                    _ ->
                                        Command.none

                            _ ->
                                Command.none
                        ]
                    )

                Err () ->
                    ( model2
                    , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
                    )

        Nothing ->
            ( model2
            , LocalChangeResponse changeId Local_Invalid |> Lamdera.sendToFrontend clientId
            )


toDiscordContent : BackendModel -> SeqDict (Id FileId) FileData -> Nonempty RichText -> String
toDiscordContent model attachedFiles content =
    Discord.Markdown.toString (RichText.toDiscord model.discordUsers attachedFiles content)


joinGuildByInvite :
    SecretId InviteLinkId
    -> Time.Posix
    -> SessionId
    -> ClientId
    -> Id GuildId
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
joinGuildByInvite inviteLinkId time sessionId clientId guildId model { userId } user =
    case SeqDict.get guildId model.guilds of
        Just guild ->
            case ( SeqDict.get inviteLinkId guild.invites, LocalState.addMember time userId guild ) of
                ( Just _, Ok guild2 ) ->
                    let
                        modelWithoutUser : BackendModel
                        modelWithoutUser =
                            model

                        model2 : BackendModel
                        model2 =
                            { model
                                | guilds = SeqDict.insert guildId guild2 model.guilds
                                , users =
                                    NonemptyDict.insert
                                        userId
                                        (LocalState.markAllChannelsAsViewed guildId guild2 user)
                                        model.users
                            }
                    in
                    ( model2
                    , Command.batch
                        [ Broadcast.toGuildExcludingOne
                            clientId
                            guildId
                            (Server_MemberJoined
                                time
                                userId
                                guildId
                                (User.backendToFrontendForUser user)
                                |> ServerChange
                            )
                            modelWithoutUser
                        , case
                            ( NonemptyDict.get guild2.owner model2.users
                            , LocalState.guildToFrontendForUser
                                (Just ( LocalState.announcementChannel guild2, NoThread ))
                                userId
                                guild2
                            )
                          of
                            ( Just owner, Just frontendGuild ) ->
                                { guildId = guildId
                                , guild = frontendGuild
                                , owner = User.backendToFrontendForUser owner
                                , members =
                                    SeqDict.filterMap
                                        (\userId2 _ ->
                                            NonemptyDict.get userId2 model2.users
                                                |> Maybe.map User.backendToFrontendForUser
                                        )
                                        guild2.members
                                }
                                    |> Ok
                                    |> Server_YouJoinedGuildByInvite
                                    |> ServerChange
                                    |> ChangeBroadcast
                                    |> Lamdera.sendToFrontends sessionId

                            _ ->
                                Command.none
                        ]
                    )

                ( _, Err () ) ->
                    ( model
                    , Err AlreadyJoined
                        |> Server_YouJoinedGuildByInvite
                        |> ServerChange
                        |> ChangeBroadcast
                        |> Lamdera.sendToFrontends sessionId
                    )

                ( Nothing, _ ) ->
                    ( model
                    , Err InviteIsInvalid
                        |> Server_YouJoinedGuildByInvite
                        |> ServerChange
                        |> ChangeBroadcast
                        |> Lamdera.sendToFrontends sessionId
                    )

        Nothing ->
            ( model, Command.none )


twoFactorAuthenticationUpdateFromFrontend :
    ClientId
    -> Time.Posix
    -> TwoFactorAuthentication.ToBackend
    -> BackendModel
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
twoFactorAuthenticationUpdateFromFrontend clientId time toBackend model { userId } user =
    case toBackend of
        TwoFactorAuthentication.EnableTwoFactorAuthenticationRequest ->
            let
                ( model2, secret ) =
                    SecretId.getUniqueId time model
            in
            case user.email of
                RegisteredDirectly email ->
                    case TwoFactorAuthentication.getConfig (EmailAddress.toString email) secret of
                        Ok key ->
                            ( { model2
                                | twoFactorAuthenticationSetup =
                                    SeqDict.insert
                                        userId
                                        { startedAt = time, secret = secret }
                                        model2.twoFactorAuthenticationSetup
                              }
                            , TwoFactorAuthentication.EnableTwoFactorAuthenticationResponse
                                { qrCodeUrl =
                                    TOTP.Key.toString key
                                        -- https://github.com/choonkeat/elm-totp/issues/3
                                        |> String.replace "%3D" ""
                                }
                                |> TwoFactorAuthenticationToFrontend
                                |> Lamdera.sendToFrontend clientId
                            )

                        Err _ ->
                            ( model2, Command.none )

                RegisteredFromDiscord ->
                    ( model2, Command.none )

                RegisteredFromSlack ->
                    ( model2, Command.none )

        TwoFactorAuthentication.ConfirmTwoFactorAuthenticationRequest code ->
            case SeqDict.get userId model.twoFactorAuthenticationSetup of
                Just data ->
                    if Duration.from data.startedAt time |> Quantity.lessThan Duration.hour then
                        if TwoFactorAuthentication.isValidCode time code data.secret then
                            ( { model
                                | twoFactorAuthentication =
                                    SeqDict.insert
                                        userId
                                        { finishedAt = time, secret = data.secret }
                                        model.twoFactorAuthentication
                                , twoFactorAuthenticationSetup =
                                    SeqDict.remove userId model.twoFactorAuthenticationSetup
                              }
                            , TwoFactorAuthentication.ConfirmTwoFactorAuthenticationResponse code True
                                |> TwoFactorAuthenticationToFrontend
                                |> Lamdera.sendToFrontend clientId
                            )

                        else
                            ( model
                            , TwoFactorAuthentication.ConfirmTwoFactorAuthenticationResponse code False
                                |> TwoFactorAuthenticationToFrontend
                                |> Lamdera.sendToFrontend clientId
                            )

                    else
                        ( model, Command.none )

                Nothing ->
                    ( model, Command.none )


adminChangeUpdate :
    ClientId
    -> ChangeId
    -> Pages.Admin.AdminChange
    -> BackendModel
    -> Time.Posix
    -> Id UserId
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
adminChangeUpdate clientId changeId adminChange model time userId user =
    let
        localMsg =
            Local_Admin adminChange
    in
    case adminChange of
        Pages.Admin.ChangeUsers changes ->
            case Pages.Admin.applyChangesToBackendUsers userId changes model.users of
                Ok newUsers ->
                    let
                        model2 : BackendModel
                        model2 =
                            Log.addLog time (Log.ChangedUsers userId) model
                    in
                    ( { model2
                        | users = newUsers
                        , sessions =
                            SeqDict.filter
                                (\_ session -> SeqSet.member session.userId changes.deletedUsers |> not)
                                model2.sessions
                      }
                    , Command.batch
                        [ Pages.Admin.ChangeUsers { changes | time = time }
                            |> Local_Admin
                            |> LocalChangeResponse changeId
                            |> Lamdera.sendToFrontend clientId
                        , Broadcast.toOtherAdmins clientId model2 (LocalChange userId localMsg)
                        ]
                    )

                Err _ ->
                    ( model, invalidChangeResponse changeId clientId )

        Pages.Admin.ExpandSection section ->
            ( { model
                | users =
                    NonemptyDict.insert
                        userId
                        { user | expandedSections = SeqSet.insert section user.expandedSections }
                        model.users
              }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.CollapseSection section ->
            ( { model
                | users =
                    NonemptyDict.insert
                        userId
                        { user | expandedSections = SeqSet.remove section user.expandedSections }
                        model.users
              }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.LogPageChanged logPageIndex ->
            ( { model
                | users = NonemptyDict.insert userId { user | lastLogPageViewed = logPageIndex } model.users
              }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        Pages.Admin.SetEmailNotificationsEnabled isEnabled ->
            let
                model2 =
                    { model | emailNotificationsEnabled = isEnabled }
            in
            ( model2
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Broadcast.toOtherAdmins clientId model2 (LocalChange userId localMsg)
                ]
            )

        Pages.Admin.SetDiscordBotToken maybeBotToken ->
            ( { model | botToken = maybeBotToken, discordModel = Discord.init }
            , Command.batch
                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                , case maybeBotToken of
                    Just botToken ->
                        Task.map2
                            Tuple.pair
                            (Discord.getCurrentUser (DiscordSync.botTokenToAuth botToken))
                            (Discord.getCurrentUserGuilds (DiscordSync.botTokenToAuth botToken))
                            |> Task.attempt (GotCurrentUserGuilds time botToken)

                    Nothing ->
                        Command.none
                , case ( maybeBotToken, model.discordModel.websocketHandle ) of
                    ( Nothing, Just handle ) ->
                        Websocket.close handle |> Task.perform (\() -> WebsocketClosedByBackend False)

                    ( Nothing, Nothing ) ->
                        Command.none

                    ( Just _, _ ) ->
                        Websocket.createHandle WebsocketCreatedHandle Discord.websocketGatewayUrl

                --, broadcastToOtherAdmins clientId model (Server_SetWebsocketToggled isEnabled |> ServerChange)
                ]
            )

        Pages.Admin.SetPrivateVapidKey privateKey ->
            ( { model
                | privateVapidKey = privateKey
                , sessions = SeqDict.map (\_ session -> { session | pushSubscription = NotSubscribed }) model.sessions
              }
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Server_PushNotificationsReset model.publicVapidKey
                    |> ServerChange
                    |> ChangeBroadcast
                    |> Lamdera.broadcast
                ]
            )

        Pages.Admin.SetPublicVapidKey publicKey ->
            ( { model
                | publicVapidKey = publicKey
                , sessions = SeqDict.map (\_ session -> { session | pushSubscription = NotSubscribed }) model.sessions
              }
            , Command.batch
                [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                , Server_PushNotificationsReset model.publicVapidKey
                    |> ServerChange
                    |> ChangeBroadcast
                    |> Lamdera.broadcast
                ]
            )

        Pages.Admin.SetSlackClientSecret clientSecret ->
            ( { model | slackClientSecret = clientSecret }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )


sendDirectMessage :
    BackendModel
    -> Time.Posix
    -> ClientId
    -> ChangeId
    -> Id UserId
    -> ThreadRouteWithMaybeMessage
    -> Nonempty RichText
    -> SeqDict (Id FileId) FileData
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendDirectMessage model time clientId changeId otherUserId threadRouteWithReplyTo text attachedFiles { userId } user =
    let
        dmChannelId : DmChannelId
        dmChannelId =
            DmChannel.channelIdFromUserIds userId otherUserId

        dmChannel : DmChannel
        dmChannel =
            SeqDict.get dmChannelId model.dmChannels
                |> Maybe.withDefault DmChannel.init
    in
    case threadRouteWithReplyTo of
        ViewThreadWithMaybeMessage threadMessageIndex _ ->
            let
                thread : Thread
                thread =
                    SeqDict.get threadMessageIndex dmChannel.threads |> Maybe.withDefault DmChannel.threadInit
            in
            ( { model
                | dmChannels = SeqDict.insert dmChannelId dmChannel model.dmChannels
                , users =
                    NonemptyDict.insert
                        userId
                        { user
                            | lastViewedThreads =
                                SeqDict.insert
                                    ( GuildOrDmId_Dm otherUserId, threadMessageIndex )
                                    (DmChannel.latestThreadMessageId thread)
                                    user.lastViewedThreads
                        }
                        model.users
              }
            , if userId == otherUserId then
                Command.none

              else
                Broadcast.broadcastDm changeId time clientId userId otherUserId text threadRouteWithReplyTo attachedFiles model
            )

        NoThreadWithMaybeMessage repliedTo ->
            let
                messageIndex : Id ChannelMessageId
                messageIndex =
                    DmChannel.latestMessageId dmChannel2

                dmChannel2 : DmChannel
                dmChannel2 =
                    LocalState.createChannelMessageBackend
                        Nothing
                        (UserTextMessage
                            { createdAt = time
                            , createdBy = userId
                            , content = text
                            , reactions = SeqDict.empty
                            , editedAt = Nothing
                            , repliedTo = repliedTo
                            , attachedFiles = attachedFiles
                            }
                        )
                        dmChannel
            in
            ( { model
                | dmChannels = SeqDict.insert dmChannelId dmChannel2 model.dmChannels
                , users =
                    NonemptyDict.insert
                        userId
                        { user
                            | lastViewed = SeqDict.insert (GuildOrDmId_Dm otherUserId) messageIndex user.lastViewed
                        }
                        model.users
              }
            , Command.batch
                [ Broadcast.broadcastDm changeId time clientId userId otherUserId text threadRouteWithReplyTo attachedFiles model
                , case ( OneToOne.first dmChannelId model.discordDms, model.botToken ) of
                    ( Just discordChannelId, Just botToken ) ->
                        Discord.createMessage
                            (DiscordSync.botTokenToAuth botToken)
                            { channelId = discordChannelId
                            , content = toDiscordContent model attachedFiles text
                            , replyTo =
                                case repliedTo of
                                    Just index ->
                                        case OneToOne.first index dmChannel2.linkedMessageIds of
                                            Just (DiscordMessageId replyTo) ->
                                                Just replyTo

                                            _ ->
                                                Nothing

                                    Nothing ->
                                        Nothing
                            }
                            |> Task.attempt (SentDirectMessageToDiscord dmChannelId messageIndex)

                    _ ->
                        Command.none
                ]
            )


validateAttachedFiles : SeqDict FileHash BackendFileData -> SeqDict (Id FileId) FileData -> SeqDict (Id FileId) FileData
validateAttachedFiles uploadedFiles dict =
    SeqDict.filterMap
        (\id fileData ->
            if Id.toInt id < 1 then
                Nothing

            else
                case SeqDict.get fileData.fileHash uploadedFiles of
                    Just { fileSize } ->
                        Just { fileData | fileSize = fileSize }

                    Nothing ->
                        Nothing
        )
        dict


sendGuildMessage :
    BackendModel
    -> Time.Posix
    -> ClientId
    -> ChangeId
    -> Id GuildId
    -> Id ChannelId
    -> ThreadRouteWithMaybeMessage
    -> Nonempty RichText
    -> SeqDict (Id FileId) FileData
    -> UserSession
    -> BackendUser
    -> BackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendGuildMessage model time clientId changeId guildId channelId threadRouteWithMaybeReplyTo text attachedFiles { userId } user guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            let
                channel2 : BackendChannel
                channel2 =
                    case threadRouteWithMaybeReplyTo of
                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                            LocalState.createThreadMessageBackend
                                Nothing
                                threadId
                                (UserTextMessage
                                    { createdAt = time
                                    , createdBy = userId
                                    , content = text
                                    , reactions = SeqDict.empty
                                    , editedAt = Nothing
                                    , repliedTo = maybeReplyTo
                                    , attachedFiles = attachedFiles
                                    }
                                )
                                channel

                        NoThreadWithMaybeMessage maybeReplyTo ->
                            LocalState.createChannelMessageBackend
                                Nothing
                                (UserTextMessage
                                    { createdAt = time
                                    , createdBy = userId
                                    , content = text
                                    , reactions = SeqDict.empty
                                    , editedAt = Nothing
                                    , repliedTo = maybeReplyTo
                                    , attachedFiles = attachedFiles
                                    }
                                )
                                channel

                guildOrDmId : GuildOrDmIdNoThread
                guildOrDmId =
                    GuildOrDmId_Guild guildId channelId

                threadRouteNoReply : ThreadRoute
                threadRouteNoReply =
                    case threadRouteWithMaybeReplyTo of
                        ViewThreadWithMaybeMessage threadId _ ->
                            ViewThread threadId

                        NoThreadWithMaybeMessage _ ->
                            NoThread

                usersMentioned : SeqSet (Id UserId)
                usersMentioned =
                    LocalState.usersMentionedOrRepliedToBackend
                        threadRouteWithMaybeReplyTo
                        text
                        (guild.owner :: SeqDict.keys guild.members)
                        channel2

                users2 : NonemptyDict (Id UserId) BackendUser
                users2 =
                    SeqSet.foldl
                        (\userId2 users ->
                            let
                                isViewing =
                                    Broadcast.userGetAllSessions userId2 model
                                        |> List.any
                                            (\( _, userSession ) ->
                                                userSession.currentlyViewing == Just ( guildOrDmId, threadRouteNoReply )
                                            )
                            in
                            if isViewing then
                                users

                            else
                                NonemptyDict.updateIfExists
                                    userId2
                                    (User.addDirectMention guildId channelId threadRouteNoReply)
                                    users
                        )
                        model.users
                        usersMentioned
            in
            ( { model
                | guilds =
                    SeqDict.insert
                        guildId
                        { guild | channels = SeqDict.insert channelId channel2 guild.channels }
                        model.guilds
                , users =
                    NonemptyDict.insert
                        userId
                        (case threadRouteWithMaybeReplyTo of
                            ViewThreadWithMaybeMessage threadMessageIndex _ ->
                                { user
                                    | lastViewedThreads =
                                        SeqDict.insert
                                            ( guildOrDmId, threadMessageIndex )
                                            (SeqDict.get threadMessageIndex channel2.threads
                                                |> Maybe.withDefault DmChannel.threadInit
                                                |> DmChannel.latestThreadMessageId
                                            )
                                            user.lastViewedThreads
                                }

                            NoThreadWithMaybeMessage _ ->
                                { user
                                    | lastViewed =
                                        SeqDict.insert
                                            guildOrDmId
                                            (DmChannel.latestMessageId channel2)
                                            user.lastViewed
                                }
                        )
                        users2
              }
            , Command.batch
                [ LocalChangeResponse
                    changeId
                    (Local_SendMessage time guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles)
                    |> Lamdera.sendToFrontend clientId
                , Broadcast.toGuildExcludingOne
                    clientId
                    guildId
                    (Server_SendMessage userId time guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles
                        |> ServerChange
                    )
                    model
                , Broadcast.messageNotification
                    usersMentioned
                    time
                    userId
                    guildOrDmId
                    threadRouteNoReply
                    text
                    (guild.owner :: SeqDict.keys guild.members)
                    model
                , case ( model.botToken, threadRouteWithMaybeReplyTo ) of
                    ( Just botToken, ViewThreadWithMaybeMessage threadMessageIndex maybeRepliedTo ) ->
                        let
                            thread : Thread
                            thread =
                                SeqDict.get threadMessageIndex channel2.threads
                                    |> Maybe.withDefault DmChannel.threadInit
                        in
                        case
                            ( OneToOne.first threadMessageIndex channel2.linkedThreadIds
                            , OneToOne.first threadMessageIndex channel2.linkedMessageIds
                            , OneToOne.first channelId guild.linkedChannelIds
                            )
                        of
                            ( Nothing, Just (DiscordMessageId discordMessageId), Just (DiscordChannelId discordChannelId) ) ->
                                Discord.startThreadFromMessage
                                    (DiscordSync.botTokenToAuth botToken)
                                    { name = "New thread"
                                    , channelId = discordChannelId
                                    , messageId = discordMessageId
                                    , autoArchiveDuration = Missing
                                    , rateLimitPerUser = Missing
                                    }
                                    |> Task.andThen
                                        (\discordThread ->
                                            Discord.createMessage
                                                (DiscordSync.botTokenToAuth botToken)
                                                { channelId = discordThread.id
                                                , content = toDiscordContent model attachedFiles text
                                                , replyTo = Nothing
                                                }
                                        )
                                    |> Task.attempt
                                        (SentGuildMessageToDiscord
                                            guildId
                                            channelId
                                            (DmChannel.latestThreadMessageId thread
                                                |> ViewThreadWithMessage threadMessageIndex
                                            )
                                        )

                            ( Just (DiscordChannelId discordThreadId), _, _ ) ->
                                Discord.createMessage
                                    (DiscordSync.botTokenToAuth botToken)
                                    { channelId = discordThreadId
                                    , content = toDiscordContent model attachedFiles text
                                    , replyTo =
                                        case maybeRepliedTo of
                                            Just index ->
                                                case OneToOne.first index thread.linkedMessageIds of
                                                    Just (DiscordMessageId replyTo) ->
                                                        Just replyTo

                                                    _ ->
                                                        Nothing

                                            Nothing ->
                                                Nothing
                                    }
                                    |> Task.attempt
                                        (DmChannel.latestThreadMessageId thread
                                            |> ViewThreadWithMessage threadMessageIndex
                                            |> SentGuildMessageToDiscord guildId channelId
                                        )

                            _ ->
                                Command.none

                    ( Just botToken, NoThreadWithMaybeMessage maybeRepliedTo ) ->
                        case OneToOne.first channelId guild.linkedChannelIds of
                            Just (DiscordChannelId discordChannelId) ->
                                Discord.createMessage
                                    (DiscordSync.botTokenToAuth botToken)
                                    { channelId = discordChannelId
                                    , content = toDiscordContent model attachedFiles text
                                    , replyTo =
                                        case maybeRepliedTo of
                                            Just index ->
                                                case OneToOne.first index channel2.linkedMessageIds of
                                                    Just (DiscordMessageId replyTo) ->
                                                        Just replyTo

                                                    _ ->
                                                        Nothing

                                            Nothing ->
                                                Nothing
                                    }
                                    |> Task.attempt
                                        (SentGuildMessageToDiscord
                                            guildId
                                            channelId
                                            (NoThreadWithMessage (DmChannel.latestMessageId channel2))
                                        )

                            _ ->
                                Command.none

                    _ ->
                        Command.none
                ]
            )

        Nothing ->
            ( model
            , invalidChangeResponse changeId clientId
            )


invalidChangeResponse : ChangeId -> ClientId -> Command BackendOnly ToFrontend backendMsg
invalidChangeResponse changeId clientId =
    LocalChangeResponse changeId Local_Invalid
        |> Lamdera.sendToFrontend clientId


shouldRateLimit : Time.Posix -> BackendUser -> Bool
shouldRateLimit time user =
    let
        loginsInLast5Minutes : Int
        loginsInLast5Minutes =
            List.Extra.count
                (\loginTime -> Duration.from loginTime time |> Quantity.lessThan (Duration.minutes 5))
                user.recentLoginEmails

        loginsInLast120Minutes : Int
        loginsInLast120Minutes =
            List.Extra.count
                (\loginTime -> Duration.from loginTime time |> Quantity.lessThan (Duration.minutes 120))
                user.recentLoginEmails
    in
    loginsInLast5Minutes > 5 || loginsInLast120Minutes > 10


updateFromFrontendAdmin :
    ClientId
    -> Pages.Admin.ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontendAdmin clientId toBackend model =
    case toBackend of
        Pages.Admin.LogPaginationToBackend a ->
            ( model
            , Pagination.updateFromFrontend clientId a model.logs
                |> Command.map
                    (\toMsg -> Pages.Admin.LogPaginationToFrontend toMsg |> AdminToFrontend)
                    identity
            )


asUser :
    BackendModel
    -> SessionId
    -> (UserSession -> BackendUser -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asUser model sessionId func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case NonemptyDict.get session.userId model.users of
                Just user ->
                    func session user

                Nothing ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asGuildMember :
    BackendModel
    -> SessionId
    -> Id GuildId
    -> (UserSession -> BackendUser -> BackendGuild -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asGuildMember model sessionId guildId func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case ( NonemptyDict.get session.userId model.users, SeqDict.get guildId model.guilds ) of
                ( Just user, Just guild ) ->
                    func session user guild

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asGuildOwner :
    BackendModel
    -> SessionId
    -> Id GuildId
    -> (Id UserId -> BackendUser -> BackendGuild -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asGuildOwner model sessionId guildId func =
    asGuildMember model
        sessionId
        guildId
        (\{ userId } user guild ->
            if userId == guild.owner then
                func userId user guild

            else
                ( model, Command.none )
        )


asAdmin :
    BackendModel
    -> SessionId
    -> (Id UserId -> BackendUser -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asAdmin model sessionId func =
    asUser
        model
        sessionId
        (\{ userId } user ->
            if user.isAdmin then
                func userId user

            else
                ( model, Command.none )
        )


getLoginCode : Time.Posix -> { a | secretCounter : Int } -> ( { a | secretCounter : Int }, Result () Int )
getLoginCode time model =
    let
        ( model2, id ) =
            SecretId.getUniqueId time model
    in
    ( model2
    , case String.left LoginForm.loginCodeLength (SecretId.toString id) |> Hex.fromString of
        Ok int ->
            case String.fromInt int |> String.left LoginForm.loginCodeLength |> String.toInt of
                Just int2 ->
                    Ok int2

                Nothing ->
                    Err ()

        Err _ ->
            Err ()
    )


sendLoginEmail :
    (Result Postmark.SendEmailError () -> backendMsg)
    -> EmailAddress
    -> Int
    -> Command BackendOnly toFrontend backendMsg
sendLoginEmail msg emailAddress loginCode =
    let
        _ =
            Debug.log "login" (String.padLeft LoginForm.loginCodeLength '0' (String.fromInt loginCode))
    in
    { from = { name = "", email = Env.noReplyEmailAddress }
    , to = List.Nonempty.fromElement { name = "", email = emailAddress }
    , subject = loginEmailSubject
    , body =
        Postmark.BodyBoth
            (loginEmailContent loginCode)
            ("Here is your code " ++ String.fromInt loginCode ++ "\n\nPlease type it in the login page you were previously on.\n\nIf you weren't expecting this email you can safely ignore it.")
    , messageStream = "outbound"
    }
        |> Postmark.sendEmail msg Env.postmarkServerToken


loginEmailContent : Int -> Email.Html.Html
loginEmailContent loginCode =
    Email.Html.div
        [ Email.Html.Attributes.padding "8px" ]
        [ Email.Html.div [] [ Email.Html.text "Here is your code." ]
        , Email.Html.div
            [ Email.Html.Attributes.fontSize "36px"
            , Email.Html.Attributes.fontFamily "monospace"
            ]
            (String.fromInt loginCode
                |> String.toList
                |> List.map
                    (\char ->
                        Email.Html.span
                            [ Email.Html.Attributes.padding "0px 3px 0px 4px" ]
                            [ Email.Html.text (String.fromChar char) ]
                    )
                |> (\a ->
                        List.take (LoginForm.loginCodeLength // 2) a
                            ++ [ Email.Html.span
                                    [ Email.Html.Attributes.backgroundColor "black"
                                    , Email.Html.Attributes.padding "0px 4px 0px 5px"
                                    , Email.Html.Attributes.style "vertical-align" "middle"
                                    , Email.Html.Attributes.fontSize "2px"
                                    ]
                                    []
                               ]
                            ++ List.drop (LoginForm.loginCodeLength // 2) a
                   )
            )
        , Email.Html.text "Please type it in the login page you were previously on."
        , Email.Html.br [] []
        , Email.Html.br [] []
        , Email.Html.text "If you weren't expecting this email you can safely ignore it."
        ]


loginEmailSubject : NonemptyString
loginEmailSubject =
    NonemptyString 'L' "ogin code"


isLoginTooOld : { a | loginAttempts : number, creationTime : Time.Posix } -> Time.Posix -> Bool
isLoginTooOld pendingLogin time =
    (pendingLogin.loginAttempts < LoginForm.maxLoginAttempts)
        && (Duration.from pendingLogin.creationTime time |> Quantity.lessThan Duration.hour)


loginWithToken :
    Time.Posix
    -> SessionId
    -> ClientId
    -> Int
    -> Maybe ( GuildOrDmIdNoThread, ThreadRoute )
    -> UserAgent
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
loginWithToken time sessionId clientId loginCode requestMessagesFor userAgent model =
    case SeqDict.get sessionId model.pendingLogins of
        Just (WaitingForLoginToken pendingLogin) ->
            if isLoginTooOld pendingLogin time then
                if loginCode == pendingLogin.loginCode then
                    case
                        ( NonemptyDict.get pendingLogin.userId model.users
                        , SeqDict.get pendingLogin.userId model.twoFactorAuthentication
                        )
                    of
                        ( Just _, Just _ ) ->
                            ( { model
                                | pendingLogins =
                                    SeqDict.insert
                                        sessionId
                                        (WaitingForTwoFactorToken
                                            { creationTime = pendingLogin.creationTime
                                            , userId = pendingLogin.userId
                                            , loginAttempts = 0
                                            }
                                        )
                                        model.pendingLogins
                              }
                            , NeedsTwoFactorToken
                                |> LoginWithTokenResponse
                                |> Lamdera.sendToFrontends sessionId
                            )

                        ( Just user, Nothing ) ->
                            let
                                session : UserSession
                                session =
                                    UserSession.init pendingLogin.userId requestMessagesFor userAgent
                            in
                            ( { model
                                | sessions = SeqDict.insert sessionId session model.sessions
                                , pendingLogins = SeqDict.remove sessionId model.pendingLogins
                              }
                            , Command.batch
                                [ getLoginData sessionId session user requestMessagesFor model
                                    |> LoginSuccess
                                    |> LoginWithTokenResponse
                                    |> Lamdera.sendToFrontends sessionId
                                , Broadcast.toUser
                                    (Just clientId)
                                    Nothing
                                    pendingLogin.userId
                                    (Server_NewSession
                                        sessionId
                                        { notificationMode = session.notificationMode
                                        , currentlyViewing = session.currentlyViewing
                                        , userAgent = session.userAgent
                                        }
                                        |> ServerChange
                                    )
                                    model
                                ]
                            )

                        ( Nothing, _ ) ->
                            ( model
                            , LoginTokenInvalid loginCode
                                |> LoginWithTokenResponse
                                |> Lamdera.sendToFrontend clientId
                            )

                else
                    ( { model
                        | pendingLogins =
                            SeqDict.insert
                                sessionId
                                (WaitingForLoginToken { pendingLogin | loginAttempts = pendingLogin.loginAttempts + 1 })
                                model.pendingLogins
                      }
                    , LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId
                    )

            else
                ( model, LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId )

        Just (WaitingForLoginTokenForSignup pendingLogin) ->
            if isLoginTooOld pendingLogin time then
                if loginCode == pendingLogin.loginCode then
                    ( { model
                        | pendingLogins =
                            SeqDict.insert
                                sessionId
                                (WaitingForUserDataForSignup
                                    { creationTime = pendingLogin.creationTime
                                    , emailAddress = pendingLogin.emailAddress
                                    }
                                )
                                model.pendingLogins
                      }
                    , LoginWithTokenResponse NeedsAccountSetup |> Lamdera.sendToFrontends sessionId
                    )

                else
                    ( { model
                        | pendingLogins =
                            SeqDict.insert
                                sessionId
                                (WaitingForLoginTokenForSignup
                                    { pendingLogin | loginAttempts = pendingLogin.loginAttempts + 1 }
                                )
                                model.pendingLogins
                      }
                    , LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId
                    )

            else
                ( model, LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId )

        _ ->
            ( model, LoginTokenInvalid loginCode |> LoginWithTokenResponse |> Lamdera.sendToFrontend clientId )


addLogWithCmd :
    Time.Posix
    -> Log
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
addLogWithCmd time log model cmd =
    let
        ( model2, logCmd ) =
            addLog time log model
    in
    ( model2, Command.batch [ logCmd, cmd ] )


addLog : Time.Posix -> Log -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
addLog time log model =
    let
        model2 : BackendModel
        model2 =
            { model | logs = Array.push { time = time, log = log } model.logs }
    in
    case
        ( Log.shouldNotifyAdmin log
        , Duration.from model2.lastErrorLogEmail time |> Quantity.lessThan (Duration.minutes 30)
        )
    of
        ( Just text, False ) ->
            ( { model2 | lastErrorLogEmail = time }
            , Postmark.sendEmailTask
                Env.postmarkServerToken
                { from = { name = "", email = Env.noReplyEmailAddress }
                , to = Nonempty { name = "", email = emailToNotifyWhenErrorsAreLogged } []
                , subject = NonemptyString 'A' "n error was logged that needs attention"
                , body = "The following error was logged: " ++ text ++ ". Note that any additional errors logged for the next 30 minutes will be ignored to avoid spamming emails." |> Postmark.BodyText
                , messageStream = "outbound"
                }
                |> Task.attempt (SentLogErrorEmail time emailToNotifyWhenErrorsAreLogged)
            )

        _ ->
            ( model2, Command.none )


emailToNotifyWhenErrorsAreLogged : EmailAddress
emailToNotifyWhenErrorsAreLogged =
    Unsafe.emailAddress "martinsstewart@gmail.com"
