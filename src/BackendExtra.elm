module BackendExtra exposing
    ( addLog
    , addLogWithCmd
    , adminData
    , asAdmin
    , asDiscordDmUser
    , asDiscordDmUser_AllowUserThatNeedsAuthAgain
    , asDiscordGuildMember
    , asDiscordGuildMember_AllowUserThatNeedsAuthAgain
    , asDiscordUser
    , asDmUser
    , asGuildMember
    , asGuildOwner
    , asUser
    , discordDmChannelToFrontend
    , discordGuildToFrontend
    , discordGuildToFrontendForUser
    , getLinkedDiscordUsersAndOtherUsers
    , getLoginCode
    , getLoginData
    , handleDrawingChange
    , invalidChangeResponse
    , loginEmailContent
    , loginEmailSubject
    , loginWithToken
    , requestedForToGuildOrDmId
    , sendDm
    , sendGuildMessage
    , sendLoginEmail
    , shouldRateLimit
    , toBackendLog
    , validateAttachedFiles
    )

{-| Backend.elm is getting to large and it's slowing down my IDE.
Most of the stuff in there doesn't neatly fit into it's own module so instead I'm just moving lots of functions here instead.
-}

import Array
import Broadcast
import Bytes.Decode
import Bytes.Encode
import Call exposing (CallId(..))
import Discord
import DiscordUserData exposing (DiscordFullUserData, DiscordUserData(..), DiscordUserLoadingData(..), NeedsAuthAgainData)
import DmChannel exposing (DiscordDmChannel, DiscordFrontendDmChannel, DmChannel, DmChannelId)
import Drawing
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Task as Task
import Effect.Time as Time
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import FileStatus exposing (FileData, FileHash, FileId)
import Hex
import Id exposing (AnyGuildOrDmId(..), ChannelId, DiscordGuildOrDmId(..), DiscordGuildOrDmId_DmData, GuildId, GuildOrDmId(..), Id, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId)
import Lamdera.Wire3
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId)
import LocalState exposing (BackendGuild, CallStatus(..), DiscordBackendGuild, DiscordFrontendGuild, DiscordUserData_ForAdmin(..))
import Log exposing (Log)
import LoginForm
import MembersAndOwner exposing (IsMember(..))
import Message
import NonemptyDict exposing (NonemptyDict)
import Pages.Admin exposing (InitAdminData)
import Pagination exposing (PageId)
import PersonName
import Postmark
import Quantity
import RateLimit
import RichText exposing (RichText)
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SessionIdHash
import String.Nonempty exposing (NonemptyString(..))
import Thread
import ToBackendLog exposing (ToBackendLog(..))
import Types exposing (AdminStatusLoginData(..), BackendFileData, BackendModel, BackendMsg(..), InitialLoadRequest(..), LocalChange(..), LocalMsg(..), LoginData, LoginResult(..), LoginTokenData(..), ServerChange(..), ToBackend(..), ToFrontend(..))
import Unsafe
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
            , Command.batch
                [ case adminEmailAddress model2 of
                    Just emailAddress ->
                        Postmark.sendEmailTask
                            model2.postmarkApiKey
                            { from = { name = "", email = noReplyEmailAddress }
                            , to = Nonempty { name = "", email = emailAddress } []
                            , subject = NonemptyString 'A' "n error was logged that needs attention"
                            , body =
                                "The following error was logged: "
                                    ++ text
                                    ++ ". Note that any additional errors logged for the next 30 minutes will be ignored to avoid spamming emails."
                                    |> Postmark.BodyText
                            , messageStream = "outbound"
                            }
                            |> Task.attempt (SentLogErrorEmail time emailAddress)

                    Nothing ->
                        Command.none
                , Broadcast.toAdmins model2 (Server_NewLog time log |> ServerChange)
                ]
            )

        _ ->
            ( model2, Broadcast.toAdmins model2 (Server_NewLog time log |> ServerChange) )


noReplyEmailAddress : EmailAddress
noReplyEmailAddress =
    Unsafe.emailAddress "no-reply@at-chat.app"


adminEmailAddress : BackendModel -> Maybe EmailAddress
adminEmailAddress model =
    List.Extra.findMap
        (\( _, user ) ->
            if user.isAdmin then
                Just user.email

            else
                Nothing
        )
        (NonemptyDict.toList model.users)


getLoginCode :
    Time.Posix
    -> { a | secretCounter : Int, serverSecret : SecretId ServerSecret }
    -> ( { a | secretCounter : Int, serverSecret : SecretId ServerSecret }, Result () Int )
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
    -> Postmark.ApiKey
    -> Command BackendOnly toFrontend backendMsg
sendLoginEmail msg emailAddress loginCode postmarkServerToken =
    let
        loginCode2 =
            String.padLeft LoginForm.loginCodeLength '0' (String.fromInt loginCode)

        _ =
            Debug.log "login" loginCode2
    in
    { from = { name = "", email = noReplyEmailAddress }
    , to = List.Nonempty.fromElement { name = "", email = emailAddress }
    , subject = loginEmailSubject
    , body =
        Postmark.BodyBoth
            (loginEmailContent loginCode2)
            ("Here is your code " ++ loginCode2 ++ "\n\nPlease type it in the login page you were previously on.\n\nIf you weren't expecting this email you can safely ignore it.")
    , messageStream = "outbound"
    }
        |> Postmark.sendEmail msg postmarkServerToken


