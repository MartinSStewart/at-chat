module Backend exposing
    ( adminUser
    , app
    , app_
    , emailToNotifyWhenErrorsAreLogged
    , getUserFromSessionId
    , loginEmailContent
    , loginEmailSubject
    )

import AiChat
import Array
import ChannelName
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Discord exposing (OptionalData(..))
import Discord.Id
import Discord.Markdown
import DmChannel exposing (DmChannel, DmChannelId)
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Process as Process
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Effect.Websocket as Websocket
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import FileStatus exposing (FileData, FileHash, FileId)
import GuildName
import Hex
import Id exposing (ChannelId, GuildId, GuildOrDmId(..), Id, InviteLinkId, ThreadRoute(..), UserId)
import Lamdera as LamderaCore
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId)
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), DiscordBotToken(..), JoinGuildError(..))
import Log exposing (Log)
import LoginForm
import Message exposing (Message(..))
import NonemptyDict
import OneToOne
import Pages.Admin exposing (InitAdminData)
import Pagination
import PersonName
import Postmark
import Quantity
import RichText exposing (RichText)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet
import String.Nonempty exposing (NonemptyString(..))
import TOTP.Key
import TwoFactorAuthentication
import Types exposing (AdminStatusLoginData(..), BackendFileData, BackendModel, BackendMsg(..), LastRequest(..), LocalChange(..), LocalMsg(..), LoginData, LoginResult(..), LoginTokenData(..), ServerChange(..), ToBackend(..), ToBeFilledInByBackend(..), ToFrontend(..))
import UInt64
import Unsafe
import User exposing (BackendUser, EmailStatus(..))


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


