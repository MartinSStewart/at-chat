module BackendExtra exposing
    ( addLog
    , addLogWithCmd
    , adminData
    , discordDmChannelToFrontend
    , discordGuildToFrontendForUser
    , getLinkedDiscordUsersAndOtherUsers
    , getLoginCode
    , getLoginData
    , invalidChangeResponse
    , loginEmailContent
    , loginEmailSubject
    , loginWithToken
    , sendDm
    , sendGuildMessage
    , sendLoginEmail
    , shouldRateLimit
    , validateAttachedFiles
    )

{-| Backend.elm is getting to large and it's slowing down my IDE.
Most of the stuff in there doesn't neatly fit into it's own module so instead I'm just moving lots of functions here instead.
-}

import Array
import Broadcast
import Discord
import DiscordUserData exposing (DiscordUserData(..), DiscordUserLoadingData(..))
import DmChannel exposing (DiscordDmChannel, DiscordFrontendDmChannel, DmChannel, DmChannelId)
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Task as Task
import Effect.Time as Time
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import FileStatus exposing (FileData, FileHash, FileId)
import Hex
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), UserId)
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId)
import LocalState exposing (BackendChannel, BackendGuild, DiscordBackendGuild, DiscordFrontendGuild, DiscordUserData_ForAdmin(..))
import Log exposing (Log)
import LoginForm
import Message exposing (Message(..))
import NonemptyDict exposing (NonemptyDict)
import NonemptySet
import Pages.Admin exposing (InitAdminData)
import Pagination exposing (PageId)
import PersonName
import Postmark
import Quantity
import RichText exposing (RichText)
import SecretId
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString(..))
import Thread exposing (BackendThread)
import Types exposing (AdminStatusLoginData(..), BackendFileData, BackendModel, BackendMsg(..), InitialLoadRequest(..), LocalChange(..), LocalMsg(..), LoginData, LoginResult(..), LoginTokenData(..), ServerChange(..), ToFrontend(..))
import User exposing (BackendUser, DiscordFrontendCurrentUser, DiscordFrontendUser)
import UserAgent exposing (UserAgent)
import UserSession exposing (UserSession)
import VisibleMessages


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
            { model | logs = Array.push { time = time, log = log, isHidden = False } model.logs }
    in
    case
        ( Log.shouldNotifyAdmin log
        , Duration.from model2.lastErrorLogEmail time |> Quantity.lessThan (Duration.minutes 30)
        )
    of
        ( Just text, False ) ->
            ( { model2 | lastErrorLogEmail = time }
            , case EmailAddress.fromString Env.adminEmail of
                Just emailAddress ->
                    Postmark.sendEmailTask
                        Env.postmarkServerToken
                        { from = { name = "", email = Env.noReplyEmailAddress }
                        , to = Nonempty { name = "", email = emailAddress } []
                        , subject = NonemptyString 'A' "n error was logged that needs attention"
                        , body = "The following error was logged: " ++ text ++ ". Note that any additional errors logged for the next 30 minutes will be ignored to avoid spamming emails." |> Postmark.BodyText
                        , messageStream = "outbound"
                        }
                        |> Task.attempt (SentLogErrorEmail time emailAddress)

                Nothing ->
                    Command.none
            )

        _ ->
            ( model2, Command.none )


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
    -> InitialLoadRequest
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
                                    UserSession.init
                                        sessionId
                                        pendingLogin.userId
                                        (case requestMessagesFor of
                                            InitialLoadRequested_None ->
                                                Nothing

                                            InitialLoadRequested_Channel anyGuildOrDmId threadRoute ->
                                                Just ( anyGuildOrDmId, threadRoute )

                                            InitialLoadRequested_Admin _ ->
                                                Nothing
                                        )
                                        userAgent
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
                                        session.sessionIdHash
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


invalidChangeResponse : ChangeId -> ClientId -> Command BackendOnly ToFrontend backendMsg
invalidChangeResponse changeId clientId =
    LocalChangeResponse changeId Local_Invalid
        |> Lamdera.sendToFrontend clientId


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


getLoginData :
    SessionId
    -> UserSession
    -> BackendUser
    -> InitialLoadRequest
    -> BackendModel
    -> LoginData