loginEmailContent : String -> Email.Html.Html
loginEmailContent loginCode =
    Email.Html.div
        [ Email.Html.Attributes.padding "8px" ]
        [ Email.Html.div [] [ Email.Html.text "Here is your code." ]
        , Email.Html.div
            [ Email.Html.Attributes.fontSize "36px"
            , Email.Html.Attributes.fontFamily "monospace"
            ]
            (String.toList loginCode
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


requestedForToGuildOrDmId : Id UserId -> InitialLoadRequest -> Maybe ( AnyGuildOrDmId, ThreadRoute )
requestedForToGuildOrDmId userId requestMessagesFor =
    case requestMessagesFor of
        InitialLoadRequested_None ->
            Nothing

        InitialLoadRequested_Discord guildOrDmId threadRoute ->
            Just ( DiscordGuildOrDmId guildOrDmId, threadRoute )

        InitialLoadRequested_Admin _ ->
            Nothing

        InitialLoadRequested_Guild guildId channelId threadRoute ->
            Just ( GuildOrDmId (GuildOrDmId_Guild guildId channelId), threadRoute )

        InitialLoadRequested_Dm dmChannelId threadRoute ->
            case DmChannel.otherUserId userId dmChannelId of
                Just otherUserId ->
                    Just ( GuildOrDmId (GuildOrDmId_Dm otherUserId), threadRoute )

                Nothing ->
                    Nothing


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
                                        time
                                        sessionId
                                        pendingLogin.userId
                                        (requestedForToGuildOrDmId pendingLogin.userId requestMessagesFor)
                                        userAgent
                            in
                            ( { model
                                | sessions = SeqDict.insert sessionId session model.sessions
                                , pendingLogins = SeqDict.remove sessionId model.pendingLogins
                              }
                            , Command.batch
                                [ getLoginData sessionId clientId session user requestMessagesFor model
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
    -> ClientId
    -> UserSession
    -> BackendUser
    -> InitialLoadRequest
    -> BackendModel
    -> LoginData
getLoginData sessionId clientId session user requestMessagesFor model =
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

                InitialLoadRequested_None ->
                    IsAdminButNoData

                InitialLoadRequested_Guild _ _ _ ->
                    IsAdminButNoData

                InitialLoadRequested_Dm _ _ ->
                    IsAdminButNoData

                InitialLoadRequested_Discord _ _ ->
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
                        InitialLoadRequested_Guild guildIdB channelId threadRoute ->
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
                        InitialLoadRequested_Discord (DiscordGuildOrDmId_Guild _ requestedGuildId requestChannelId) threadRoute ->
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
                        InitialLoadRequested_Discord (DiscordGuildOrDmId_Dm data) _ ->
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
                                    InitialLoadRequested_Dm dmChannelIdB threadRoute ->
                                        if dmChannelId == dmChannelIdB then
                                            Just threadRoute

                                        else
                                            Nothing

                                    _ ->
                                        Nothing
                                )
                                dmChannelId
                                model.goMatchPublicIds
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
    , stickers = model.stickers
    , customEmojis = model.customEmojis
    , voiceChatPeers = getVoiceChatData clientId session model
    }


getVoiceChatDataHelper :
    CallId
    -> UserSession
    -> UserSession
    -> ClientId
    -> Call.RemoteCallData
    -> SeqDict CallId (NonemptyDict ( Id UserId, ClientId ) Call.RemoteCallData)
    -> SeqDict CallId (NonemptyDict ( Id UserId, ClientId ) Call.RemoteCallData)
getVoiceChatDataHelper roomId session otherSession otherClientId remoteCallData dict2 =
    case roomId of
        DmRoomId dmingWith ->
            let
                dmChannelId : DmChannelId
                dmChannelId =
                    DmChannel.channelIdFromUserIds otherSession.userId dmingWith
            in
            case DmChannel.otherUserId session.userId dmChannelId of
                Just otherUserId ->
                    SeqDict.update
                        (DmRoomId otherUserId)
                        (\maybe ->
                            case maybe of
                                Just nonempty ->
                                    NonemptyDict.insert ( otherSession.userId, otherClientId ) remoteCallData nonempty |> Just

                                Nothing ->
                                    NonemptyDict.singleton ( otherSession.userId, otherClientId ) remoteCallData |> Just
                        )
                        dict2

                Nothing ->
                    dict2


getVoiceChatData : ClientId -> UserSession -> BackendModel -> SeqDict CallId (NonemptyDict ( Id UserId, ClientId ) Call.RemoteCallData)
getVoiceChatData clientId session model =
    SeqDict.foldl
        (\otherSessionId connections dict ->
            case SeqDict.get otherSessionId model.sessions of
                Just otherSession ->
                    NonemptyDict.foldl
                        (\otherClientId data dict2 ->
                            case ( data.call, otherClientId == clientId ) of
                                ( ConnectedToCall roomId _, False ) ->
                                    getVoiceChatDataHelper roomId session otherSession otherClientId data.remoteCallData dict2

                                ( ConnectingToCall roomId, False ) ->
                                    getVoiceChatDataHelper roomId session otherSession otherClientId data.remoteCallData dict2

                                _ ->
                                    dict2
                        )
                        dict
                        connections

                Nothing ->
                    dict
        )
        SeqDict.empty
        model.connections


discordGuildToFrontendForUser :
    Maybe ( Discord.Id Discord.ChannelId, ThreadRoute )
    -> DiscordBackendGuild
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser
    -> Maybe DiscordFrontendGuild
discordGuildToFrontendForUser requestMessagesFor guild linkedDiscordUsers =
    if
        SeqDict.member (MembersAndOwner.owner guild.membersAndOwner) linkedDiscordUsers
            || not (SeqDict.isEmpty (SeqDict.intersect (MembersAndOwner.members guild.membersAndOwner) linkedDiscordUsers))
    then
        discordGuildToFrontend requestMessagesFor guild |> Just

    else
        Nothing


discordGuildToFrontend :
    Maybe ( Discord.Id Discord.ChannelId, ThreadRoute )
    -> DiscordBackendGuild
    -> DiscordFrontendGuild
discordGuildToFrontend requestMessagesFor guild =
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
    , membersAndOwner = guild.membersAndOwner
    , stickers = guild.stickers
    , customEmojis = guild.customEmojis
    }


discordDmChannelToFrontend :
    Bool
    -> DiscordDmChannel
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser
    -> Maybe DiscordFrontendDmChannel
discordDmChannelToFrontend preloadMessages dmChannel linkedDiscordUsers =
    if List.any (\( linkedId, _ ) -> NonemptyDict.member linkedId dmChannel.members) (SeqDict.toList linkedDiscordUsers) then
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
    , discordLinkingEnabled = model.discordLinkingEnabled
    , twoFactorAuthentication = SeqDict.map (\_ a -> a.finishedAt) model.twoFactorAuthentication
    , privateVapidKey = model.privateVapidKey
    , slackClientSecret = model.slackClientSecret
    , openRouterKey = model.openRouterKey
    , cloudflareRealtimeApiToken = model.cloudflareRealtimeApiToken
    , cloudflareRealtimeAppId = model.cloudflareRealtimeAppId
    , cloudflareAccountId = model.cloudflareAccountId
    , cloudflareAnalyticsApiToken = model.cloudflareAnalyticsApiToken
    , postmarkApiKey = model.postmarkApiKey
    , dmChannels =
        SeqDict.map
            (\_ channel ->
                { messageCount = Array.length channel.messages
                , threadCount = SeqDict.size channel.threads
                }
            )
            model.dmChannels
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
                , membersAndOwner = guild.membersAndOwner
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
                , memberCount = SeqDict.size (MembersAndOwner.members guild.membersAndOwner)
                , owner = MembersAndOwner.owner guild.membersAndOwner
                }
            )
            model.guilds
    , deletedGuilds =
        SeqDict.map
            (\_ deletedGuild ->
                { name = deletedGuild.guild.name
                , owner = MembersAndOwner.owner deletedGuild.guild.membersAndOwner
                , memberCount = SeqDict.size (MembersAndOwner.members deletedGuild.guild.membersAndOwner)
                , deletedAt = deletedGuild.deletedAt
                }
            )
            model.deletedGuilds
    , loadingDiscordChannels =
        SeqDict.map
            (\_ channel ->
                LocalState.loadingDiscordChannelMap
                    (List.foldl (\message count -> count + List.length message.attachments) 0)
                    channel
            )
            model.loadingDiscordChannels
    , logs = Pagination.init lastLogPageViewed model.logs
    , connections =
        SeqDict.toList model.connections
            |> List.map
                (\( sessionId, clients ) ->
                    ( case SeqDict.get sessionId model.sessions of
                        Just session ->
                            session.sessionIdHash

                        Nothing ->
                            SessionIdHash.fromString "Session not found"
                    , clients
                    )
                )
            |> SeqDict.fromList
    , filesCount = SeqDict.size model.files
    , toBackendLogs = Array.slice (Array.length model.toBackendLogs - 1000) (Array.length model.toBackendLogs) model.toBackendLogs
    , vulnerabilityChecks =
        case
            Bytes.Encode.sequence [ Bytes.Encode.unsignedInt8 255, Lamdera.Wire3.encodeFloat64 (0 / 0) ]
                |> Bytes.Encode.encode
                |> Bytes.Decode.decode Lamdera.Wire3.decodeInt
        of
            Just int ->
                "decodeInt not patched! " ++ String.fromInt int

            Nothing ->
                case
                    Bytes.Encode.sequence [ Bytes.Encode.unsignedInt8 255, Lamdera.Wire3.encodeFloat64 (1 / 0) ]
                        |> Bytes.Encode.encode
                        |> Bytes.Decode.decode Lamdera.Wire3.decodeInt
                of
                    Just int ->
                        "decodeInt not patched! " ++ String.fromInt int

                    Nothing ->
                        case
                            Bytes.Encode.sequence [ Bytes.Encode.unsignedInt8 255, Lamdera.Wire3.encodeFloat64 (-1 / 0) ]
                                |> Bytes.Encode.encode
                                |> Bytes.Decode.decode Lamdera.Wire3.decodeInt
                        of
                            Just int ->
                                "decodeInt not patched! " ++ String.fromInt int

                            Nothing ->
                                ""
    , serverSecretRegeneratedAt = model.serverSecretRegeneratedAt
    , websocketCloseEvents = model.websocketCloseEvents
    , sessions =
        SeqDict.values model.sessions
            |> List.map (\session -> ( session.sessionIdHash, session ))
            |> SeqDict.fromList
    }