adminUserId : Id UserId
adminUserId =
    Id.fromInt 0


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
            , createdBy = adminUserId
            , name = Unsafe.guildName "First guild"
            , icon = Nothing
            , channels =
                SeqDict.fromList
                    [ ( Id.fromInt 0
                      , { createdAt = Time.millisToPosix 0
                        , createdBy = adminUserId
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
                        , createdBy = adminUserId
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
            , owner = adminUserId
            , invites = SeqDict.empty
            }
    in
    ( { users =
            Nonempty ( adminUserId, adminUser ) []
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
      , guilds =
            SeqDict.fromList
                [ ( Id.fromInt 0
                  , guild
                  )
                ]
      , discordModel = Discord.init
      , discordNotConnected = True
      , discordGuilds = OneToOne.empty
      , discordUsers = OneToOne.empty
      , discordBotId = Nothing
      , dmChannels = SeqDict.empty
      , discordDms = OneToOne.empty
      , botToken = Nothing
      , files = SeqDict.empty
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


loadImage : String -> Task restriction x (Maybe ( FileHash, Maybe (Coord units) ))
loadImage url =
    Http.task
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , resolver =
            Http.bytesResolver
                (\result2 ->
                    case result2 of
                        Http.GoodStatus_ _ body ->
                            Ok (Just body)

                        _ ->
                            Ok Nothing
                )
        , timeout = Just (Duration.seconds 30)
        }
        |> Task.andThen
            (\maybeBytes ->
                case maybeBytes of
                    Just bytes ->
                        FileStatus.uploadBytes Env.secretKey bytes
                            |> Task.map Just
                            |> Task.onError (\_ -> Task.succeed Nothing)

                    Nothing ->
                        Task.succeed Nothing
            )


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
            case model.botToken of
                Just botToken ->
                    let
                        ( discordModel2, outMsgs ) =
                            Discord.update (botTokenToAuth botToken) discordMsg model.discordModel
                    in
                    List.foldl
                        (\outMsg ( model2, cmds ) ->
                            case outMsg of
                                Discord.CloseAndReopenHandle connection ->
                                    ( model2
                                    , Task.perform (\() -> WebsocketClosedByBackend True) (Websocket.close connection)
                                        :: cmds
                                    )

                                Discord.OpenHandle ->
                                    ( model2
                                    , Websocket.createHandle WebsocketCreatedHandle Discord.websocketGatewayUrl
                                        :: cmds
                                    )

                                Discord.SendWebsocketData connection data ->
                                    ( model2
                                    , Task.attempt WebsocketSentData (Websocket.sendString connection data)
                                        :: cmds
                                    )

                                Discord.SendWebsocketDataWithDelay connection duration data ->
                                    ( model2
                                    , (Process.sleep duration
                                        |> Task.andThen (\() -> Websocket.sendString connection data)
                                        |> Task.attempt WebsocketSentData
                                      )
                                        :: cmds
                                    )

                                Discord.UserCreatedMessage channelType message ->
                                    let
                                        _ =
                                            Debug.log "created message" ( ( Discord.Id.toString message.id, channelType, message.type_ ), message.content, Discord.Id.toString message.channelId )

                                        ( model3, cmd2 ) =
                                            handleDiscordCreateMessage channelType message model2
                                    in
                                    ( model3, cmd2 :: cmds )

                                Discord.UserDeletedMessage discordGuildId discordChannelId messageId ->
                                    let
                                        ( model3, cmd2 ) =
                                            handleDiscordDeleteMessage discordGuildId discordChannelId messageId model2
                                    in
                                    ( model3, cmd2 :: cmds )

                                Discord.UserEditedMessage messageUpdate ->
                                    let
                                        ( model3, cmd2 ) =
                                            handleDiscordEditMessage messageUpdate model2
                                    in
                                    ( model3, cmd2 :: cmds )

                                Discord.FailedToParseWebsocketMessage error ->
                                    let
                                        _ =
                                            Debug.log "gateway error" error
                                    in
                                    ( model2, cmds )

                                Discord.ThreadCreatedOrUserAddedToThread _ ->
                                    ( model2, cmds )
                         --( handleDiscordThreadCreated channel model2, cmds )
                        )
                        ( { model | discordModel = discordModel2 }, [] )
                        outMsgs
                        |> Tuple.mapSecond Command.batch

                Nothing ->
                    ( model, Command.none )

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
                    ( addDiscordUsers time (SeqDict.remove botUserId users) model
                        |> addDiscordGuilds time (SeqDict.fromList data)
                    , List.map
                        (\guildMember ->
                            Task.map
                                (\maybeAvatar -> ( guildMember.user.id, maybeAvatar ))
                                (case guildMember.user.avatar of
                                    Just avatar ->
                                        loadImage
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

        GotCurrentUserGuilds time botToken result ->
            case result of
                Ok ( botUser, guilds ) ->
                    let
                        botToken2 =
                            botTokenToAuth botToken
                    in
                    ( { model
                        | discordBotId = Just botUser.id
                        , discordUsers = OneToOne.insert botUser.id adminUserId model.discordUsers
                      }
                    , List.map
                        (\partialGuild ->
                            Task.map5
                                (\guild members channels maybeIcon threads ->
                                    ( guild.id
                                    , { guild = guild
                                      , members = members
                                      , channels = channels
                                      , icon = maybeIcon
                                      , threads = threads
                                      }
                                    )
                                )
                                (Discord.getGuild botToken2 partialGuild.id)
                                (Discord.listGuildMembers
                                    botToken2
                                    { guildId = partialGuild.id
                                    , limit = 1000
                                    , after = Discord.Missing
                                    }
                                )
                                (Discord.getGuildChannels botToken2 partialGuild.id
                                    |> Task.andThen
                                        (\channels ->
                                            List.map
                                                (\channel ->
                                                    Discord.getMessages
                                                        botToken2
                                                        { channelId = channel.id
                                                        , limit = 100
                                                        , relativeTo = Discord.MostRecent
                                                        }
                                                        |> Task.onError (\_ -> Task.succeed [])
                                                        |> Task.map (Tuple.pair channel)
                                                )
                                                channels
                                                |> Task.sequence
                                        )
                                )
                                (case partialGuild.icon of
                                    Just icon ->
                                        loadImage
                                            (Discord.guildIconUrl
                                                { size = Discord.DefaultImageSize
                                                , imageType = Discord.Choice1 Discord.Png
                                                }
                                                partialGuild.id
                                                icon
                                            )

                                    Nothing ->
                                        Task.succeed Nothing
                                )
                                (Discord.listActiveThreads botToken2 partialGuild.id
                                    |> Task.andThen
                                        (\activeThreads ->
                                            List.map
                                                (\thread ->
                                                    Discord.getMessages
                                                        botToken2
                                                        { channelId = thread.id
                                                        , limit = 100
                                                        , relativeTo = Discord.MostRecent
                                                        }
                                                        |> Task.onError
                                                            (\error ->
                                                                let
                                                                    _ =
                                                                        Debug.log "missing thread messages" error
                                                                in
                                                                Task.succeed []
                                                            )
                                                        |> Task.map (Tuple.pair thread)
                                                )
                                                activeThreads.threads
                                                |> Task.sequence
                                        )
                                )
                        )
                        (if Env.isProduction then
                            guilds

                         else
                            List.filter
                                (\guild ->
                                    Just guild.id == Maybe.map Discord.Id.fromUInt64 (UInt64.fromString "705745250815311942")
                                )
                                guilds
                        )
                        |> Task.sequence
                        |> Task.attempt (GotDiscordGuilds time botUser.id)
                    )

                Err error ->
                    let
                        _ =
                            Debug.log "GotCurrentUserGuilds" error
                    in
                    ( model, Command.none )

        SentGuildMessageToDiscord messageId threadRoute result ->
            case result of
                Ok message ->
                    ( { model
                        | guilds =
                            SeqDict.updateIfExists
                                messageId.guildId
                                (\guild ->
                                    { guild
                                        | channels =
                                            SeqDict.updateIfExists
                                                messageId.channelId
                                                (\channel ->
                                                    case threadRoute of
                                                        ViewThread threadMessageIndex ->
                                                            { channel
                                                                | threads =
                                                                    SeqDict.updateIfExists
                                                                        threadMessageIndex
                                                                        (\thread ->
                                                                            { thread
                                                                                | linkedMessageIds =
                                                                                    OneToOne.insert message.id messageId.messageIndex thread.linkedMessageIds
                                                                            }
                                                                        )
                                                                        channel.threads
                                                            }

                                                        NoThread ->
                                                            { channel
                                                                | linkedMessageIds =
                                                                    OneToOne.insert
                                                                        message.id
                                                                        messageId.messageIndex
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

        SentDirectMessageToDiscord dmChannelId threadRoute messageIndex result ->
            case result of
                Ok message ->
                    ( { model
                        | dmChannels =
                            SeqDict.updateIfExists
                                dmChannelId
                                (\dmChannel ->
                                    case threadRoute of
                                        ViewThread threadMessageIndex ->
                                            { dmChannel
                                                | threads =
                                                    SeqDict.updateIfExists
                                                        threadMessageIndex
                                                        (\thread ->
                                                            { thread
                                                                | linkedMessageIds =
                                                                    OneToOne.insert message.id messageIndex thread.linkedMessageIds
                                                            }
                                                        )
                                                        dmChannel.threads
                                            }

                                        NoThread ->
                                            { dmChannel
                                                | linkedMessageIds =
                                                    OneToOne.insert message.id messageIndex dmChannel.linkedMessageIds
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
                                            NonemptyDict.updateIfExists userId
                                                (\user -> { user | icon = Maybe.map Tuple.first maybeAvatar })
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


getGuildFromDiscordId : Discord.Id.Id Discord.Id.GuildId -> BackendModel -> Maybe ( Id GuildId, BackendGuild )
getGuildFromDiscordId discordGuildId model =
    case OneToOne.second discordGuildId model.discordGuilds of
        Just guildId ->
            case SeqDict.get guildId model.guilds of
                Just guild ->
                    Just ( guildId, guild )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


handleDiscordEditMessage :
    Discord.MessageUpdate
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordEditMessage edit model =
    case getGuildFromDiscordId edit.guildId model of
        Just ( guildId, guild ) ->
            case LocalState.linkedChannel edit.channelId guild of
                Just ( channelId, channel ) ->
                    case
                        ( OneToOne.second edit.id channel.linkedMessageIds
                        , OneToOne.second edit.author.id model.discordUsers
                        )
                    of
                        ( Just messageIndex, Just userId ) ->
                            let
                                richText : Nonempty RichText
                                richText =
                                    RichText.fromDiscord model.discordUsers edit.content
                            in
                            case
                                LocalState.editMessageHelper
                                    edit.timestamp
                                    userId
                                    richText
                                    SeqDict.empty
                                    messageIndex
                                    NoThread
                                    channel
                            of
                                Ok channel2 ->
                                    ( { model
                                        | guilds =
                                            SeqDict.updateIfExists
                                                guildId
                                                (LocalState.updateChannel (\_ -> channel2) channelId)
                                                model.guilds
                                      }
                                    , broadcastToGuild
                                        guildId
                                        (Server_SendEditMessage
                                            edit.timestamp
                                            userId
                                            (GuildOrDmId_Guild guildId channelId NoThread)
                                            messageIndex
                                            richText
                                            SeqDict.empty
                                            |> ServerChange
                                        )
                                        model
                                    )

                                Err _ ->
                                    ( model, Command.none )

                        _ ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


handleDiscordDeleteMessage :
    Discord.Id.Id Discord.Id.GuildId
    -> Discord.Id.Id Discord.Id.ChannelId
    -> Discord.Id.Id Discord.Id.MessageId
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDiscordDeleteMessage discordGuildId discordChannelId messageId model =
    case getGuildFromDiscordId discordGuildId model of
        Just ( guildId, guild ) ->
            case LocalState.linkedChannel discordChannelId guild of
                Just ( channelId, channel ) ->
                    case OneToOne.second messageId channel.linkedMessageIds of
                        Just messageIndex ->
                            case Array.get messageIndex channel.messages of
                                Just (UserTextMessage data) ->
                                    ( { model
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                { guild
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            { channel
                                                                | messages =
                                                                    Array.set
                                                                        messageIndex
                                                                        (DeletedMessage data.createdAt)
                                                                        channel.messages
                                                                , linkedMessageIds =
                                                                    OneToOne.removeFirst
                                                                        messageId
                                                                        channel.linkedMessageIds
                                                            }
                                                            guild.channels
                                                }
                                                model.guilds
                                      }
                                    , broadcastToGuild
                                        guildId
                                        (Server_DiscordDeleteMessage
                                            { guildId = guildId
                                            , channelId = channelId
                                            , messageIndex = messageIndex
                                            }
                                            |> ServerChange
                                        )
                                        model
                                    )

                                _ ->
                                    ( model, Command.none )

                        Nothing ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


addDiscordUsers :
    Time.Posix
    -> SeqDict (Discord.Id.Id Discord.Id.UserId) Discord.GuildMember
    -> BackendModel
    -> BackendModel
addDiscordUsers time newUsers model =
    SeqDict.foldl
        (\discordUserId discordUser model2 ->
            case OneToOne.second discordUserId model2.discordUsers of
                Just _ ->
                    model2

                Nothing ->
                    let
                        userId : Id UserId
                        userId =
                            Id.nextId (NonemptyDict.toSeqDict model2.users)

                        user : BackendUser
                        user =
                            LocalState.createNewUser
                                time
                                (PersonName.fromStringLossy discordUser.user.username)
                                RegisteredFromDiscord
                                False
                    in
                    { model2
                        | discordUsers = OneToOne.insert discordUserId userId model2.discordUsers
                        , users = NonemptyDict.insert userId user model2.users
                    }
        )
        model
        newUsers


addDiscordChannel :
    Time.Posix
    -> Id UserId
    -> BackendModel
    -> SeqDict (Discord.Id.Id Discord.Id.ChannelId) (List ( Discord.Channel, List Discord.Message ))
    -> Int
    -> Discord.Channel2
    -> List Discord.Message
    -> Maybe ( Id ChannelId, BackendChannel )
addDiscordChannel time ownerId model threads index discordChannel messages =
    let
        isTextChannel : Bool
        isTextChannel =
            case discordChannel.type_ of
                Discord.GuildAnnouncement ->
                    True

                Discord.GuildText ->
                    True

                Discord.DirectMessage ->
                    True

                Discord.GuildVoice ->
                    False

                Discord.GroupDirectMessage ->
                    True

                Discord.GuildCategory ->
                    False

                Discord.AnnouncementThread ->
                    True

                Discord.PublicThread ->
                    True

                Discord.PrivateThread ->
                    True

                Discord.GuildStageVoice ->
                    False

                Discord.GuildDirectory ->
                    False

                Discord.GuildForum ->
                    False

                Discord.GuildMedia ->
                    False
    in
    if not (List.any (\a -> a.deny.viewChannel) discordChannel.permissionOverwrites) && isTextChannel then
        let
            channel : BackendChannel
            channel =
                { createdAt = time
                , createdBy = ownerId
                , name =
                    (case discordChannel.name of
                        Included name ->
                            name

                        Missing ->
                            "Channel " ++ String.fromInt index
                    )
                        |> ChannelName.fromStringLossy
                , messages = Array.empty
                , status = ChannelActive
                , lastTypedAt = SeqDict.empty
                , linkedMessageIds = OneToOne.empty
                , threads = SeqDict.empty
                , linkedThreadIds = OneToOne.empty
                }
                    |> addDiscordMessages NoThread messages model
        in
        ( Id.fromInt index
        , List.foldl
            (\( thread, threadMessages ) channel2 ->
                case
                    OneToOne.second
                        (Discord.Id.toUInt64 thread.id |> Discord.Id.fromUInt64)
                        channel2.linkedMessageIds
                of
                    Just messageIndex ->
                        addDiscordMessages (ViewThread messageIndex) threadMessages model channel2

                    Nothing ->
                        channel2
            )
            channel
            (SeqDict.get discordChannel.id threads |> Maybe.withDefault [])
        )
            |> Just

    else
        Nothing


addDiscordMessages : ThreadRoute -> List Discord.Message -> BackendModel -> BackendChannel -> BackendChannel
addDiscordMessages threadRoute messages model channel =
    List.foldr
        (\message channel2 ->
            case ( message.type_, OneToOne.second message.author.id model.discordUsers ) of
                ( Discord.ThreadCreated, Nothing ) ->
                    channel2

                ( Discord.ThreadStarterMessage, Nothing ) ->
                    channel2

                ( _, Just userId ) ->
                    handleDiscordCreateGuildMessageHelper
                        message.id
                        message.channelId
                        threadRoute
                        (discordReplyTo message channel2)
                        userId
                        (RichText.fromDiscord model.discordUsers message.content)
                        message
                        channel2

                _ ->
                    let
                        _ =
                            Debug.log "missing" ( message.author.id, message.author.username )
                    in
                    channel2
        )
        channel
        messages


addDiscordGuilds :
    Time.Posix
    ->
        SeqDict
            (Discord.Id.Id Discord.Id.GuildId)
            { guild : Discord.Guild
            , members : List Discord.GuildMember
            , channels : List ( Discord.Channel2, List Discord.Message )
            , icon : Maybe ( FileHash, Maybe (Coord CssPixels) )
            , threads : List ( Discord.Channel, List Discord.Message )
            }
    -> BackendModel
    -> BackendModel
addDiscordGuilds time guilds model =
    SeqDict.foldl
        (\discordGuildId data model2 ->
            case OneToOne.second discordGuildId model2.discordGuilds of
                Just _ ->
                    model2

                Nothing ->
                    let
                        ownerId : Id UserId
                        ownerId =
                            case OneToOne.second data.guild.ownerId model2.discordUsers of
                                Just ownerId2 ->
                                    ownerId2

                                Nothing ->
                                    let
                                        _ =
                                            Debug.log "missing owner" data.guild.ownerId
                                    in
                                    adminUserId

                        threads : SeqDict (Discord.Id.Id Discord.Id.ChannelId) (List ( Discord.Channel, List Discord.Message ))
                        threads =
                            List.foldl
                                (\a dict ->
                                    case (Tuple.first a).parentId of
                                        Included (Just parentId) ->
                                            SeqDict.update
                                                parentId
                                                (\maybe ->
                                                    case maybe of
                                                        Just list ->
                                                            Just (a :: list)

                                                        Nothing ->
                                                            Just [ a ]
                                                )
                                                dict

                                        _ ->
                                            dict
                                )
                                SeqDict.empty
                                data.threads

                        newGuild : BackendGuild
                        newGuild =
                            { createdAt = time
                            , createdBy = ownerId
                            , name = GuildName.fromStringLossy data.guild.name
                            , icon = Maybe.map Tuple.first data.icon
                            , channels = SeqDict.empty
                            , linkedChannelIds = OneToOne.empty
                            , members =
                                List.filterMap
                                    (\guildMember ->
                                        case OneToOne.second guildMember.user.id model2.discordUsers of
                                            Just userId ->
                                                if userId == ownerId then
                                                    Nothing

                                                else
                                                    Just ( userId, { joinedAt = time } )

                                            Nothing ->
                                                Nothing
                                    )
                                    data.members
                                    |> SeqDict.fromList
                            , owner = ownerId
                            , invites = SeqDict.empty
                            }

                        newGuild2 =
                            List.sortBy
                                (\( channel, _ ) ->
                                    case channel.position of
                                        Included position ->
                                            position

                                        Missing ->
                                            9999
                                )
                                data.channels
                                |> List.indexedMap Tuple.pair
                                |> List.foldl
                                    (\( index, ( discordChannel, messages ) ) guild2 ->
                                        case addDiscordChannel time ownerId model2 threads index discordChannel messages of
                                            Just ( channelId, channel ) ->
                                                { newGuild
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            channel
                                                            guild2.channels
                                                    , linkedChannelIds =
                                                        OneToOne.insert
                                                            discordChannel.id
                                                            channelId
                                                            guild2.linkedChannelIds
                                                }

                                            Nothing ->
                                                guild2
                                    )
                                    newGuild

                        newGuild3 : BackendGuild
                        newGuild3 =
                            LocalState.addMember time adminUserId newGuild2
                                |> Result.withDefault newGuild2

                        guildId : Id GuildId
                        guildId =
                            Id.nextId model2.guilds
                    in
                    { model2
                        | discordGuilds =
                            OneToOne.insert discordGuildId guildId model2.discordGuilds
                        , guilds = SeqDict.insert guildId newGuild3 model2.guilds
                    }
        )
        model
        guilds


handleDiscordCreateMessage :
    Discord.ChannelType
    -> Discord.Message
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend msg )
handleDiscordCreateMessage channelType message model =
    case ( Just message.author.id == model.discordBotId, message.type_ ) of
        ( True, _ ) ->
            ( model, Command.none )

        ( _, Discord.ThreadCreated ) ->
            ( model, Command.none )

        ( _, Discord.ThreadStarterMessage ) ->
            ( model, Command.none )

        _ ->
            case ( OneToOne.second message.author.id model.discordUsers, message.guildId ) of
                ( Just userId, Missing ) ->
                    let
                        richText : Nonempty RichText
                        richText =
                            RichText.fromDiscord model.discordUsers message.content

                        dmChannelId : DmChannelId
                        dmChannelId =
                            DmChannel.channelIdFromUserIds userId adminUserId

                        dmChannel : DmChannel
                        dmChannel =
                            Maybe.withDefault DmChannel.init (SeqDict.get dmChannelId model.dmChannels)

                        replyTo : Maybe Int
                        replyTo =
                            case message.referencedMessage of
                                Discord.Referenced referenced ->
                                    OneToOne.second referenced.id dmChannel.linkedMessageIds

                                Discord.ReferenceDeleted ->
                                    Nothing

                                Discord.NoReference ->
                                    Nothing
                    in
                    ( { model
                        | dmChannels =
                            SeqDict.insert
                                dmChannelId
                                (LocalState.createMessage
                                    (Just ( message.id, message.channelId ))
                                    (UserTextMessage
                                        { createdAt = message.timestamp
                                        , createdBy = userId
                                        , content = richText
                                        , reactions = SeqDict.empty
                                        , editedAt = Nothing
                                        , repliedTo =
                                            case message.referencedMessage of
                                                Discord.Referenced referenced ->
                                                    OneToOne.second referenced.id dmChannel.linkedMessageIds

                                                Discord.ReferenceDeleted ->
                                                    Nothing

                                                Discord.NoReference ->
                                                    Nothing
                                        , attachedFiles = SeqDict.empty
                                        }
                                    )
                                    NoThread
                                    dmChannel
                                )
                                model.dmChannels
                        , discordDms = OneToOne.insert message.channelId dmChannelId model.discordDms
                      }
                    , broadcastToUser
                        Nothing
                        adminUserId
                        (Server_DiscordDirectMessage message.timestamp message.id userId richText replyTo
                            |> ServerChange
                        )
                        model
                    )

                ( Just userId, Included discordGuildId ) ->
                    handleDiscordCreateGuildMessage userId discordGuildId channelType message model

                _ ->
                    let
                        _ =
                            Debug.log "user id not found for message" message
                    in
                    ( model, Command.none )


handleDiscordCreateGuildMessage :
    Id UserId
    -> Discord.Id.Id Discord.Id.GuildId
    -> Discord.ChannelType
    -> Discord.Message
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend msg )
handleDiscordCreateGuildMessage userId discordGuildId channelType message model =
    let
        richText : Nonempty RichText
        richText =
            RichText.fromDiscord model.discordUsers message.content

        maybeData : Maybe { guildId : Id GuildId, guild : BackendGuild, channelId : Id ChannelId, channel : BackendChannel, threadRoute : ThreadRoute }
        maybeData =
            case OneToOne.second discordGuildId model.discordGuilds of
                Just guildId ->
                    case SeqDict.get guildId model.guilds of
                        Just guild ->
                            case LocalState.linkedChannel message.channelId guild of
                                Just ( channelId, channel ) ->
                                    Just
                                        { guildId = guildId
                                        , guild = guild
                                        , channelId = channelId
                                        , channel = channel
                                        , threadRoute = NoThread
                                        }

                                Nothing ->
                                    List.Extra.findMap
                                        (\( channelId, channel ) ->
                                            case
                                                OneToOne.second
                                                    (Discord.Id.toUInt64 message.channelId |> Discord.Id.fromUInt64)
                                                    channel.linkedMessageIds
                                            of
                                                Just messageIndex ->
                                                    { guildId = guildId
                                                    , guild = guild
                                                    , channelId = channelId
                                                    , channel = channel
                                                    , threadRoute = ViewThread messageIndex
                                                    }
                                                        |> Just

                                                _ ->
                                                    Nothing
                                        )
                                        (SeqDict.toList guild.channels)

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing
    in
    case maybeData of
        Just { guildId, guild, channelId, channel, threadRoute } ->
            let
                replyTo : Maybe Int
                replyTo =
                    discordReplyTo message channel
            in
            ( { model
                | guilds =
                    SeqDict.insert
                        guildId
                        { guild
                            | channels =
                                SeqDict.insert
                                    channelId
                                    (handleDiscordCreateGuildMessageHelper
                                        message.id
                                        message.channelId
                                        threadRoute
                                        replyTo
                                        userId
                                        richText
                                        message
                                        channel
                                    )
                                    guild.channels
                        }
                        model.guilds
              }
            , broadcastToGuild
                guildId
                (Server_SendMessage
                    userId
                    message.timestamp
                    (GuildOrDmId_Guild guildId channelId threadRoute)
                    richText
                    replyTo
                    SeqDict.empty
                    |> ServerChange
                )
                model
            )

        _ ->
            ( model, Command.none )


discordReplyTo : Discord.Message -> BackendChannel -> Maybe Int
discordReplyTo message channel =
    case message.referencedMessage of
        Discord.Referenced referenced ->
            OneToOne.second referenced.id channel.linkedMessageIds

        Discord.ReferenceDeleted ->
            Nothing

        Discord.NoReference ->
            Nothing


handleDiscordCreateGuildMessageHelper :
    Discord.Id.Id Discord.Id.MessageId
    -> Discord.Id.Id Discord.Id.ChannelId
    -> ThreadRoute
    -> Maybe Int
    -> Id UserId
    -> Nonempty RichText
    -> Discord.Message
    -> BackendChannel
    -> BackendChannel
handleDiscordCreateGuildMessageHelper discordMessageId discordChannelId threadRoute replyTo userId richText message channel =
    LocalState.createMessage
        (Just ( discordMessageId, discordChannelId ))
        (UserTextMessage
            { createdAt = message.timestamp
            , createdBy = userId
            , content = richText
            , reactions = SeqDict.empty
            , editedAt = Nothing
            , repliedTo = replyTo
            , attachedFiles = SeqDict.empty
            }
        )
        threadRoute
        channel


updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    ( model, Task.perform (BackendGotTime sessionId clientId msg) Time.now )


getLoginData : SessionId -> Id UserId -> BackendUser -> BackendModel -> LoginData
getLoginData sessionId userId user model =
    { userId = userId
    , adminData =
        if user.isAdmin then
            IsAdminLoginData (adminData model user.lastLogPageViewed)

        else
            IsNotAdminLoginData
    , twoFactorAuthenticationEnabled =
        SeqDict.get userId model.twoFactorAuthentication |> Maybe.map .finishedAt
    , guilds = SeqDict.filterMap (\_ guild -> LocalState.guildToFrontendForUser userId guild) model.guilds
    , dmChannels =
        SeqDict.foldl
            (\dmChannelId dmChannel dict ->
                case DmChannel.otherUserId userId dmChannelId of
                    Just otherUserId ->
                        SeqDict.insert otherUserId dmChannel dict

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
                    if otherUserId == userId then
                        Nothing

                    else
                        Just ( otherUserId, User.backendToFrontendForUser otherUser )
                )
            |> SeqDict.fromList
    , sessionId = sessionId
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
        CheckLoginRequest ->
            let
                cmd : Command BackendOnly ToFrontend backendMsg
                cmd =
                    case getUserFromSessionId sessionId model2 of
                        Just ( userId, user ) ->
                            getLoginData sessionId userId user model2
                                |> Ok
                                |> CheckLoginResponse
                                |> Lamdera.sendToFrontend clientId

                        Nothing ->
                            CheckLoginResponse (Err ()) |> Lamdera.sendToFrontend clientId
            in
            if model2.discordNotConnected then
                ( { model2 | discordNotConnected = False }
                , Command.batch
                    [ Websocket.createHandle WebsocketCreatedHandle Discord.websocketGatewayUrl
                    , cmd
                    ]
                )

            else
                ( model2, cmd )

        LoginWithTokenRequest loginCode ->
            loginWithToken time sessionId clientId loginCode model2

        FinishUserCreationRequest personName ->
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
                                    | sessions = SeqDict.insert sessionId userId model2.sessions
                                    , pendingLogins = SeqDict.remove sessionId model2.pendingLogins
                                    , users = NonemptyDict.insert userId newUser model2.users
                                }
                        in
                        ( model3
                        , getLoginData sessionId userId newUser model3
                            |> LoginSuccess
                            |> LoginWithTokenResponse
                            |> Lamdera.sendToFrontends sessionId
                        )

                _ ->
                    ( model2, Command.none )

        LoginWithTwoFactorRequest loginCode ->
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
                                    ( { model2
                                        | sessions = SeqDict.insert sessionId pendingLogin.userId model2.sessions
                                        , pendingLogins = SeqDict.remove sessionId model2.pendingLogins
                                      }
                                    , getLoginData sessionId pendingLogin.userId user model2
                                        |> LoginSuccess
                                        |> LoginWithTokenResponse
                                        |> Lamdera.sendToFrontends sessionId
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
            ( { model2 | sessions = SeqDict.remove sessionId model2.sessions }
            , Lamdera.sendToFrontends sessionId LoggedOutSession
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

                Local_SendMessage _ guildOrDmId text repliedTo attachedFiles ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId threadRoute ->
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
                                    repliedTo
                                    (validateAttachedFiles model2.files attachedFiles)
                                )

                        GuildOrDmId_Dm otherUserId threadRoute ->
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
                                    repliedTo
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
                                , broadcastToGuildExcludingOne
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
                                , broadcastToGuildExcludingOne
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
                                , broadcastToGuildExcludingOne
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
                        (\userId _ guild ->
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
                                , broadcastToGuildExcludingOne
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
                        (\userId _ ->
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
                                , broadcastToUser
                                    (Just clientId)
                                    userId
                                    (Local_NewGuild time guildName (FilledInByBackend guildId) |> LocalChange userId)
                                    model2
                                ]
                            )
                        )

                Local_MemberTyping _ guildOrDmId ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId threadRoute ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\userId _ guild ->
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
                                        [ Local_MemberTyping time guildOrDmId
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastToGuildExcludingOne
                                            clientId
                                            guildId
                                            (Server_MemberTyping time userId guildOrDmId |> ServerChange)
                                            model2
                                        ]
                                    )
                                )

                        GuildOrDmId_Dm otherUserId threadRoute ->
                            asUser
                                model2
                                sessionId
                                (\userId _ ->
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
                                        [ Local_MemberTyping time guildOrDmId
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastToUser
                                            (Just clientId)
                                            otherUserId
                                            (Server_MemberTyping time userId (GuildOrDmId_Dm userId threadRoute) |> ServerChange)
                                            model2
                                        ]
                                    )
                                )

                Local_AddReactionEmoji guildOrDmId messageIndex emoji ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId threadRoute ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\userId _ guild ->
                                    ( { model2
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                (LocalState.updateChannel
                                                    (LocalState.addReactionEmoji emoji userId threadRoute messageIndex)
                                                    channelId
                                                    guild
                                                )
                                                model2.guilds
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , broadcastToGuildExcludingOne
                                            clientId
                                            guildId
                                            (Server_AddReactionEmoji userId guildOrDmId messageIndex emoji |> ServerChange)
                                            model2
                                        ]
                                    )
                                )

                        GuildOrDmId_Dm otherUserId threadRoute ->
                            asUser
                                model2
                                sessionId
                                (\userId _ ->
                                    let
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    ( { model2
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.addReactionEmoji emoji userId threadRoute messageIndex)
                                                model2.dmChannels
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , broadcastToDmChannel
                                            clientId
                                            userId
                                            otherUserId
                                            (\otherUserId2 ->
                                                Server_AddReactionEmoji
                                                    userId
                                                    (GuildOrDmId_Dm otherUserId2 threadRoute)
                                                    messageIndex
                                                    emoji
                                            )
                                            model2
                                        ]
                                    )
                                )

                Local_RemoveReactionEmoji guildOrDmId messageIndex emoji ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId threadRoute ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\userId _ guild ->
                                    ( { model2
                                        | guilds =
                                            SeqDict.insert
                                                guildId
                                                (LocalState.updateChannel
                                                    (LocalState.removeReactionEmoji
                                                        emoji
                                                        userId
                                                        threadRoute
                                                        messageIndex
                                                    )
                                                    channelId
                                                    guild
                                                )
                                                model2.guilds
                                      }
                                    , Command.batch
                                        [ Local_RemoveReactionEmoji guildOrDmId messageIndex emoji
                                            |> LocalChangeResponse changeId
                                            |> Lamdera.sendToFrontend clientId
                                        , broadcastToGuildExcludingOne
                                            clientId
                                            guildId
                                            (Server_RemoveReactionEmoji userId guildOrDmId messageIndex emoji
                                                |> ServerChange
                                            )
                                            model2
                                        ]
                                    )
                                )

                        GuildOrDmId_Dm otherUserId threadRoute ->
                            asUser
                                model2
                                sessionId
                                (\userId _ ->
                                    let
                                        dmChannelId : DmChannelId
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    ( { model2
                                        | dmChannels =
                                            SeqDict.updateIfExists
                                                dmChannelId
                                                (LocalState.removeReactionEmoji emoji userId threadRoute messageIndex)
                                                model2.dmChannels
                                      }
                                    , Command.batch
                                        [ LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                                        , broadcastToDmChannel
                                            clientId
                                            userId
                                            otherUserId
                                            (\otherUserId2 ->
                                                Server_RemoveReactionEmoji
                                                    userId
                                                    (GuildOrDmId_Dm otherUserId2 threadRoute)
                                                    messageIndex
                                                    emoji
                                            )
                                            model2
                                        ]
                                    )
                                )

                Local_SendEditMessage _ guildOrDmId messageIndex newContent attachedFiles ->
                    let
                        attachedFiles2 =
                            validateAttachedFiles model2.files attachedFiles
                    in
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId threadRoute ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\userId _ guild ->
                                    case SeqDict.get channelId guild.channels of
                                        Just channel ->
                                            case
                                                LocalState.editMessageHelper
                                                    time
                                                    userId
                                                    newContent
                                                    attachedFiles2
                                                    messageIndex
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
                                                            guildOrDmId
                                                            messageIndex
                                                            newContent
                                                            attachedFiles2
                                                            |> LocalChangeResponse changeId
                                                            |> Lamdera.sendToFrontend clientId
                                                        , broadcastToGuildExcludingOne
                                                            clientId
                                                            guildId
                                                            (Server_SendEditMessage
                                                                time
                                                                userId
                                                                guildOrDmId
                                                                messageIndex
                                                                newContent
                                                                attachedFiles2
                                                                |> ServerChange
                                                            )
                                                            model2
                                                        , case
                                                            ( OneToOne.first channelId guild.linkedChannelIds
                                                            , OneToOne.first messageIndex channel2.linkedMessageIds
                                                            , model2.botToken
                                                            )
                                                          of
                                                            ( Just discordChannelId, Just discordMessageId, Just botToken ) ->
                                                                Discord.editMessage
                                                                    (botTokenToAuth botToken)
                                                                    { channelId = discordChannelId
                                                                    , messageId = discordMessageId
                                                                    , content =
                                                                        toDiscordContent
                                                                            model2
                                                                            attachedFiles2
                                                                            newContent
                                                                    }
                                                                    |> Task.attempt (\_ -> EditedDiscordMessage)

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
                                )

                        GuildOrDmId_Dm otherUserId threadRoute ->
                            asUser
                                model2
                                sessionId
                                (\userId _ ->
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
                                                    messageIndex
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
                                                            messageIndex
                                                            newContent
                                                            attachedFiles2
                                                            |> LocalChangeResponse changeId
                                                            |> Lamdera.sendToFrontend clientId
                                                        , broadcastToDmChannel
                                                            clientId
                                                            userId
                                                            otherUserId
                                                            (\otherUserId2 ->
                                                                Server_SendEditMessage
                                                                    time
                                                                    userId
                                                                    (GuildOrDmId_Dm otherUserId2 threadRoute)
                                                                    messageIndex
                                                                    newContent
                                                                    attachedFiles2
                                                            )
                                                            model2
                                                        , case OneToOne.first dmChannelId model2.discordDms of
                                                            Just discordDmId ->
                                                                case
                                                                    ( OneToOne.first messageIndex dmChannel2.linkedMessageIds
                                                                    , model2.botToken
                                                                    )
                                                                of
                                                                    ( Just discordMessageId, Just botToken ) ->
                                                                        Discord.editMessage
                                                                            (botTokenToAuth botToken)
                                                                            { channelId = discordDmId
                                                                            , messageId = discordMessageId
                                                                            , content = toDiscordContent model2 attachedFiles2 newContent
                                                                            }
                                                                            |> Task.attempt (\_ -> EditedDiscordMessage)

                                                                    _ ->
                                                                        Command.none

                                                            Nothing ->
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

                Local_MemberEditTyping _ guildOrDmId messageIndex ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId threadRoute ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\userId _ guild ->
                                    case
                                        LocalState.memberIsEditTyping
                                            userId
                                            time
                                            channelId
                                            threadRoute
                                            messageIndex
                                            guild
                                    of
                                        Ok guild2 ->
                                            ( { model2 | guilds = SeqDict.insert guildId guild2 model2.guilds }
                                            , Command.batch
                                                [ Local_MemberEditTyping time guildOrDmId messageIndex
                                                    |> LocalChangeResponse changeId
                                                    |> Lamdera.sendToFrontend clientId
                                                , broadcastToGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_MemberEditTyping time userId guildOrDmId messageIndex
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

                        GuildOrDmId_Dm otherUserId threadRoute ->
                            asUser
                                model2
                                sessionId
                                (\userId _ ->
                                    let
                                        dmChannelId : DmChannelId
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    case SeqDict.get dmChannelId model2.dmChannels of
                                        Just dmChannel ->
                                            case LocalState.memberIsEditTypingHelper time userId messageIndex threadRoute dmChannel of
                                                Ok dmChannel2 ->
                                                    ( { model2
                                                        | dmChannels =
                                                            SeqDict.insert dmChannelId dmChannel2 model2.dmChannels
                                                      }
                                                    , Command.batch
                                                        [ Local_MemberEditTyping time guildOrDmId messageIndex
                                                            |> LocalChangeResponse changeId
                                                            |> Lamdera.sendToFrontend clientId
                                                        , broadcastToUser
                                                            (Just clientId)
                                                            otherUserId
                                                            (Server_MemberEditTyping
                                                                time
                                                                userId
                                                                (GuildOrDmId_Dm userId threadRoute)
                                                                messageIndex
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

                Local_SetLastViewed guildOrDmId messageIndex ->
                    asUser
                        model2
                        sessionId
                        (\userId user ->
                            ( { model2
                                | users =
                                    NonemptyDict.insert
                                        userId
                                        { user | lastViewed = SeqDict.insert guildOrDmId messageIndex user.lastViewed }
                                        model2.users
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , broadcastToUser (Just clientId) userId (LocalChange userId localMsg) model2
                                ]
                            )
                        )

                Local_DeleteMessage guildOrDmId messageIndex ->
                    case guildOrDmId of
                        GuildOrDmId_Guild guildId channelId threadRoute ->
                            asGuildMember
                                model2
                                sessionId
                                guildId
                                (\userId _ guild ->
                                    case
                                        LocalState.deleteMessage
                                            userId
                                            channelId
                                            threadRoute
                                            messageIndex
                                            guild
                                    of
                                        Ok guild2 ->
                                            ( { model2 | guilds = SeqDict.insert guildId guild2 model2.guilds }
                                            , Command.batch
                                                [ Lamdera.sendToFrontend
                                                    clientId
                                                    (LocalChangeResponse changeId localMsg)
                                                , broadcastToGuildExcludingOne
                                                    clientId
                                                    guildId
                                                    (Server_DeleteMessage userId guildOrDmId messageIndex |> ServerChange)
                                                    model2
                                                , case
                                                    ( SeqDict.get channelId guild2.channels
                                                    , OneToOne.first channelId guild2.linkedChannelIds
                                                    )
                                                  of
                                                    ( Just channel, Just discordChannelId ) ->
                                                        case
                                                            ( OneToOne.first messageIndex channel.linkedMessageIds
                                                            , model2.botToken
                                                            )
                                                        of
                                                            ( Just discordMessageId, Just botToken ) ->
                                                                Discord.deleteMessage
                                                                    (botTokenToAuth botToken)
                                                                    { channelId = discordChannelId
                                                                    , messageId = discordMessageId
                                                                    }
                                                                    |> Task.attempt (\_ -> DeletedDiscordMessage)

                                                            _ ->
                                                                Command.none

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

                        GuildOrDmId_Dm otherUserId threadRoute ->
                            asUser
                                model2
                                sessionId
                                (\userId _ ->
                                    let
                                        dmChannelId : DmChannelId
                                        dmChannelId =
                                            DmChannel.channelIdFromUserIds userId otherUserId
                                    in
                                    case SeqDict.get dmChannelId model2.dmChannels of
                                        Just dmChannel ->
                                            case LocalState.deleteMessageHelper userId messageIndex threadRoute dmChannel of
                                                Ok dmChannel2 ->
                                                    ( { model2 | dmChannels = SeqDict.insert dmChannelId dmChannel2 model2.dmChannels }
                                                    , Command.batch
                                                        [ Lamdera.sendToFrontend
                                                            clientId
                                                            (LocalChangeResponse changeId localMsg)
                                                        , broadcastToDmChannel
                                                            clientId
                                                            userId
                                                            otherUserId
                                                            (\otherUserId2 ->
                                                                Server_DeleteMessage
                                                                    userId
                                                                    (GuildOrDmId_Dm otherUserId2 threadRoute)
                                                                    messageIndex
                                                            )
                                                            model2
                                                        , case OneToOne.first dmChannelId model2.discordDms of
                                                            Just discordChannelId ->
                                                                case
                                                                    ( OneToOne.first messageIndex dmChannel2.linkedMessageIds
                                                                    , model2.botToken
                                                                    )
                                                                of
                                                                    ( Just discordMessageId, Just botToken ) ->
                                                                        Discord.deleteMessage
                                                                            (botTokenToAuth botToken)
                                                                            { channelId = discordChannelId
                                                                            , messageId = discordMessageId
                                                                            }
                                                                            |> Task.attempt (\_ -> DeletedDiscordMessage)

                                                                    _ ->
                                                                        Command.none

                                                            Nothing ->
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

                Local_ViewChannel guildId channelId ->
                    asUser
                        model2
                        sessionId
                        (\userId user ->
                            ( { model2
                                | users =
                                    NonemptyDict.insert
                                        userId
                                        (User.setLastChannelViewed guildId channelId user)
                                        model2.users
                              }
                            , Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                            )
                        )

                Local_SetName name ->
                    asUser
                        model2
                        sessionId
                        (\userId user ->
                            ( { model2
                                | users = NonemptyDict.insert userId { user | name = name } model2.users
                              }
                            , Command.batch
                                [ Lamdera.sendToFrontend clientId (LocalChangeResponse changeId localMsg)
                                , broadcastToEveryoneWhoCanSeeUser
                                    clientId
                                    userId
                                    (ServerChange (Server_SetName userId name))
                                    model2
                                ]
                            )
                        )

        TwoFactorToBackend toBackend2 ->
            asUser
                model2
                sessionId
                (\userId user ->
                    twoFactorAuthenticationUpdateFromFrontend clientId time userId user toBackend2 model2
                )

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

        ReloadDataRequest ->
            ( model2
            , case getUserFromSessionId sessionId model2 of
                Just ( userId, user ) ->
                    getLoginData sessionId userId user model2
                        |> Ok
                        |> ReloadDataResponse
                        |> Lamdera.sendToFrontend clientId

                Nothing ->
                    Lamdera.sendToFrontend clientId (ReloadDataResponse (Err ()))
            )


broadcastToEveryoneWhoCanSeeUser :
    ClientId
    -> Id UserId
    -> LocalMsg
    -> BackendModel
    -> Command BackendOnly ToFrontend msg
broadcastToEveryoneWhoCanSeeUser clientId userId change model =
    SeqDict.foldl
        (\_ guild state ->
            if userId == guild.owner || SeqDict.member userId guild.members then
                guild.owner :: SeqDict.keys guild.members |> List.foldl SeqSet.insert state

            else
                state
        )
        SeqSet.empty
        model.guilds
        |> SeqSet.foldl (\userId2 cmds -> broadcastToUser (Just clientId) userId2 change model :: cmds) []
        |> Command.batch


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
    -> Id UserId
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
joinGuildByInvite inviteLinkId time sessionId clientId guildId model userId user =
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
                        [ broadcastToGuildExcludingOne
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
                            , LocalState.guildToFrontendForUser userId guild2
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
    -> Id UserId
    -> BackendUser
    -> TwoFactorAuthentication.ToBackend
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
twoFactorAuthenticationUpdateFromFrontend clientId time userId user toBackend model =
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
                                (\_ sessionUserId -> SeqSet.member sessionUserId changes.deletedUsers |> not)
                                model2.sessions
                      }
                    , Command.batch
                        [ Pages.Admin.ChangeUsers { changes | time = time }
                            |> Local_Admin
                            |> LocalChangeResponse changeId
                            |> Lamdera.sendToFrontend clientId
                        , broadcastToOtherAdmins clientId model2 (LocalChange userId localMsg)
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
                , broadcastToOtherAdmins clientId model2 (LocalChange userId localMsg)
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
                            (Discord.getCurrentUser (botTokenToAuth botToken))
                            (Discord.getCurrentUserGuilds (botTokenToAuth botToken))
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


botTokenToAuth : DiscordBotToken -> Discord.Authentication
botTokenToAuth (DiscordBotToken botToken) =
    Discord.botToken botToken


sendDirectMessage :
    BackendModel
    -> Time.Posix
    -> ClientId
    -> ChangeId
    -> Id UserId
    -> ThreadRoute
    -> Nonempty RichText
    -> Maybe Int
    -> SeqDict (Id FileId) FileData
    -> Id UserId
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendDirectMessage model time clientId changeId otherUserId threadRoute text repliedTo attachedFiles userId user =
    let
        dmChannelId : DmChannelId
        dmChannelId =
            DmChannel.channelIdFromUserIds userId otherUserId

        dmChannel : DmChannel
        dmChannel =
            SeqDict.get dmChannelId model.dmChannels
                |> Maybe.withDefault DmChannel.init
                |> LocalState.createMessage
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
                    threadRoute

        messageIndex =
            Array.length dmChannel.messages - 1
    in
    ( { model
        | dmChannels = SeqDict.insert dmChannelId dmChannel model.dmChannels
        , users =
            NonemptyDict.insert
                userId
                { user
                    | lastViewed = SeqDict.insert (GuildOrDmId_Dm otherUserId threadRoute) messageIndex user.lastViewed
                }
                model.users
      }
    , Command.batch
        [ LocalChangeResponse
            changeId
            (Local_SendMessage time (GuildOrDmId_Dm otherUserId threadRoute) text repliedTo attachedFiles)
            |> Lamdera.sendToFrontend clientId
        , broadcastToDmChannel
            clientId
            userId
            otherUserId
            (\otherUserId2 ->
                Server_SendMessage
                    userId
                    time
                    (GuildOrDmId_Dm otherUserId2 threadRoute)
                    text
                    repliedTo
                    attachedFiles
            )
            model
        , case
            ( OneToOne.first dmChannelId model.discordDms
            , model.botToken
            )
          of
            ( Just discordChannelId, Just botToken ) ->
                Discord.createMessage
                    (botTokenToAuth botToken)
                    { channelId = discordChannelId
                    , content = toDiscordContent model attachedFiles text
                    , replyTo =
                        case repliedTo of
                            Just index ->
                                OneToOne.first index dmChannel.linkedMessageIds

                            Nothing ->
                                Nothing
                    }
                    |> Task.attempt (SentDirectMessageToDiscord dmChannelId threadRoute messageIndex)

            _ ->
                Command.none
        ]
    )


broadcastToDmChannel :
    ClientId
    -> Id UserId
    -> Id UserId
    -> (Id UserId -> ServerChange)
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
broadcastToDmChannel clientId userId otherUserId serverMsg model =
    if userId == otherUserId then
        broadcastToUser (Just clientId) userId (serverMsg otherUserId |> ServerChange) model

    else
        Command.batch
            [ broadcastToUser (Just clientId) userId (serverMsg otherUserId |> ServerChange) model
            , broadcastToUser (Just clientId) otherUserId (serverMsg userId |> ServerChange) model
            ]


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
    -> ThreadRoute
    -> Nonempty RichText
    -> Maybe Int
    -> SeqDict (Id FileId) FileData
    -> Id UserId
    -> BackendUser
    -> BackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendGuildMessage model time clientId changeId guildId channelId threadRoute text repliedTo attachedFiles userId user guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            let
                channel2 : BackendChannel
                channel2 =
                    LocalState.createMessage
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
                        threadRoute
                        channel

                messageIndex : Int
                messageIndex =
                    Array.length channel2.messages - 1

                maybeDiscordChannelId : Maybe ( Discord.Id.Id Discord.Id.ChannelId, Maybe (Discord.Id.Id Discord.Id.MessageId) )
                maybeDiscordChannelId =
                    case Debug.log "threadRoute" threadRoute of
                        ViewThread threadMessageIndex ->
                            case OneToOne.first threadMessageIndex channel.linkedThreadIds of
                                Just discordThreadId ->
                                    let
                                        _ =
                                            Debug.log "discordThreadId" (Discord.Id.toString discordThreadId)
                                    in
                                    ( discordThreadId
                                    , case repliedTo of
                                        Just index ->
                                            SeqDict.get threadMessageIndex channel.threads
                                                |> Maybe.withDefault DmChannel.threadInit
                                                |> .linkedMessageIds
                                                |> OneToOne.first index

                                        Nothing ->
                                            Nothing
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing

                        NoThread ->
                            case OneToOne.first channelId guild.linkedChannelIds of
                                Just discordChannelId ->
                                    ( discordChannelId
                                    , case repliedTo of
                                        Just index ->
                                            OneToOne.first index channel2.linkedMessageIds

                                        Nothing ->
                                            Nothing
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing
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
                        { user
                            | lastViewed =
                                SeqDict.insert
                                    (GuildOrDmId_Guild guildId channelId threadRoute)
                                    messageIndex
                                    user.lastViewed
                        }
                        model.users
              }
            , Command.batch
                [ LocalChangeResponse
                    changeId
                    (Local_SendMessage time (GuildOrDmId_Guild guildId channelId threadRoute) text repliedTo attachedFiles)
                    |> Lamdera.sendToFrontend clientId
                , broadcastToGuildExcludingOne
                    clientId
                    guildId
                    (Server_SendMessage userId time (GuildOrDmId_Guild guildId channelId threadRoute) text repliedTo attachedFiles
                        |> ServerChange
                    )
                    model
                , case ( maybeDiscordChannelId, model.botToken ) of
                    ( Just ( discordChannelId, replyTo ), Just botToken ) ->
                        Discord.createMessage
                            (botTokenToAuth botToken)
                            { channelId = discordChannelId
                            , content = toDiscordContent model attachedFiles text
                            , replyTo = replyTo
                            }
                            |> Task.attempt
                                (SentGuildMessageToDiscord
                                    { guildId = guildId, channelId = channelId, messageIndex = messageIndex }
                                    threadRoute
                                )

                    _ ->
                        Command.none
                ]
            )

        Nothing ->
            ( model
            , invalidChangeResponse changeId clientId
            )


broadcastToGuildExcludingOne : ClientId -> Id GuildId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
broadcastToGuildExcludingOne clientToSkip _ msg model =
    List.concatMap
        (\( _, otherClientIds ) ->
            NonemptyDict.keys otherClientIds
                |> List.Nonempty.toList
                |> List.filterMap
                    (\otherClientId ->
                        if clientToSkip == otherClientId then
                            Nothing

                        else
                            ChangeBroadcast msg
                                |> Lamdera.sendToFrontend otherClientId
                                |> Just
                    )
        )
        (SeqDict.toList model.connections)
        |> Command.batch


broadcastToGuild : Id GuildId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
broadcastToGuild _ msg model =
    List.concatMap
        (\( _, otherClientIds ) ->
            NonemptyDict.keys otherClientIds
                |> List.Nonempty.toList
                |> List.map
                    (\otherClientId ->
                        ChangeBroadcast msg
                            |> Lamdera.sendToFrontend otherClientId
                    )
        )
        (SeqDict.toList model.connections)
        |> Command.batch


broadcastToUser : Maybe ClientId -> Id UserId -> LocalMsg -> BackendModel -> Command BackendOnly ToFrontend msg
broadcastToUser clientToSkip userId msg model =
    SeqDict.filterMap
        (\sessionId otherUserId ->
            if userId == otherUserId then
                case SeqDict.get sessionId model.connections of
                    Just clientIds ->
                        List.filterMap
                            (\( otherClientId, _ ) ->
                                if clientToSkip == Just otherClientId then
                                    Nothing

                                else
                                    ChangeBroadcast msg
                                        |> Lamdera.sendToFrontend otherClientId
                                        |> Just
                            )
                            (NonemptyDict.toList clientIds)
                            |> Command.batch
                            |> Just

                    Nothing ->
                        Nothing

            else
                Nothing
        )
        model.sessions
        |> SeqDict.values
        |> Command.batch



--    |> SeqDict.keys
--    |>
--List.concatMap
--    (\( _, otherClientIds ) ->
--        NonemptyDict.keys otherClientIds
--            |> List.Nonempty.toList
--            |> List.filterMap
--                (\otherClientId ->
--                    if clientToSkip == otherClientId then
--                        Nothing
--
--                    else
--                        ChangeBroadcast msg
--                            |> Lamdera.sendToFrontend otherClientId
--                            |> Just
--                )
--    )
--    (SeqDict.toList model.connections)
--    |> Command.batch


broadcastToOtherAdmins : ClientId -> BackendModel -> LocalMsg -> Command BackendOnly ToFrontend msg
broadcastToOtherAdmins currentClientId model broadcastMsg =
    List.concatMap
        (\( sessionId, clientIds ) ->
            case getUserFromSessionId sessionId model of
                Just ( _, user ) ->
                    if user.isAdmin then
                        NonemptyDict.toList clientIds
                            |> List.filterMap
                                (\( clientId2, _ ) ->
                                    if clientId2 == currentClientId then
                                        Nothing

                                    else
                                        ChangeBroadcast broadcastMsg
                                            |> Lamdera.sendToFrontend clientId2
                                            |> Just
                                )

                    else
                        []

                Nothing ->
                    []
        )
        (SeqDict.toList model.connections)
        |> Command.batch


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
    -> (Id UserId -> BackendUser -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asUser model sessionId func =
    case SeqDict.get sessionId model.sessions of
        Just userId ->
            case NonemptyDict.get userId model.users of
                Just user ->
                    func userId user

                Nothing ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asGuildMember :
    BackendModel
    -> SessionId
    -> Id GuildId
    -> (Id UserId -> BackendUser -> BackendGuild -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asGuildMember model sessionId guildId func =
    case SeqDict.get sessionId model.sessions of
        Just userId ->
            case ( NonemptyDict.get userId model.users, SeqDict.get guildId model.guilds ) of
                ( Just user, Just guild ) ->
                    func userId user guild

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
        (\userId user guild ->
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
        (\userId user ->
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
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
loginWithToken time sessionId clientId loginCode model =
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
                            ( { model
                                | sessions = SeqDict.insert sessionId pendingLogin.userId model.sessions
                                , pendingLogins = SeqDict.remove sessionId model.pendingLogins
                              }
                            , getLoginData sessionId pendingLogin.userId user model
                                |> LoginSuccess
                                |> LoginWithTokenResponse
                                |> Lamdera.sendToFrontends sessionId
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


getUserFromSessionId : SessionId -> BackendModel -> Maybe ( Id UserId, BackendUser )
getUserFromSessionId sessionId model =
    SeqDict.get sessionId model.sessions
        |> Maybe.andThen (\userId -> NonemptyDict.get userId model.users |> Maybe.map (Tuple.pair userId))


emailToNotifyWhenErrorsAreLogged : EmailAddress
emailToNotifyWhenErrorsAreLogged =
    Unsafe.emailAddress "martinsstewart@gmail.com"


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