getLoginData sessionId session user requestMessagesFor model =
    let
        ( otherDiscordUsers, linkedDiscordUsers ) =
            getLinkedDiscordUsersAndOtherUsers session.userId model
    in
    { session = session
    , adminData =
        if user.isAdmin then
            case requestMessagesFor of
                InitialLoadRequested_Admin logPage ->
                    IsAdminLoginData (adminData model (Maybe.withDefault user.lastLogPageViewed logPage))

                InitialLoadRequested_Channel _ _ ->
                    IsAdminButNoData

                InitialLoadRequested_None ->
                    IsAdminButNoData

        else
            IsNotAdminLoginData
    , twoFactorAuthenticationEnabled =
        SeqDict.get session.userId model.twoFactorAuthentication |> Maybe.map .finishedAt
    , guilds =
        SeqDict.filterMap
            (\guildId guild ->
                LocalState.guildToFrontendForUser
                    (case requestMessagesFor of
                        InitialLoadRequested_Channel (GuildOrDmId (GuildOrDmId_Guild guildIdB channelId)) threadRoute ->
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
    , discordGuilds =
        SeqDict.filterMap
            (\guildId guild ->
                discordGuildToFrontendForUser
                    (case requestMessagesFor of
                        InitialLoadRequested_Channel (DiscordGuildOrDmId (DiscordGuildOrDmId_Guild _ requestedGuildId requestChannelId)) threadRoute ->
                            if requestedGuildId == guildId then
                                Just ( requestChannelId, threadRoute )

                            else
                                Nothing

                        _ ->
                            Nothing
                    )
                    guild
                    linkedDiscordUsers
            )
            model.discordGuilds
    , discordDmChannels =
        SeqDict.filterMap
            (\dmChannelId dmChannel ->
                discordDmChannelToFrontend
                    (case requestMessagesFor of
                        InitialLoadRequested_Channel (DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data)) _ ->
                            dmChannelId == data.channelId

                        _ ->
                            False
                    )
                    dmChannel
                    linkedDiscordUsers
            )
            model.discordDmChannels
    , dmChannels =
        SeqDict.foldl
            (\dmChannelId dmChannel dict ->
                case DmChannel.otherUserId session.userId dmChannelId of
                    Just otherUserId ->
                        SeqDict.insert otherUserId
                            (DmChannel.toFrontend
                                (case requestMessagesFor of
                                    InitialLoadRequested_Channel (GuildOrDmId (GuildOrDmId_Dm otherUserIdB)) threadRoute ->
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
    , user = User.backendToFrontendCurrent user
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
    , otherDiscordUsers = otherDiscordUsers
    , linkedDiscordUsers = linkedDiscordUsers
    , otherSessions =
        SeqDict.remove sessionId model.sessions
            |> SeqDict.toList
            |> List.filterMap
                (\( _, otherSession ) ->
                    case UserSession.toFrontend session.userId otherSession of
                        Just frontendSession ->
                            Just ( otherSession.sessionIdHash, frontendSession )

                        Nothing ->
                            Nothing
                )
            |> SeqDict.fromList
    , publicVapidKey = model.publicVapidKey
    , textEditor = model.textEditor
    }


discordGuildToFrontendForUser :
    Maybe ( Discord.Id Discord.ChannelId, ThreadRoute )
    -> DiscordBackendGuild
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser
    -> Maybe DiscordFrontendGuild
discordGuildToFrontendForUser requestMessagesFor guild linkedDiscordUsers =
    if
        SeqDict.member guild.owner linkedDiscordUsers
            || not (SeqDict.isEmpty (SeqDict.intersect guild.members linkedDiscordUsers))
    then
        { name = guild.name
        , icon = guild.icon
        , channels =
            SeqDict.filterMap
                (\channelId channel ->
                    LocalState.discordChannelToFrontend
                        (case requestMessagesFor of
                            Just ( channelIdB, threadRoute ) ->
                                if channelId == channelIdB then
                                    Just threadRoute

                                else
                                    Nothing

                            _ ->
                                Nothing
                        )
                        channel
                )
                guild.channels
        , members = guild.members
        , owner = guild.owner
        }
            |> Just

    else
        Nothing


discordDmChannelToFrontend :
    Bool
    -> DiscordDmChannel
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser
    -> Maybe DiscordFrontendDmChannel
discordDmChannelToFrontend preloadMessages dmChannel linkedDiscordUsers =
    if List.any (\( linkedId, _ ) -> NonemptySet.member linkedId dmChannel.members) (SeqDict.toList linkedDiscordUsers) then
        { messages = DmChannel.toDiscordFrontendHelper preloadMessages { messages = dmChannel.messages, threads = SeqDict.empty }
        , visibleMessages = VisibleMessages.init preloadMessages dmChannel
        , lastTypedAt = dmChannel.lastTypedAt
        , members = dmChannel.members
        }
            |> Just

    else
        Nothing


getLinkedDiscordUsersAndOtherUsers :
    Id UserId
    -> BackendModel
    ->
        ( SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
        , SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser
        )
getLinkedDiscordUsersAndOtherUsers userId model =
    SeqDict.foldl
        (\discordUserId userData ( otherDiscordUsers2, linkedDiscordUsers2 ) ->
            case userData of
                FullData data ->
                    if data.linkedTo == userId then
                        ( otherDiscordUsers2
                        , SeqDict.insert
                            discordUserId
                            (User.discordFullDataUserToFrontendCurrentUser False data data.isLoadingData)
                            linkedDiscordUsers2
                        )

                    else
                        ( SeqDict.insert
                            discordUserId
                            { name = PersonName.fromStringLossy data.user.username, icon = data.icon }
                            otherDiscordUsers2
                        , linkedDiscordUsers2
                        )

                BasicData data ->
                    ( SeqDict.insert
                        discordUserId
                        { name = PersonName.fromStringLossy data.user.username, icon = data.icon }
                        otherDiscordUsers2
                    , linkedDiscordUsers2
                    )

                NeedsAuthAgain data ->
                    if data.linkedTo == userId then
                        ( otherDiscordUsers2
                        , SeqDict.insert
                            discordUserId
                            (User.discordFullDataUserToFrontendCurrentUser True data DiscordUserLoadedSuccessfully)
                            linkedDiscordUsers2
                        )

                    else
                        ( SeqDict.insert
                            discordUserId
                            { name = PersonName.fromStringLossy data.user.username, icon = data.icon }
                            otherDiscordUsers2
                        , linkedDiscordUsers2
                        )
        )
        ( SeqDict.empty, SeqDict.empty )
        model.discordUsers


adminData : BackendModel -> Id PageId -> InitAdminData
adminData model lastLogPageViewed =
    { users = model.users
    , emailNotificationsEnabled = model.emailNotificationsEnabled
    , signupsEnabled = model.signupsEnabled
    , twoFactorAuthentication = SeqDict.map (\_ a -> a.finishedAt) model.twoFactorAuthentication
    , privateVapidKey = model.privateVapidKey
    , slackClientSecret = model.slackClientSecret
    , openRouterKey = model.openRouterKey
    , discordDmChannels =
        SeqDict.map
            (\_ channel ->
                { members = channel.members
                , messageCount = Array.length channel.messages
                , firstMessage = Array.get 0 channel.messages
                }
            )
            model.discordDmChannels
    , discordUsers =
        SeqDict.map
            (\_ discordUser ->
                case discordUser of
                    FullData data ->
                        FullData_ForAdmin
                            { user = data.user
                            , linkedTo = data.linkedTo
                            , icon = data.icon
                            , linkedAt = data.linkedAt
                            , isLoadingData = data.isLoadingData
                            }

                    BasicData data ->
                        BasicData_ForAdmin data

                    NeedsAuthAgain data ->
                        NeedsAuthAgain_ForAdmin data
            )
            model.discordUsers
    , discordGuilds =
        SeqDict.map
            (\_ guild ->
                { name = guild.name
                , channels =
                    SeqDict.map
                        (\_ channel ->
                            { name = channel.name
                            , messageCount = Array.length channel.messages
                            , threadCount = SeqDict.size channel.threads
                            , firstMessage = Array.get 0 channel.messages
                            }
                        )
                        guild.channels
                , members = guild.members
                , owner = guild.owner
                }
            )
            model.discordGuilds
    , guilds =
        SeqDict.map
            (\_ guild ->
                { name = guild.name
                , channels =
                    SeqDict.map
                        (\_ channel ->
                            { name = channel.name
                            , messageCount = Array.length channel.messages
                            }
                        )
                        guild.channels
                , memberCount = SeqDict.size guild.members
                , owner = guild.owner
                }
            )
            model.guilds
    , loadingDiscordChannels =
        SeqDict.map
            (\_ channel ->
                LocalState.loadingDiscordChannelMap
                    (List.foldl (\message count -> count + List.length message.attachments) 0)
                    channel
            )
            model.loadingDiscordChannels
    , logs = Pagination.init lastLogPageViewed model.logs
    }


sendGuildMessage :
    BackendModel
    -> Time.Posix
    -> ClientId
    -> ChangeId
    -> Id GuildId
    -> Id ChannelId
    -> ThreadRouteWithMaybeMessage
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> UserSession
    -> BackendUser
    -> BackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendGuildMessage model time clientId changeId guildId channelId threadRouteWithMaybeReplyTo text attachedFiles session user guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            let
                channel2 : BackendChannel
                channel2 =
                    case threadRouteWithMaybeReplyTo of
                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                            LocalState.createThreadMessageBackend
                                threadId
                                (UserTextMessage
                                    { createdAt = time
                                    , createdBy = session.userId
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
                                (UserTextMessage
                                    { createdAt = time
                                    , createdBy = session.userId
                                    , content = text
                                    , reactions = SeqDict.empty
                                    , editedAt = Nothing
                                    , repliedTo = maybeReplyTo
                                    , attachedFiles = attachedFiles
                                    }
                                )
                                channel

                guildOrDmId : GuildOrDmId
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
                                    List.any
                                        (\( _, userSession ) ->
                                            userSession.currentlyViewing == Just ( GuildOrDmId guildOrDmId, threadRouteNoReply )
                                        )
                                        (Broadcast.userGetAllSessions userId2 model)
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
                        session.userId
                        (case threadRouteWithMaybeReplyTo of
                            ViewThreadWithMaybeMessage threadMessageIndex _ ->
                                { user
                                    | lastViewedThreads =
                                        SeqDict.insert
                                            ( GuildOrDmId guildOrDmId, threadMessageIndex )
                                            (SeqDict.get threadMessageIndex channel2.threads
                                                |> Maybe.withDefault Thread.backendInit
                                                |> DmChannel.latestThreadMessageId
                                            )
                                            user.lastViewedThreads
                                }

                            NoThreadWithMaybeMessage _ ->
                                { user
                                    | lastViewed =
                                        SeqDict.insert
                                            (GuildOrDmId guildOrDmId)
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
                    (Server_SendMessage session.userId time guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles
                        |> ServerChange
                    )
                    model
                , Broadcast.messageNotification
                    usersMentioned
                    time
                    session.userId
                    guildId
                    channelId
                    threadRouteNoReply
                    text
                    (guild.owner :: SeqDict.keys guild.members)
                    model
                ]
            )

        Nothing ->
            ( model
            , invalidChangeResponse changeId clientId
            )


sendDm :
    BackendModel
    -> Time.Posix
    -> ClientId
    -> ChangeId
    -> Id UserId
    -> ThreadRouteWithMaybeMessage
    -> Nonempty (RichText (Id UserId))
    -> SeqDict (Id FileId) FileData
    -> UserSession
    -> BackendUser
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendDm model time clientId changeId otherUserId threadRouteWithReplyTo text attachedFiles session user =
    let
        dmChannelId : DmChannelId
        dmChannelId =
            DmChannel.channelIdFromUserIds session.userId otherUserId

        dmChannel : DmChannel
        dmChannel =
            SeqDict.get dmChannelId model.dmChannels
                |> Maybe.withDefault DmChannel.backendInit
    in
    case threadRouteWithReplyTo of
        ViewThreadWithMaybeMessage threadMessageIndex _ ->
            let
                thread : BackendThread
                thread =
                    SeqDict.get threadMessageIndex dmChannel.threads |> Maybe.withDefault Thread.backendInit
            in
            ( { model
                | dmChannels = SeqDict.insert dmChannelId dmChannel model.dmChannels
                , users =
                    NonemptyDict.insert
                        session.userId
                        { user
                            | lastViewedThreads =
                                SeqDict.insert
                                    ( GuildOrDmId (GuildOrDmId_Dm otherUserId), threadMessageIndex )
                                    (DmChannel.latestThreadMessageId thread)
                                    user.lastViewedThreads
                        }
                        model.users
              }
            , if session.userId == otherUserId then
                Command.none

              else
                Broadcast.broadcastDm
                    changeId
                    time
                    clientId
                    session.userId
                    otherUserId
                    text
                    threadRouteWithReplyTo
                    attachedFiles
                    model
            )

        NoThreadWithMaybeMessage repliedTo ->
            let
                messageIndex : Id ChannelMessageId
                messageIndex =
                    DmChannel.latestMessageId dmChannel2

                dmChannel2 : DmChannel
                dmChannel2 =
                    LocalState.createChannelMessageBackend
                        (UserTextMessage
                            { createdAt = time
                            , createdBy = session.userId
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
                        session.userId
                        { user
                            | lastViewed =
                                SeqDict.insert
                                    (GuildOrDmId (GuildOrDmId_Dm otherUserId))
                                    messageIndex
                                    user.lastViewed
                        }
                        model.users
              }
            , Command.batch
                [ Broadcast.broadcastDm changeId time clientId session.userId otherUserId text threadRouteWithReplyTo attachedFiles model
                ]
            )