sendGuildMessage :
    BackendModel
    -> Time.Posix
    -> ClientId
    -> ChangeId
    -> Id GuildId
    -> Id ChannelId
    -> ThreadRouteWithMaybeMessage
    -> NonemptyString
    -> SeqDict (Id FileId) FileData
    -> UserSession
    -> BackendUser
    -> BackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendGuildMessage model time clientId changeId guildId channelId threadRouteWithMaybeReplyTo text attachedFiles session user guild =
    case ( SeqDict.get channelId guild.channels, RateLimit.checkAndUpdateRateLimit time session.userId model.sendMessageRateLimits ) of
        ( Just channel, Ok sendMessageRateLimits ) ->
            let
                richText : Nonempty (RichText (Id UserId))
                richText =
                    RichText.fromNonemptyString
                        (List.foldl
                            (\memberId dict ->
                                case NonemptyDict.get memberId model.users of
                                    Just member ->
                                        SeqDict.insert memberId member dict

                                    Nothing ->
                                        dict
                            )
                            SeqDict.empty
                            (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                        )
                        text

                ( channel2, embedCmds, stickers ) =
                    case threadRouteWithMaybeReplyTo of
                        ViewThreadWithMaybeMessage threadId maybeReplyTo ->
                            let
                                ( message2, cmds, stickers2 ) =
                                    Message.userTextMessageBackend
                                        model.serverSecret
                                        time
                                        session.userId
                                        richText
                                        maybeReplyTo
                                        attachedFiles
                                        model.stickers

                                ( messageId, channel3 ) =
                                    LocalState.createThreadMessageBackend threadId message2 channel
                            in
                            ( channel3
                            , Command.map
                                identity
                                (GotGuildMessageEmbed guildId channelId (ViewThreadWithMessage threadId messageId))
                                cmds
                            , stickers2
                            )

                        NoThreadWithMaybeMessage maybeReplyTo ->
                            let
                                ( message2, cmds, stickers2 ) =
                                    Message.userTextMessageBackend
                                        model.serverSecret
                                        time
                                        session.userId
                                        richText
                                        maybeReplyTo
                                        attachedFiles
                                        model.stickers

                                ( messageId, channel3 ) =
                                    LocalState.createChannelMessageBackend message2 channel
                            in
                            ( channel3
                            , Command.map
                                identity
                                (GotGuildMessageEmbed guildId channelId (NoThreadWithMessage messageId))
                                cmds
                            , stickers2
                            )

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
                        richText
                        (MembersAndOwner.membersAndOwner guild.membersAndOwner)
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

                ( sessions, notificationCmds ) =
                    Broadcast.messageNotification
                        usersMentioned
                        time
                        session.userId
                        guildId
                        channelId
                        threadRouteNoReply
                        richText
                        (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                        model
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
                , sendMessageRateLimits = sendMessageRateLimits
                , sessions = sessions
              }
            , Command.batch
                [ LocalChangeResponse
                    changeId
                    (Local_SendMessage time guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles)
                    |> Lamdera.sendToFrontend clientId
                , Broadcast.toGuildExcludingOne
                    clientId
                    guildId
                    (Server_SendMessage
                        session.userId
                        time
                        guildOrDmId
                        richText
                        threadRouteWithMaybeReplyTo
                        attachedFiles
                        stickers
                        |> ServerChange
                    )
                    model
                , Command.batch notificationCmds
                , embedCmds
                ]
            )

        _ ->
            ( model, invalidChangeResponse changeId clientId )


sendDm :
    BackendModel
    -> Time.Posix
    -> ClientId
    -> ChangeId
    -> Id UserId
    -> ThreadRouteWithMaybeMessage
    -> NonemptyString
    -> SeqDict (Id FileId) FileData
    -> UserSession
    -> BackendUser
    -> BackendUser
    -> DmChannelId
    -> DmChannel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendDm model time clientId changeId otherUserId threadRouteWithReplyTo text attachedFiles session user otherUser dmChannelId dmChannel =
    let
        richText : Nonempty (RichText (Id UserId))
        richText =
            RichText.fromNonemptyString
                (SeqDict.fromList [ ( session.userId, user ), ( otherUserId, otherUser ) ])
                text
    in
    case ( threadRouteWithReplyTo, RateLimit.checkAndUpdateRateLimit time session.userId model.sendMessageRateLimits ) of
        ( ViewThreadWithMaybeMessage threadId repliedTo, Ok sendMessageRateLimits ) ->
            let
                ( message, embedCmds, stickers ) =
                    Message.userTextMessageBackend
                        model.serverSecret
                        time
                        session.userId
                        richText
                        repliedTo
                        attachedFiles
                        model.stickers

                ( messageId, dmChannel2 ) =
                    LocalState.createThreadMessageBackend threadId message dmChannel

                ( sessions, notificationCmds ) =
                    Broadcast.broadcastDm
                        changeId
                        time
                        clientId
                        session.userId
                        otherUserId
                        text
                        richText
                        threadRouteWithReplyTo
                        attachedFiles
                        stickers
                        model
            in
            ( { model
                | dmChannels = SeqDict.insert dmChannelId dmChannel2 model.dmChannels
                , users =
                    NonemptyDict.insert
                        session.userId
                        { user
                            | lastViewedThreads =
                                SeqDict.insert
                                    ( GuildOrDmId (GuildOrDmId_Dm otherUserId), threadId )
                                    messageId
                                    user.lastViewedThreads
                        }
                        model.users
                , sendMessageRateLimits = sendMessageRateLimits
                , sessions = sessions
              }
            , Command.batch
                [ notificationCmds
                , Command.map identity (GotDmMessageEmbed dmChannelId (ViewThreadWithMessage threadId messageId)) embedCmds
                ]
            )

        ( NoThreadWithMaybeMessage repliedTo, Ok sendMessageRateLimits ) ->
            let
                ( message, embedCmds, stickers ) =
                    Message.userTextMessageBackend
                        model.serverSecret
                        time
                        session.userId
                        richText
                        repliedTo
                        attachedFiles
                        model.stickers

                ( messageId, dmChannel2 ) =
                    LocalState.createChannelMessageBackend message dmChannel

                ( sessions, notificationCmds ) =
                    Broadcast.broadcastDm
                        changeId
                        time
                        clientId
                        session.userId
                        otherUserId
                        text
                        richText
                        threadRouteWithReplyTo
                        attachedFiles
                        stickers
                        model
            in
            ( { model
                | dmChannels = SeqDict.insert dmChannelId dmChannel2 model.dmChannels
                , users =
                    NonemptyDict.insert
                        session.userId
                        { user
                            | lastViewed =
                                SeqDict.insert (GuildOrDmId (GuildOrDmId_Dm otherUserId)) messageId user.lastViewed
                        }
                        model.users
                , sendMessageRateLimits = sendMessageRateLimits
                , sessions = sessions
              }
            , Command.batch
                [ notificationCmds
                , Command.map identity (GotDmMessageEmbed dmChannelId (NoThreadWithMessage messageId)) embedCmds
                ]
            )

        _ ->
            ( model, invalidChangeResponse changeId clientId )


handleDrawingChange :
    SessionId
    -> ClientId
    -> ChangeId
    -> AnyGuildOrDmId
    -> ThreadRouteWithMessage
    -> Drawing.LocalChange
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDrawingChange sessionId clientId changeId guildOrDmId threadRoute drawingChange model =
    let
        localMsg : LocalChange
        localMsg =
            Local_Drawing guildOrDmId threadRoute drawingChange
    in
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild guildId channelId) ->
            asGuildMember
                model
                sessionId
                guildId
                (\{ userId } _ guild ->
                    case SeqDict.get channelId guild.channels of
                        Just channel ->
                            ( { model
                                | guilds =
                                    SeqDict.insert
                                        guildId
                                        { guild
                                            | channels =
                                                SeqDict.insert
                                                    channelId
                                                    (LocalState.drawingHandleChangeHelperBackend
                                                        userId
                                                        drawingChange
                                                        threadRoute
                                                        channel
                                                    )
                                                    guild.channels
                                        }
                                        model.guilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_Drawing userId guildOrDmId threadRoute drawingChange |> ServerChange)
                                    model
                                ]
                            )

                        Nothing ->
                            ( model, invalidChangeResponse changeId clientId )
                )

        GuildOrDmId (GuildOrDmId_Dm otherUserId) ->
            asDmUser
                model
                sessionId
                { otherUserId = otherUserId }
                (\session _ _ dmChannelId dmChannel ->
                    ( { model
                        | dmChannels =
                            SeqDict.insert dmChannelId
                                (LocalState.drawingHandleChangeHelperBackend
                                    session.userId
                                    drawingChange
                                    threadRoute
                                    dmChannel
                                )
                                model.dmChannels
                      }
                    , Command.batch
                        [ LocalChangeResponse changeId localMsg
                            |> Lamdera.sendToFrontend clientId
                        , Broadcast.toDmChannelExcludingOne
                            clientId
                            session.userId
                            otherUserId
                            (\otherUserId2 ->
                                Server_Drawing
                                    session.userId
                                    (GuildOrDmId (GuildOrDmId_Dm otherUserId2))
                                    threadRoute
                                    drawingChange
                            )
                            model
                        ]
                    )
                )

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild currentDiscordUserId guildId channelId) ->
            asDiscordGuildMember
                model
                sessionId
                guildId
                currentDiscordUserId
                (\session _ _ guild ->
                    case SeqDict.get channelId guild.channels of
                        Just channel ->
                            ( { model
                                | discordGuilds =
                                    SeqDict.insert
                                        guildId
                                        { guild
                                            | channels =
                                                SeqDict.insert
                                                    channelId
                                                    (LocalState.drawingHandleChangeHelperBackend
                                                        currentDiscordUserId
                                                        drawingChange
                                                        threadRoute
                                                        channel
                                                    )
                                                    guild.channels
                                        }
                                        model.discordGuilds
                              }
                            , Command.batch
                                [ LocalChangeResponse changeId localMsg
                                    |> Lamdera.sendToFrontend clientId
                                , Broadcast.toDiscordGuildExcludingOne
                                    clientId
                                    guildId
                                    (Server_Drawing session.userId guildOrDmId threadRoute drawingChange |> ServerChange)
                                    model
                                ]
                            )

                        Nothing ->
                            ( model, invalidChangeResponse changeId clientId )
                )

        DiscordGuildOrDmId (DiscordGuildOrDmId_Dm data) ->
            asDiscordDmUser
                model
                sessionId
                data
                (\session _ _ dmChannel ->
                    ( { model
                        | discordDmChannels =
                            SeqDict.insert
                                data.channelId
                                (case threadRoute of
                                    NoThreadWithMessage messageId ->
                                        LocalState.drawingHandleChangeNoThreadBackend
                                            data.currentUserId
                                            drawingChange
                                            messageId
                                            dmChannel

                                    ViewThreadWithMessage _ _ ->
                                        dmChannel
                                )
                                model.discordDmChannels
                      }
                    , Command.batch
                        [ LocalChangeResponse changeId localMsg
                            |> Lamdera.sendToFrontend clientId
                        , Broadcast.toDiscordDmChannelExcludingOne
                            clientId
                            data.channelId
                            (Server_Drawing session.userId guildOrDmId threadRoute drawingChange |> ServerChange)
                            model
                        ]
                    )
                )


toBackendLog : ToBackend -> ToBackendLog
toBackendLog toBackend =
    case toBackend of
        CheckLoginRequest _ ->
            ToBackendLog_CheckLoginRequest

        LoginWithTokenRequest _ _ _ ->
            ToBackendLog_LoginWithTokenRequest

        LoginWithTwoFactorRequest _ _ _ ->
            ToBackendLog_LoginWithTwoFactorRequest

        GetLoginTokenRequest _ ->
            ToBackendLog_GetLoginTokenRequest

        AdminToBackend _ ->
            ToBackendLog_AdminToBackend

        LogOutRequest ->
            ToBackendLog_LogOutRequest

        LocalModelChangeRequest _ localChange ->
            case localChange of
                Local_Invalid ->
                    ToBackendLog_Local_Invalid

                Local_Admin _ ->
                    ToBackendLog_Local_Admin

                Local_SendMessage _ _ _ _ _ ->
                    ToBackendLog_Local_SendMessage

                Local_Discord_SendMessage _ _ _ _ _ ->
                    ToBackendLog_Local_Discord_SendMessage

                Local_NewChannel _ _ _ _ ->
                    ToBackendLog_Local_NewChannel

                Local_EditChannel _ _ _ _ ->
                    ToBackendLog_Local_EditChannel

                Local_DeleteChannel _ _ ->
                    ToBackendLog_Local_DeleteChannel

                Local_DeleteGuild _ ->
                    ToBackendLog_Local_DeleteGuild

                Local_NewInviteLink _ _ _ ->
                    ToBackendLog_Local_NewInviteLink

                Local_DeleteInviteLink _ _ ->
                    ToBackendLog_Local_DeleteInviteLink

                Local_NewGuild _ _ _ ->
                    ToBackendLog_Local_NewGuild

                Local_MemberTyping _ _ ->
                    ToBackendLog_Local_MemberTyping

                Local_AddReactionEmoji _ _ _ ->
                    ToBackendLog_Local_AddReactionEmoji

                Local_RemoveReactionEmoji _ _ _ ->
                    ToBackendLog_Local_RemoveReactionEmoji

                Local_SendEditMessage _ _ _ _ _ ->
                    ToBackendLog_Local_SendEditMessage

                Local_Discord_SendEditGuildMessage _ _ _ _ _ _ ->
                    ToBackendLog_Local_Discord_SendEditGuildMessage

                Local_Discord_SendEditDmMessage _ _ _ _ ->
                    ToBackendLog_Local_Discord_SendEditDmMessage

                Local_MemberEditTyping _ _ _ ->
                    ToBackendLog_Local_MemberEditTyping

                Local_SetLastViewed _ _ ->
                    ToBackendLog_Local_SetLastViewed

                Local_DeleteMessage _ _ ->
                    ToBackendLog_Local_DeleteMessage

                Local_CurrentlyViewing _ ->
                    ToBackendLog_Local_CurrentlyViewing

                Local_SetName _ ->
                    ToBackendLog_Local_SetName

                Local_LoadChannelMessages _ _ _ ->
                    ToBackendLog_Local_LoadChannelMessages

                Local_LoadThreadMessages _ _ _ _ ->
                    ToBackendLog_Local_LoadThreadMessages

                Local_Discord_LoadChannelMessages _ _ _ ->
                    ToBackendLog_Local_Discord_LoadChannelMessages

                Local_Discord_LoadThreadMessages _ _ _ _ ->
                    ToBackendLog_Local_Discord_LoadThreadMessages

                Local_SetGuildNotificationLevel _ _ ->
                    ToBackendLog_Local_SetGuildNotificationLevel

                Local_SetDiscordGuildNotificationLevel _ _ _ ->
                    ToBackendLog_Local_SetDiscordGuildNotificationLevel

                Local_SetNotificationMode _ ->
                    ToBackendLog_Local_SetNotificationMode

                Local_RegisterPushSubscription _ _ ->
                    ToBackendLog_Local_RegisterPushSubscription

                Local_TextEditor _ ->
                    ToBackendLog_Local_TextEditor

                Local_UnlinkDiscordUser _ ->
                    ToBackendLog_Local_UnlinkDiscordUser

                Local_StartReloadingDiscordUser _ _ ->
                    ToBackendLog_Local_StartReloadingDiscordUser

                Local_LinkDiscordAcknowledgementIsChecked _ ->
                    ToBackendLog_Local_LinkDiscordAcknowledgementIsChecked

                Local_SetDomainWhitelist _ _ ->
                    ToBackendLog_Local_SetDomainWhitelist

                Local_SetEmojiCategory _ ->
                    ToBackendLog_Local_SetEmojiCategory

                Local_SetEmojiSkinTone _ ->
                    ToBackendLog_Local_SetEmojiSkinTone

                Local_AddCustomEmojisToUser _ ->
                    ToBackendLog_Local_AddCustomEmojisToUser

                Local_VoiceChatChange _ ->
                    ToBackendLog_Local_VoiceChatChange

                Local_Go _ _ ->
                    ToBackendLog_Local_Go

                Local_Drawing _ _ _ ->
                    ToBackendLog_Local_Drawing

        TwoFactorToBackend _ ->
            ToBackendLog_TwoFactorToBackend

        JoinGuildByInviteRequest _ _ ->
            ToBackendLog_JoinGuildByInviteRequest

        FinishUserCreationRequest _ _ _ ->
            ToBackendLog_FinishUserCreationRequest

        AiChatToBackend _ ->
            ToBackendLog_AiChatToBackend

        ReloadDataRequest _ ->
            ToBackendLog_ReloadDataRequest

        LinkSlackOAuthCode _ _ ->
            ToBackendLog_LinkSlackOAuthCode

        LinkDiscordRequest _ ->
            ToBackendLog_LinkDiscordRequest

        ProfilePictureEditorToBackend _ ->
            ToBackendLog_ProfilePictureEditorToBackend

        AdminDataRequest _ ->
            ToBackendLog_AdminDataRequest

        GetPublicGoMatchRequest _ ->
            ToBackendLog_GetPublicGoMatchRequest


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
                    case MembersAndOwner.isMember session.userId guild.membersAndOwner of
                        IsNotMember ->
                            ( model, Command.none )

                        IsMember ->
                            func session user guild

                        IsOwner ->
                            func session user guild

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asDiscordGuildMember :
    BackendModel
    -> SessionId
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.UserId
    -> (UserSession -> DiscordFullUserData -> BackendUser -> DiscordBackendGuild -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordGuildMember model sessionId guildId discordUserId func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case
                ( NonemptyDict.get session.userId model.users
                , SeqDict.get guildId model.discordGuilds
                , SeqDict.get discordUserId model.discordUsers
                )
            of
                ( Just user, Just guild, Just (FullData discordUser) ) ->
                    if discordUser.linkedTo == session.userId then
                        case MembersAndOwner.isMember discordUserId guild.membersAndOwner of
                            IsNotMember ->
                                ( model, Command.none )

                            IsMember ->
                                func session discordUser user guild

                            IsOwner ->
                                func session discordUser user guild

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asDiscordGuildMember_AllowUserThatNeedsAuthAgain :
    BackendModel
    -> SessionId
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.UserId
    -> (UserSession -> NeedsAuthAgainData -> BackendUser -> DiscordBackendGuild -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordGuildMember_AllowUserThatNeedsAuthAgain model sessionId guildId discordUserId func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case
                ( NonemptyDict.get session.userId model.users
                , SeqDict.get guildId model.discordGuilds
                , SeqDict.get discordUserId model.discordUsers
                )
            of
                ( Just user, Just guild, Just (FullData discordUser) ) ->
                    if discordUser.linkedTo == session.userId then
                        case MembersAndOwner.isMember discordUserId guild.membersAndOwner of
                            IsNotMember ->
                                ( model, Command.none )

                            IsMember ->
                                func
                                    session
                                    { user = discordUser.user
                                    , linkedTo = discordUser.linkedTo
                                    , icon = discordUser.icon
                                    , linkedAt = discordUser.linkedAt
                                    }
                                    user
                                    guild

                            IsOwner ->
                                func
                                    session
                                    { user = discordUser.user
                                    , linkedTo = discordUser.linkedTo
                                    , icon = discordUser.icon
                                    , linkedAt = discordUser.linkedAt
                                    }
                                    user
                                    guild

                    else
                        ( model, Command.none )

                ( Just user, Just guild, Just (NeedsAuthAgain discordUser) ) ->
                    if discordUser.linkedTo == session.userId then
                        case MembersAndOwner.isMember discordUserId guild.membersAndOwner of
                            IsNotMember ->
                                ( model, Command.none )

                            IsMember ->
                                func session discordUser user guild

                            IsOwner ->
                                func session discordUser user guild

                    else
                        ( model, Command.none )

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
        (\session user guild ->
            case MembersAndOwner.isMember session.userId guild.membersAndOwner of
                IsOwner ->
                    func session.userId user guild

                IsMember ->
                    ( model, Command.none )

                IsNotMember ->
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


asDmUser :
    BackendModel
    -> SessionId
    -> { otherUserId : Id UserId }
    -> (UserSession -> BackendUser -> BackendUser -> DmChannelId -> DmChannel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDmUser model sessionId { otherUserId } func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            let
                dmChannelId =
                    DmChannel.channelIdFromUserIds session.userId otherUserId
            in
            case
                ( NonemptyDict.get session.userId model.users
                , NonemptyDict.get otherUserId model.users
                , SeqDict.get dmChannelId model.dmChannels
                )
            of
                ( Just user, Just otherUser, Just dmChannel ) ->
                    func session user otherUser dmChannelId dmChannel

                ( Just user, Just otherUser, Nothing ) ->
                    if usersHaveSharedGuilds session.userId otherUserId model then
                        func session user otherUser dmChannelId DmChannel.backendInit

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


usersHaveSharedGuilds : Id UserId -> Id UserId -> BackendModel -> Bool
usersHaveSharedGuilds userIdA userIdB model =
    SeqDict.foldl
        (\_ guild haveShared ->
            haveShared
                || (MembersAndOwner.isMember userIdA guild.membersAndOwner /= IsNotMember)
                && (MembersAndOwner.isMember userIdB guild.membersAndOwner /= IsNotMember)
        )
        False
        model.guilds


asDiscordUser :
    BackendModel
    -> SessionId
    -> Discord.Id Discord.UserId
    ->
        (UserSession
         -> DiscordFullUserData
         -> BackendUser
         -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        )
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordUser model sessionId discordUserId func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case ( NonemptyDict.get session.userId model.users, SeqDict.get discordUserId model.discordUsers ) of
                ( Just user, Just (FullData discordUser) ) ->
                    if discordUser.linkedTo == session.userId then
                        func session discordUser user

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asDiscordDmUser :
    BackendModel
    -> SessionId
    -> DiscordGuildOrDmId_DmData
    ->
        (UserSession
         -> DiscordFullUserData
         -> BackendUser
         -> DiscordDmChannel
         -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        )
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordDmUser model sessionId { currentUserId, channelId } func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case
                ( NonemptyDict.get session.userId model.users
                , SeqDict.get currentUserId model.discordUsers
                , SeqDict.get channelId model.discordDmChannels
                )
            of
                ( Just user, Just (FullData discordUser), Just dmChannel ) ->
                    if discordUser.linkedTo == session.userId && NonemptyDict.member currentUserId dmChannel.members then
                        func session discordUser user dmChannel

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asDiscordDmUser_AllowUserThatNeedsAuthAgain :
    BackendModel
    -> SessionId
    -> DiscordGuildOrDmId_DmData
    ->
        (UserSession
         -> NeedsAuthAgainData
         -> BackendUser
         -> DiscordDmChannel
         -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        )
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordDmUser_AllowUserThatNeedsAuthAgain model sessionId { currentUserId, channelId } func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case
                ( NonemptyDict.get session.userId model.users
                , SeqDict.get currentUserId model.discordUsers
                , SeqDict.get channelId model.discordDmChannels
                )
            of
                ( Just user, Just (FullData discordUser), Just dmChannel ) ->
                    if discordUser.linkedTo == session.userId && NonemptyDict.member currentUserId dmChannel.members then
                        func
                            session
                            { user = discordUser.user
                            , linkedTo = discordUser.linkedTo
                            , icon = discordUser.icon
                            , linkedAt = discordUser.linkedAt
                            }
                            user
                            dmChannel

                    else
                        ( model, Command.none )

                ( Just user, Just (NeedsAuthAgain discordUser), Just dmChannel ) ->
                    if discordUser.linkedTo == session.userId && NonemptyDict.member currentUserId dmChannel.members then
                        func session discordUser user dmChannel

                    else
                        ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )
