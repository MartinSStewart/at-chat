module BackendExtra exposing
    ( addLog
    , addLogWithCmd
    , adminData
    , asAdmin
    , asDiscordDmUser
    , asDiscordDmUser_AllowUserThatNeedsAuthAgain
    , asDiscordGuildChannelMember
    , asDiscordGuildChannelMember_AllowUserThatNeedsAuthAgain
    , asDiscordGuildMember
    , asDiscordUser
    , asDmUser
    , asDmUserRpc
    , asGuildMember
    , asGuildMemberRpc
    , asGuildOwner
    , asUser
    , channelDataToDecrypt
    , decryptOldMessages
    , discordDmChannelToFrontend
    , discordGuildToFrontend
    , discordGuildToFrontendForUser
    , dmChannelsThatNeedEncrypting
    , encryptOldMessages
    , getLinkedDiscordUsersAndOtherUsers
    , getLoginCode
    , getLoginData
    , handleDrawingChange
    , invalidChangeResponse
    , loginEmailContent
    , loginEmailSubject
    , loginWithToken
    , ownMessageIsReadBackend
    , requestedForToGuildOrDmId
    , sendDm
    , sendEncryptedDm
    , sendGuildMessage
    , sendLoginEmail
    , shouldRateLimit
    , toBackendLog
    , unreadOverviewData
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
import DmChannel exposing (BackendDmChannel, DiscordDmChannel, DiscordFrontendDmChannel, FrontendDmChannel)
import DmChannelId exposing (DmChannelId)
import Drawing
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera as Lamdera exposing (ClientId, SessionId)
import Effect.Task as Task
import Effect.Time as Time
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Emoji exposing (EmojiOrCustomEmoji)
import Encryption exposing (EncryptedData)
import FileStatus exposing (FileData, FileHash, FileId)
import Hex
import Http
import Id exposing (AnyGuildOrDmId(..), ChannelId, ChannelMessageId, DiscordGuildOrDmId(..), GuildId, GuildOrDmId(..), Id, ThreadMessageId, ThreadRoute(..), ThreadRouteWithMaybeMessage(..), ThreadRouteWithMessage(..), UserId, Viewing_ChannelId, Viewing_DiscordChannelId, Viewing_DiscordDmId, Viewing_DmId)
import IdArray exposing (IdArray)
import Lamdera.Wire3
import LinkedAndOtherDiscordUsers exposing (DiscordFrontendCurrentUser, LinkedAndOtherDiscordUsers)
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Local exposing (ChangeId)
import LocalState exposing (BackendGuild, CallStatus(..), ChannelStatus(..), ConnectionData, DiscordBackendChannel, DiscordBackendGuild, DiscordFrontendGuild, DiscordUserData_ForAdmin(..), FrontendGuild, LastRequest(..))
import Log exposing (Log)
import LoginForm
import Maybe.Extra
import MembersAndOwner exposing (IsMember(..))
import Message exposing (Message(..), MessageContent)
import NonemptyDict exposing (NonemptyDict)
import Pages.Admin exposing (InitAdminData)
import Pagination exposing (PageId)
import Postmark
import Quantity
import RateLimit
import RichText exposing (RichText)
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import SeqDictHelper
import SeqSet exposing (SeqSet)
import SessionIdHash
import String.Nonempty exposing (NonemptyString(..))
import Thread
import ToBackendLog exposing (ToBackendLog(..))
import Types exposing (AdminStatusLoginData(..), BackendFileData, BackendModel, BackendMsg(..), ChannelDataToDecrypt, ChannelDataToEncrypt, InitialLoadRequest(..), LocalChange(..), LocalMsg(..), LoginData, LoginResult(..), LoginTokenData(..), ServerChange(..), ToBackend(..), ToFrontend(..))
import Unsafe
import User exposing (BackendUser, FrontendUser)
import UserAgent exposing (UserAgent)
import UserSession exposing (DiscordFrontendUser, UserSession)
import VisibleMessages
import WordSpellingGame exposing (WordList(..))


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


requestedForToGuildOrDmId : Id UserId -> InitialLoadRequest -> UserSession.Viewing
requestedForToGuildOrDmId userId requestMessagesFor =
    case requestMessagesFor of
        InitialLoadRequested_None ->
            UserSession.Viewing_None

        InitialLoadRequested_DiscordGuild discordUserId guildId channelId threadRoute ->
            case threadRoute of
                NoThread ->
                    UserSession.Viewing_DiscordChannel
                        { id = { guildId = guildId, channelId = channelId, currentUserId = discordUserId }
                        , previouslyLastViewedMessage = UserSession.DontCare
                        }

                ViewThread threadId ->
                    UserSession.Viewing_DiscordChannelThread
                        { id =
                            { guildId = guildId
                            , channelId = channelId
                            , currentUserId = discordUserId
                            , threadId = threadId
                            }
                        , previouslyLastViewedMessage = UserSession.DontCare
                        }

        InitialLoadRequested_DiscordDm discordUserId channelId ->
            UserSession.Viewing_DiscordDm
                { id = { currentUserId = discordUserId, channelId = channelId }
                , previouslyLastViewedMessage = UserSession.DontCare
                }

        InitialLoadRequested_Admin _ ->
            UserSession.Viewing_None

        InitialLoadRequested_Guild guildId channelId threadRoute tab ->
            case threadRoute of
                NoThread ->
                    UserSession.Viewing_Channel
                        { id = { guildId = guildId, channelId = channelId }
                        , channelHeaderTab = tab
                        , previouslyLastViewedMessage = UserSession.DontCare
                        }

                ViewThread threadId ->
                    UserSession.Viewing_ChannelThread
                        { id = { guildId = guildId, channelId = channelId, threadId = threadId }
                        , previouslyLastViewedMessage = UserSession.DontCare
                        }

        InitialLoadRequested_Dm dmChannelId threadRoute tab ->
            case DmChannelId.otherUserId userId dmChannelId of
                Just otherUserId ->
                    case threadRoute of
                        NoThread ->
                            UserSession.Viewing_Dm
                                { id = { otherUserId = otherUserId }
                                , channelHeaderTab = tab
                                , previouslyLastViewedMessage = UserSession.DontCare
                                }

                        ViewThread threadId ->
                            UserSession.Viewing_DmThread
                                { id = { otherUserId = otherUserId, threadId = threadId }
                                , previouslyLastViewedMessage = UserSession.DontCare
                                }

                Nothing ->
                    UserSession.Viewing_None


{-| What the unread overview needs: the newest unread messages of every channel and thread
the user hasn't read to the end, plus the Discord users those messages show the names of.

Only channels the user is allowed to see are included.

-}
unreadOverviewData : Id UserId -> BackendUser -> BackendModel -> UserSession.UnreadOverviewData
unreadOverviewData userId user model =
    let
        linkedDiscordUserIds : List (Discord.Id Discord.UserId)
        linkedDiscordUserIds =
            SeqDict.foldr
                (\discordUserId userData list ->
                    case userData of
                        FullData data ->
                            if data.linkedTo == userId then
                                discordUserId :: list

                            else
                                list

                        NeedsAuthAgain data ->
                            if data.linkedTo == userId then
                                discordUserId :: list

                            else
                                list

                        BasicData _ ->
                            list
                )
                []
                model.discordUsers

        discordGuilds :
            { channels :
                SeqDict
                    ( Discord.Id Discord.GuildId, Discord.Id Discord.ChannelId )
                    (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id Discord.UserId)))
            , threads :
                SeqDict
                    ( Discord.Id Discord.GuildId, Discord.Id Discord.ChannelId, Id ChannelMessageId )
                    (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Discord.Id Discord.UserId)))
            }
        discordGuilds =
            SeqDict.foldl
                (\guildId guild dict ->
                    -- The frontend shows a Discord guild as whichever of our linked Discord
                    -- users is a member of it, and that's the user the unread state is
                    -- tracked for, so pick the same one here.
                    case
                        List.Extra.find
                            (\discordUserId -> MembersAndOwner.isMember discordUserId guild.membersAndOwner /= IsNotMember)
                            linkedDiscordUserIds
                    of
                        Just discordUserId ->
                            SeqDict.foldl
                                (\channelId channel dict2 ->
                                    let
                                        guildOrDmId : AnyGuildOrDmId
                                        guildOrDmId =
                                            DiscordGuildOrDmId
                                                (DiscordGuildOrDmId_Guild
                                                    { currentUserId = discordUserId, guildId = guildId, channelId = channelId }
                                                )
                                    in
                                    if LocalState.canViewDiscordChannel guildId channel guild discordUserId then
                                        case channel.status of
                                            ChannelActive ->
                                                { channels =
                                                    case
                                                        unreadMessages
                                                            (SeqDict.get guildOrDmId user.lastViewedMessage)
                                                            channel
                                                    of
                                                        Just messages ->
                                                            SeqDict.insert ( guildId, channelId ) messages dict2.channels

                                                        Nothing ->
                                                            dict2.channels
                                                , threads =
                                                    SeqDict.foldl
                                                        (\threadId thread dict3 ->
                                                            case
                                                                unreadMessages
                                                                    (SeqDict.get ( guildOrDmId, threadId ) user.lastViewedThreadMessage)
                                                                    thread
                                                            of
                                                                Just messages ->
                                                                    SeqDict.insert
                                                                        ( guildId, channelId, threadId )
                                                                        messages
                                                                        dict3

                                                                Nothing ->
                                                                    dict3
                                                        )
                                                        dict2.threads
                                                        channel.threads
                                                }

                                            _ ->
                                                dict2

                                    else
                                        dict2
                                )
                                dict
                                guild.channels

                        Nothing ->
                            dict
                )
                { channels = SeqDict.empty, threads = SeqDict.empty }
                model.discordGuilds

        discordDmChannels :
            SeqDict
                (Discord.Id Discord.PrivateChannelId)
                (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Discord.Id Discord.UserId)))
        discordDmChannels =
            SeqDict.foldl
                (\channelId dmChannel dict ->
                    case
                        List.Extra.find
                            (\discordUserId -> NonemptyDict.member discordUserId dmChannel.members)
                            linkedDiscordUserIds
                    of
                        Just currentUserId ->
                            case
                                unreadMessages
                                    (SeqDict.get
                                        (DiscordGuildOrDmId (DiscordGuildOrDmId_Dm { currentUserId = currentUserId, channelId = channelId }))
                                        user.lastViewedMessage
                                    )
                                    dmChannel
                            of
                                Just messages ->
                                    SeqDict.insert channelId messages dict

                                Nothing ->
                                    dict

                        Nothing ->
                            dict
                )
                SeqDict.empty
                model.discordDmChannels

        guilds :
            { channels :
                SeqDict
                    ( Id GuildId, Id ChannelId )
                    (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId)))
            , threads :
                SeqDict
                    ( Id GuildId, Id ChannelId, Id ChannelMessageId )
                    (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId)))
            }
        guilds =
            SeqDict.foldl
                (\guildId guild dict ->
                    case MembersAndOwner.isMember userId guild.membersAndOwner of
                        IsNotMember ->
                            dict

                        _ ->
                            SeqDict.foldl
                                (\channelId channel dict2 ->
                                    let
                                        guildOrDmId : AnyGuildOrDmId
                                        guildOrDmId =
                                            GuildOrDmId (GuildOrDmId_Guild { guildId = guildId, channelId = channelId })
                                    in
                                    case channel.status of
                                        ChannelActive ->
                                            { channels =
                                                case unreadMessages (SeqDict.get guildOrDmId user.lastViewedMessage) channel of
                                                    Just messages ->
                                                        SeqDict.insert ( guildId, channelId ) messages dict2.channels

                                                    Nothing ->
                                                        dict2.channels
                                            , threads =
                                                SeqDict.foldl
                                                    (\threadId thread dict3 ->
                                                        case
                                                            unreadMessages
                                                                (SeqDict.get ( guildOrDmId, threadId ) user.lastViewedThreadMessage)
                                                                thread
                                                        of
                                                            Just messages ->
                                                                SeqDict.insert ( guildId, channelId, threadId ) messages dict3

                                                            Nothing ->
                                                                dict3
                                                    )
                                                    dict2.threads
                                                    channel.threads
                                            }

                                        _ ->
                                            dict2
                                )
                                dict
                                guild.channels
                )
                { channels = SeqDict.empty, threads = SeqDict.empty }
                model.guilds

        dms :
            { channels : SeqDict (Id UserId) (SeqDict (Id ChannelMessageId) (Message ChannelMessageId (Id UserId)))
            , threads :
                SeqDict
                    ( Id UserId, Id ChannelMessageId )
                    (SeqDict (Id ThreadMessageId) (Message ThreadMessageId (Id UserId)))
            }
        dms =
            SeqDict.foldl
                (\dmChannelId dmChannel dict ->
                    case DmChannelId.otherUserId userId dmChannelId of
                        Just otherUserId ->
                            let
                                guildOrDmId : AnyGuildOrDmId
                                guildOrDmId =
                                    GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId })
                            in
                            { channels =
                                case unreadMessages (SeqDict.get guildOrDmId user.lastViewedMessage) dmChannel of
                                    Just messages ->
                                        SeqDict.insert otherUserId messages dict.channels

                                    Nothing ->
                                        dict.channels
                            , threads =
                                SeqDict.foldl
                                    (\threadId thread dict2 ->
                                        case
                                            unreadMessages
                                                (SeqDict.get ( guildOrDmId, threadId ) user.lastViewedThreadMessage)
                                                thread
                                        of
                                            Just messages ->
                                                SeqDict.insert ( otherUserId, threadId ) messages dict2

                                            Nothing ->
                                                dict2
                                    )
                                    dict.threads
                                    dmChannel.threads
                            }

                        Nothing ->
                            dict
                )
                { channels = SeqDict.empty, threads = SeqDict.empty }
                model.dmChannels
    in
    { guildChannels = guilds.channels
    , guildThreads = guilds.threads
    , dmChannels = dms.channels
    , dmThreads = dms.threads
    , discordGuildChannels = discordGuilds.channels
    , discordGuildThreads = discordGuilds.threads
    , discordDmChannels = discordDmChannels
    , discordUsers =
        SeqDict.empty
            |> discordUsersInMessages model (SeqDict.values discordGuilds.channels ++ SeqDict.values discordDmChannels)
            |> discordUsersInMessages model (SeqDict.values discordGuilds.threads)
    }


{-| The Discord users the given messages show the names of, added to the users found so
far. Channel messages and thread messages are numbered differently, so they can't be put
in one list and are added in two passes instead.
-}
discordUsersInMessages :
    BackendModel
    -> List (SeqDict (Id messageId) (Message messageId (Discord.Id Discord.UserId)))
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
discordUsersInMessages model messageDicts foundSoFar =
    List.foldl
        (\messages dict ->
            SeqDict.foldl
                (\_ message dict2 ->
                    List.foldl
                        (\discordUserId dict3 ->
                            case SeqDict.get discordUserId model.discordUsers of
                                Just discordUser ->
                                    SeqDict.insert
                                        discordUserId
                                        (User.discordUserDataToFrontendUser model.users discordUser)
                                        dict3

                                Nothing ->
                                    dict3
                        )
                        dict2
                        (messageUserIds message)
                )
                dict
                messages
        )
        foundSoFar
        messageDicts


{-| The users a message shows the name of: whoever wrote it, plus anyone it mentions.
-}
messageUserIds : Message messageId userId -> List userId
messageUserIds message =
    case message of
        UserTextMessage data ->
            data.createdBy :: SeqSet.toList (RichText.mentionsUser data.content.content)

        EncryptedUserTextMessage data ->
            [ data.createdBy ]

        UserJoinedMessage _ userId _ _ ->
            [ userId ]

        DeletedMessage _ ->
            []

        CallStarted data ->
            [ data.startedBy ]

        GameStarted data ->
            [ data.startedBy ]


{-| The newest unread messages in a channel or thread, at most `unreadOverviewMessageLimit`
of them, keyed by the index they sit at. `Nothing` when the user has read it to the end.
-}
unreadMessages :
    Maybe (Id messageId)
    -> { a | messages : IdArray messageId (Message messageId userId) }
    -> Maybe (SeqDict (Id messageId) (Message messageId userId))
unreadMessages maybeLastViewed channel =
    let
        messageCount : Int
        messageCount =
            IdArray.length channel.messages

        oldestUnread : Int
        oldestUnread =
            case maybeLastViewed of
                Just lastViewed ->
                    Id.toInt lastViewed + 1

                Nothing ->
                    0

        oldestIncluded : Int
        oldestIncluded =
            max oldestUnread (messageCount - UserSession.unreadOverviewMessageLimit)
    in
    if oldestUnread < messageCount then
        IdArray.slice (Id.fromInt oldestIncluded) (Id.fromInt messageCount) channel.messages
            |> IdArray.toList
            |> List.indexedMap (\index message -> ( oldestIncluded + index |> Id.fromInt, message ))
            |> SeqDict.fromList
            |> Just

    else
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
                                currentlyViewing : UserSession.Viewing
                                currentlyViewing =
                                    requestedForToGuildOrDmId pendingLogin.userId requestMessagesFor

                                session : UserSession
                                session =
                                    UserSession.init time sessionId pendingLogin.userId userAgent
                            in
                            ( { model
                                | sessions = SeqDict.insert sessionId session model.sessions
                                , pendingLogins = SeqDict.remove sessionId model.pendingLogins
                              }
                            , Command.batch
                                [ getLoginData sessionId clientId currentlyViewing session user requestMessagesFor model
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
                                        , currentlyViewing = SeqDict.singleton clientId currentlyViewing
                                        , userAgent = session.userAgent
                                        , lastActiveAt = time
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


getLastActiveAt : Maybe (NonemptyDict ClientId ConnectionData) -> Maybe Time.Posix
getLastActiveAt connections =
    case connections of
        Just connections2 ->
            NonemptyDict.foldl
                (\_ connection lastActiveAt ->
                    case connection.lastRequest of
                        LastRequest lastRequest ->
                            timeMax lastRequest lastActiveAt

                        NoRequestsMade ->
                            lastActiveAt
                )
                (Time.millisToPosix 0)
                connections2
                |> Just

        Nothing ->
            Nothing


timeMax : Time.Posix -> Time.Posix -> Time.Posix
timeMax a b =
    max (Time.posixToMillis a) (Time.posixToMillis b) |> Time.millisToPosix


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
    -> UserSession.Viewing
    -> UserSession
    -> BackendUser
    -> InitialLoadRequest
    -> BackendModel
    -> LoginData
getLoginData sessionId clientId currentlyViewing session user requestMessagesFor model =
    let
        linkedAndOtherDiscordUsers =
            getLinkedDiscordUsersAndOtherUsers session.userId currentlyViewing model

        guilds : SeqDict (Id GuildId) FrontendGuild
        guilds =
            SeqDict.filterMap
                (\guildId guild ->
                    LocalState.guildToFrontendForUser
                        guildId
                        (case requestMessagesFor of
                            InitialLoadRequested_Guild guildIdB channelId threadRoute channelHeaderTab ->
                                if guildId == guildIdB then
                                    Just ( channelId, ( threadRoute, channelHeaderTab ) )

                                else
                                    Nothing

                            _ ->
                                Nothing
                        )
                        session.userId
                        model.goMatchPublicIds
                        guild
                )
                model.guilds

        dmChannels : SeqDict (Id UserId) FrontendDmChannel
        dmChannels =
            SeqDict.foldl
                (\dmChannelId dmChannel dict ->
                    case DmChannelId.otherUserId session.userId dmChannelId of
                        Just otherUserId ->
                            SeqDict.insert otherUserId
                                (DmChannel.toFrontend
                                    (case requestMessagesFor of
                                        InitialLoadRequested_Dm dmChannelIdB threadRoute channelHeaderTab ->
                                            if dmChannelId == dmChannelIdB then
                                                Just ( threadRoute, channelHeaderTab )

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
    in
    { session = session
    , currentlyViewing = currentlyViewing
    , adminData =
        if user.isAdmin then
            case requestMessagesFor of
                InitialLoadRequested_Admin logPage ->
                    IsAdminLoginData (adminData model (Maybe.withDefault user.lastLogPageViewed logPage))

                InitialLoadRequested_None ->
                    IsAdminButNoData

                InitialLoadRequested_Guild _ _ _ _ ->
                    IsAdminButNoData

                InitialLoadRequested_Dm _ _ _ ->
                    IsAdminButNoData

                InitialLoadRequested_DiscordGuild _ _ _ _ ->
                    IsAdminButNoData

                InitialLoadRequested_DiscordDm _ _ ->
                    IsAdminButNoData

        else
            IsNotAdminLoginData
    , twoFactorAuthenticationEnabled =
        SeqDict.get session.userId model.twoFactorAuthentication |> Maybe.map .finishedAt
    , guilds = guilds
    , discordGuilds =
        SeqDict.filterMap
            (\guildId guild ->
                discordGuildToFrontendForUser
                    (case requestMessagesFor of
                        InitialLoadRequested_DiscordGuild _ requestedGuildId requestChannelId threadRoute ->
                            if requestedGuildId == guildId then
                                Just ( requestChannelId, threadRoute )

                            else
                                Nothing

                        _ ->
                            Nothing
                    )
                    guildId
                    guild
                    (LinkedAndOtherDiscordUsers.linkedUsers linkedAndOtherDiscordUsers)
            )
            model.discordGuilds
    , discordDmChannels =
        SeqDict.filterMap
            (\dmChannelId dmChannel ->
                discordDmChannelToFrontend
                    (case requestMessagesFor of
                        InitialLoadRequested_DiscordDm _ requestedChannelId ->
                            dmChannelId == requestedChannelId

                        _ ->
                            False
                    )
                    dmChannel
                    (LinkedAndOtherDiscordUsers.linkedUsers linkedAndOtherDiscordUsers)
            )
            model.discordDmChannels
    , dmChannels = dmChannels
    , user = User.backendToFrontendCurrent user
    , otherUsers = visibleUsers session.userId guilds dmChannels model.users
    , discordUsers = linkedAndOtherDiscordUsers
    , otherSessions =
        SeqDict.remove sessionId model.sessions
            |> SeqDict.toList
            |> List.filterMap
                (\( otherSessionId, otherSession ) ->
                    let
                        connections : Maybe (NonemptyDict ClientId ConnectionData)
                        connections =
                            SeqDict.get otherSessionId model.connections
                    in
                    if session.userId == otherSession.userId then
                        ( otherSession.sessionIdHash
                        , { notificationMode = otherSession.notificationMode
                          , currentlyViewing =
                                case connections of
                                    Just connections2 ->
                                        SeqDict.map
                                            (\_ connection2 -> connection2.currentlyViewing)
                                            (NonemptyDict.toSeqDict connections2)

                                    Nothing ->
                                        SeqDict.empty
                          , userAgent = otherSession.userAgent
                          , lastActiveAt =
                                case otherSession.lastClientDisconnect of
                                    Just time ->
                                        Maybe.withDefault otherSession.signedInAt (getLastActiveAt connections)
                                            |> timeMax time

                                    Nothing ->
                                        Maybe.withDefault otherSession.signedInAt (getLastActiveAt connections)
                          }
                        )
                            |> Just

                    else
                        Nothing
                )
            |> SeqDict.fromList
    , publicVapidKey = model.publicVapidKey
    , textEditor = model.textEditor
    , stickers = model.stickers
    , customEmojis = model.customEmojis
    , voiceChatPeers = getVoiceChatData clientId session model
    }


{-| Only send the users this user is able to see, that is, the members of the guilds they
belong to and the people they have DMs with. Otherwise every account on the server would
be handed out to anyone who logs in.

If the frontend does encounter a user it hasn't heard of (someone who left a guild but
whose messages are still there, for example) then it gets told about them separately. See
`addMessageSender` in FrontendExtra.

-}
visibleUsers :
    Id UserId
    -> SeqDict (Id GuildId) FrontendGuild
    -> SeqDict (Id UserId) FrontendDmChannel
    -> NonemptyDict (Id UserId) BackendUser
    -> SeqDict (Id UserId) FrontendUser
visibleUsers userId guilds dmChannels users =
    let
        addUser : Id UserId -> SeqDict (Id UserId) FrontendUser -> SeqDict (Id UserId) FrontendUser
        addUser otherUserId dict =
            if otherUserId == userId then
                dict

            else
                case NonemptyDict.get otherUserId users of
                    Just otherUser ->
                        SeqDict.insert otherUserId (User.backendToFrontendForUser otherUser) dict

                    Nothing ->
                        dict
    in
    SeqDict.foldl
        (\_ guild dict ->
            List.foldl
                addUser
                dict
                (guild.createdBy
                    :: MembersAndOwner.membersAndOwner guild.membersAndOwner
                    ++ List.map .createdBy (SeqDict.values guild.invites)
                )
        )
        (SeqDict.foldl (\otherUserId _ dict -> addUser otherUserId dict) SeqDict.empty dmChannels)
        guilds


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
                    DmChannelId.fromUserIds otherSession.userId dmingWith.otherUserId
            in
            case DmChannelId.otherUserId session.userId dmChannelId of
                Just otherUserId ->
                    SeqDict.update
                        (DmRoomId { otherUserId = otherUserId })
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

        GuildRoomId id ->
            SeqDict.update
                (GuildRoomId id)
                (\maybe ->
                    case maybe of
                        Just nonempty ->
                            NonemptyDict.insert ( otherSession.userId, otherClientId ) remoteCallData nonempty |> Just

                        Nothing ->
                            NonemptyDict.singleton ( otherSession.userId, otherClientId ) remoteCallData |> Just
                )
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
                                ( ConnectedToCall roomId, False ) ->
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
    -> Discord.Id Discord.GuildId
    -> DiscordBackendGuild
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser
    -> Maybe DiscordFrontendGuild
discordGuildToFrontendForUser requestMessagesFor guildId guild linkedDiscordUsers =
    if
        SeqDict.member (MembersAndOwner.owner guild.membersAndOwner) linkedDiscordUsers
            || not (SeqDict.isEmpty (SeqDict.intersect (MembersAndOwner.members guild.membersAndOwner) linkedDiscordUsers))
    then
        discordGuildToFrontend requestMessagesFor linkedDiscordUsers guildId guild |> Just

    else
        Nothing


discordGuildToFrontend :
    Maybe ( Discord.Id Discord.ChannelId, ThreadRoute )
    -> SeqDict (Discord.Id Discord.UserId) a
    -> Discord.Id Discord.GuildId
    -> DiscordBackendGuild
    -> DiscordFrontendGuild
discordGuildToFrontend requestMessagesFor linkedDiscordUsers guildId guild =
    { name = guild.name
    , icon = guild.icon
    , channels =
        SeqDict.filterMap
            (\channelId channel ->
                LocalState.discordChannelToFrontend
                    guildId
                    guild
                    linkedDiscordUsers
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
    , roles = guild.roles
    }


discordDmChannelToFrontend :
    Bool
    -> DiscordDmChannel
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser
    -> Maybe DiscordFrontendDmChannel
discordDmChannelToFrontend preloadMessages dmChannel linkedDiscordUsers =
    if List.any (\( linkedId, _ ) -> NonemptyDict.member linkedId dmChannel.members) (SeqDict.toList linkedDiscordUsers) then
        { messages = DmChannel.toDiscordFrontendHelper preloadMessages { messages = dmChannel.messages, threads = SeqDict.empty }
        , visibleMessages = VisibleMessages.init preloadMessages (IdArray.length dmChannel.messages)
        , lastTypedAt = dmChannel.lastTypedAt
        , members = dmChannel.members
        , dateDividerDrawings = dmChannel.dateDividerDrawings
        }
            |> Just

    else
        Nothing


getLinkedDiscordUsersAndOtherUsers : Id UserId -> UserSession.Viewing -> BackendModel -> LinkedAndOtherDiscordUsers
getLinkedDiscordUsersAndOtherUsers userId currentlyViewing model =
    let
        linkedUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser
        linkedUsers =
            SeqDict.foldl
                (\discordUserId userData linkedDiscordUsers2 ->
                    case userData of
                        FullData data ->
                            if data.linkedTo == userId then
                                SeqDict.insert
                                    discordUserId
                                    (User.discordFullDataUserToFrontendCurrentUser model.users False data data.isLoadingData)
                                    linkedDiscordUsers2

                            else
                                linkedDiscordUsers2

                        BasicData _ ->
                            linkedDiscordUsers2

                        NeedsAuthAgain data ->
                            if data.linkedTo == userId then
                                SeqDict.insert
                                    discordUserId
                                    (User.discordFullDataUserToFrontendCurrentUser model.users True data DiscordUserLoadedSuccessfully)
                                    linkedDiscordUsers2

                            else
                                linkedDiscordUsers2
                )
                SeqDict.empty
                model.discordUsers

        linkedUserIds =
            SeqDict.keys linkedUsers

        isDmMember : DiscordDmChannel -> Bool
        isDmMember dmChannel =
            List.any (\linkedUserId -> NonemptyDict.member linkedUserId dmChannel.members) linkedUserIds

        isGuildMember : DiscordBackendGuild -> Bool
        isGuildMember guild =
            List.any
                (\linkedUserId ->
                    case MembersAndOwner.isMember linkedUserId guild.membersAndOwner of
                        IsNotMember ->
                            False

                        IsMember ->
                            True

                        IsOwner ->
                            True
                )
                linkedUserIds

        visibleDmUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
        visibleDmUsers =
            SeqDict.foldl
                (\_ dmChannel dict ->
                    if isDmMember dmChannel then
                        NonemptyDict.foldl
                            (\memberId _ dict2 ->
                                case SeqDict.get memberId model.discordUsers of
                                    Just discordUser ->
                                        SeqDict.insert
                                            memberId
                                            (User.discordUserDataToFrontendUser model.users discordUser)
                                            dict2

                                    Nothing ->
                                        dict2
                            )
                            dict
                            dmChannel.members

                    else
                        dict
                )
                SeqDict.empty
                model.discordDmChannels

        getDiscordGuild guildId =
            case SeqDict.get guildId model.discordGuilds of
                Just guild ->
                    if isGuildMember guild then
                        List.foldl
                            (\memberId dict2 ->
                                case SeqDict.get memberId model.discordUsers of
                                    Just discordUser ->
                                        SeqDict.insert
                                            memberId
                                            (User.discordUserDataToFrontendUser model.users discordUser)
                                            dict2

                                    Nothing ->
                                        dict2
                            )
                            visibleDmUsers
                            (MembersAndOwner.membersAndOwner guild.membersAndOwner)

                    else
                        visibleDmUsers

                Nothing ->
                    visibleDmUsers
    in
    LinkedAndOtherDiscordUsers.init
        (case currentlyViewing of
            UserSession.Viewing_Dm _ ->
                visibleDmUsers

            UserSession.Viewing_Channel _ ->
                visibleDmUsers

            UserSession.Viewing_DmThread _ ->
                visibleDmUsers

            UserSession.Viewing_ChannelThread _ ->
                visibleDmUsers

            UserSession.Viewing_DiscordChannel data ->
                getDiscordGuild data.id.guildId

            UserSession.Viewing_DiscordChannelThread data ->
                getDiscordGuild data.id.guildId

            UserSession.Viewing_DiscordDm _ ->
                visibleDmUsers

            UserSession.Viewing_None ->
                visibleDmUsers

            UserSession.Viewing_Overview ->
                -- The Discord users the overview needs are sent along with the overview
                -- itself (see `unreadOverviewData`), since which guilds they come from
                -- depends on which channels have unread messages.
                visibleDmUsers
        )
        linkedUsers


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
    , postmarkApiKey = model.postmarkApiKey
    , dmChannels =
        SeqDict.map
            (\_ channel ->
                { messageCount = IdArray.length channel.messages
                , threadCount = SeqDict.size channel.threads
                }
            )
            model.dmChannels
    , discordDmChannels =
        SeqDict.map
            (\_ channel ->
                { members = channel.members
                , messageCount = IdArray.length channel.messages
                , firstMessage = IdArray.get (Id.fromInt 0) channel.messages
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
                            , gateway =
                                { websocketIsOpen = Maybe.Extra.isJust data.connection.websocketHandle
                                , failedReconnectAttempts = data.connection.reconnect.failedAttempts
                                }
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
                            , messageCount = IdArray.length channel.messages
                            , threadCount = SeqDict.size channel.threads
                            , firstMessage = IdArray.get (Id.fromInt 0) channel.messages
                            , permissionOverwrites = channel.permissionOverwrites
                            }
                        )
                        guild.channels
                , membersAndOwner = guild.membersAndOwner
                , roles = guild.roles
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
                            , messageCount = IdArray.length channel.messages
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
                LocalState.loadingDiscordChannelMap LocalState.discordChannelReloadAttachmentCount channel
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
    , lastBackup = Maybe.map .backup model.lastBackup
    , websocketCloseEvents = model.websocketCloseEvents
    , sessions =
        SeqDict.values model.sessions
            |> List.map (\session -> ( session.sessionIdHash, session ))
            |> SeqDict.fromList
    , wordSpellingGameEnglish = wordListStatus model.wordSpellingGameEnglish
    , wordSpellingGameSwedish = wordListStatus model.wordSpellingGameSwedish
    }


wordListStatus : WordList -> LocalState.WordSpellingGameStatus
wordListStatus wordList =
    case wordList of
        WordList_NotLoaded ->
            LocalState.WordSpellingGameStatus_NotLoaded

        WordList_Loading ->
            LocalState.WordSpellingGameStatus_Loading

        WordList_Error error ->
            LocalState.WordSpellingGameStatus_Error error

        WordList_Loaded _ ->
            LocalState.WordSpellingGameStatus_Loaded


sendGuildMessage :
    BackendModel
    -> Time.Posix
    -> Time.Zone
    -> ClientId
    -> ChangeId
    -> Viewing_ChannelId
    -> ThreadRouteWithMaybeMessage
    -> NonemptyString
    -> SeqDict (Id FileId) FileData
    -> List EmojiOrCustomEmoji
    -> UserSession
    -> BackendUser
    -> BackendGuild
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendGuildMessage model time timezone clientId changeId id threadRouteWithMaybeReplyTo text attachedFiles emojis session user guild =
    case ( SeqDict.get id.channelId guild.channels, RateLimit.checkAndUpdateRateLimit time session.userId model.sendMessageRateLimits ) of
        ( Just channel, Ok sendMessageRateLimits ) ->
            let
                richText : Nonempty (RichText (Id UserId))
                richText =
                    RichText.fromNonemptyString
                        timezone
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

                threadRouteNoReply : ThreadRoute
                threadRouteNoReply =
                    case threadRouteWithMaybeReplyTo of
                        ViewThreadWithMaybeMessage threadId _ ->
                            ViewThread threadId

                        NoThreadWithMaybeMessage _ ->
                            NoThread

                ( ( usersMentioned, ( sessions, notificationCmds ), channel2 ), embedCmds, stickers ) =
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
                                    LocalState.createThreadMessageBackend threadId (UserTextMessage message2) channel

                                usersMentioned2 : SeqSet (Id UserId)
                                usersMentioned2 =
                                    LocalState.usersMentionedOrRepliedToBackend
                                        threadRouteWithMaybeReplyTo
                                        richText
                                        (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                        channel3

                                messageNotification =
                                    Broadcast.messageNotification
                                        usersMentioned2
                                        time
                                        session.userId
                                        id
                                        threadRouteNoReply
                                        message2
                                        (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                        model
                            in
                            ( ( usersMentioned2, messageNotification, channel3 )
                            , Command.map
                                identity
                                (GotGuildMessageEmbed id.guildId id.channelId (ViewThreadWithMessage threadId messageId))
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
                                    LocalState.createChannelMessageBackend (UserTextMessage message2) channel

                                usersMentioned2 : SeqSet (Id UserId)
                                usersMentioned2 =
                                    LocalState.usersMentionedOrRepliedToBackend
                                        threadRouteWithMaybeReplyTo
                                        richText
                                        (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                        channel3

                                messageNotification =
                                    Broadcast.messageNotification
                                        usersMentioned2
                                        time
                                        session.userId
                                        id
                                        threadRouteNoReply
                                        message2
                                        (MembersAndOwner.membersAndOwner guild.membersAndOwner)
                                        model
                            in
                            ( ( usersMentioned2, messageNotification, channel3 )
                            , Command.map
                                identity
                                (GotGuildMessageEmbed id.guildId id.channelId (NoThreadWithMessage messageId))
                                cmds
                            , stickers2
                            )

                guildOrDmId : GuildOrDmId
                guildOrDmId =
                    GuildOrDmId_Guild id

                newMessage : ThreadRouteWithMessage
                newMessage =
                    case threadRouteWithMaybeReplyTo of
                        ViewThreadWithMaybeMessage threadId _ ->
                            SeqDict.get threadId channel2.threads
                                |> Maybe.withDefault Thread.backendInit
                                |> DmChannel.latestThreadMessageId
                                |> ViewThreadWithMessage threadId

                        NoThreadWithMaybeMessage _ ->
                            DmChannel.latestMessageId channel2 |> NoThreadWithMessage

                viewers : SeqSet (Id UserId)
                viewers =
                    Broadcast.usersViewing (GuildOrDmId guildOrDmId) threadRouteNoReply model

                users2 : NonemptyDict (Id UserId) BackendUser
                users2 =
                    SeqSet.foldl
                        (\userId2 users ->
                            NonemptyDict.updateIfExists
                                userId2
                                (LocalState.incrementLastViewedMessageBackend
                                    (GuildOrDmId guildOrDmId)
                                    newMessage
                                )
                                users
                        )
                        model.users
                        viewers
                        |> (\users ->
                                SeqSet.foldl
                                    (\userId2 users3 ->
                                        if SeqSet.member userId2 viewers then
                                            users3

                                        else
                                            NonemptyDict.updateIfExists
                                                userId2
                                                (User.addDirectMention id.guildId id.channelId threadRouteNoReply)
                                                users3
                                    )
                                    users
                                    usersMentioned
                           )
            in
            ( { model
                | guilds =
                    SeqDict.insert
                        id.guildId
                        { guild | channels = SeqDict.insert id.channelId channel2 guild.channels }
                        model.guilds
                , users =
                    NonemptyDict.insert
                        session.userId
                        ((case threadRouteWithMaybeReplyTo of
                            ViewThreadWithMaybeMessage threadMessageIndex _ ->
                                { user
                                    | lastViewedThreadMessage =
                                        SeqDict.insert
                                            ( GuildOrDmId guildOrDmId, threadMessageIndex )
                                            (SeqDict.get threadMessageIndex channel2.threads
                                                |> Maybe.withDefault Thread.backendInit
                                                |> DmChannel.latestThreadMessageId
                                            )
                                            user.lastViewedThreadMessage
                                }

                            NoThreadWithMaybeMessage _ ->
                                { user
                                    | lastViewedMessage =
                                        SeqDict.insert
                                            (GuildOrDmId guildOrDmId)
                                            (DmChannel.latestMessageId channel2)
                                            user.lastViewedMessage
                                }
                         )
                            |> User.addRecentlyUsedEmojis emojis
                        )
                        users2
                , sendMessageRateLimits = sendMessageRateLimits
                , sessions = sessions
              }
            , Command.batch
                [ LocalChangeResponse
                    changeId
                    (Local_SendMessage time timezone guildOrDmId text threadRouteWithMaybeReplyTo attachedFiles emojis)
                    |> Lamdera.sendToFrontend clientId
                , Broadcast.toGuildExcludingOne
                    clientId
                    id.guildId
                    (Server_SendMessage
                        session.userId
                        (User.backendToFrontendForUser user)
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


{-| The card a call or a game leaves behind in a conversation is read the moment it exists
for the person who started it, the same as a message they wrote themselves.
-}
ownMessageIsReadBackend :
    Id UserId
    -> AnyGuildOrDmId
    -> Id ChannelMessageId
    -> NonemptyDict (Id UserId) BackendUser
    -> NonemptyDict (Id UserId) BackendUser
ownMessageIsReadBackend userId guildOrDmId messageId users =
    NonemptyDict.updateIfExists
        userId
        (User.setLastViewedMessage guildOrDmId (NoThreadWithMessage messageId))
        users


{-| The person on the other end of a DM keeps up with a message that arrives while they are
looking at the conversation. They know the DM by who they are talking to, which is the
sender, so that is the id their last viewed message is stored under.
-}
readerIsViewingDm :
    Id UserId
    -> Id UserId
    -> ThreadRouteWithMessage
    -> BackendModel
    -> NonemptyDict (Id UserId) BackendUser
readerIsViewingDm readerId senderId threadRoute model =
    let
        guildOrDmId : AnyGuildOrDmId
        guildOrDmId =
            GuildOrDmId (GuildOrDmId_Dm { otherUserId = senderId })
    in
    if
        SeqSet.member
            readerId
            (Broadcast.usersViewing guildOrDmId (Id.threadRouteWithoutMessage threadRoute) model)
    then
        NonemptyDict.updateIfExists
            readerId
            (LocalState.incrementLastViewedMessageBackend guildOrDmId threadRoute)
            model.users

    else
        model.users


dmChannelsThatNeedEncrypting : UserSession -> SeqDict DmChannelId BackendDmChannel -> SeqDict Viewing_DmId ChannelDataToEncrypt
dmChannelsThatNeedEncrypting session dmChannels =
    SeqDict.foldl
        (\dmChannelId dmChannel dict ->
            case
                ( DmChannelId.otherUserId session.userId dmChannelId
                , dmChannel.e2ee
                )
            of
                ( Just otherUserId, DmChannel.E2eeEnabled _ ) ->
                    let
                        conversation : ChannelDataToEncrypt
                        conversation =
                            { channel = plainTextMessages dmChannel.messages
                            , threads =
                                SeqDict.foldl
                                    (\threadId thread threads ->
                                        let
                                            plainText : SeqDict (Id ThreadMessageId) (MessageContent (Id UserId))
                                            plainText =
                                                plainTextMessages thread.messages
                                        in
                                        if SeqDict.isEmpty plainText then
                                            threads

                                        else
                                            SeqDict.insert threadId plainText threads
                                    )
                                    SeqDict.empty
                                    dmChannel.threads
                            }
                    in
                    if SeqDict.isEmpty conversation.channel && SeqDict.isEmpty conversation.threads then
                        dict

                    else
                        SeqDict.insert { otherUserId = otherUserId } conversation dict

                _ ->
                    dict
        )
        SeqDict.empty
        dmChannels


channelDataToDecrypt : BackendDmChannel -> ChannelDataToDecrypt
channelDataToDecrypt dmChannel =
    { channel = cipherTextMessages dmChannel.messages
    , threads =
        SeqDict.foldl
            (\threadId thread threads ->
                case NonemptyDict.fromSeqDict (cipherTextMessages thread.messages) of
                    Just nonempty ->
                        SeqDict.insert threadId nonempty threads

                    Nothing ->
                        threads
            )
            SeqDict.empty
            dmChannel.threads
    }


cipherTextMessages :
    IdArray messageId (Message messageId (Id UserId))
    -> SeqDict (Id messageId) (EncryptedData (MessageContent (Id UserId)))
cipherTextMessages messages =
    IdArray.foldlWithId
        (\messageId message dict ->
            case message of
                EncryptedUserTextMessage data ->
                    SeqDict.insert messageId data.content dict

                UserTextMessage _ ->
                    dict

                UserJoinedMessage _ _ _ _ ->
                    dict

                DeletedMessage _ ->
                    dict

                CallStarted _ ->
                    dict

                GameStarted _ ->
                    dict
        )
        SeqDict.empty
        messages


plainTextMessages :
    IdArray messageId (Message messageId (Id UserId))
    -> SeqDict (Id messageId) (MessageContent (Id UserId))
plainTextMessages messages =
    IdArray.foldlWithId
        (\messageId message dict ->
            case message of
                UserTextMessage data ->
                    SeqDict.insert messageId data.content dict

                EncryptedUserTextMessage _ ->
                    dict

                UserJoinedMessage _ _ _ _ ->
                    dict

                DeletedMessage _ ->
                    dict

                CallStarted _ ->
                    dict

                GameStarted _ ->
                    dict
        )
        SeqDict.empty
        messages


{-| Store and pass on a DM whose contents the server cannot read.

Almost everything `sendDm` does with a message needs the text: working out who was
mentioned, what to put in a notification, which links to fetch embeds for. None of that
is possible here, so this keeps only what is left, and the notification says a message
arrived without saying what it was.

-}
sendEncryptedDm :
    Time.Posix
    -> ClientId
    -> ChangeId
    -> Viewing_DmId
    -> SeqSet FileHash
    -> EncryptedData (MessageContent (Id UserId))
    -> ThreadRouteWithMaybeMessage
    -> UserSession
    -> BackendUser
    -> DmChannelId
    -> BackendDmChannel
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendEncryptedDm time clientId changeId id fileHashes contentAndEmbeds threadRouteWithReplyTo session user dmChannelId dmChannel model =
    case RateLimit.checkAndUpdateRateLimit time session.userId model.sendMessageRateLimits of
        Ok sendMessageRateLimits ->
            let
                ( threadRouteWithMessage, dmChannel2 ) =
                    case threadRouteWithReplyTo of
                        ViewThreadWithMaybeMessage threadId repliedTo ->
                            LocalState.createThreadMessageBackend
                                threadId
                                (Message.encryptedUserTextMessageFrontend time session.userId fileHashes contentAndEmbeds repliedTo)
                                dmChannel
                                |> Tuple.mapFirst (ViewThreadWithMessage threadId)

                        NoThreadWithMaybeMessage repliedTo ->
                            LocalState.createChannelMessageBackend
                                (Message.encryptedUserTextMessageFrontend time session.userId fileHashes contentAndEmbeds repliedTo)
                                dmChannel
                                |> Tuple.mapFirst NoThreadWithMessage

                ( sessions, notificationCmd ) =
                    Broadcast.encryptedDmNotification time session.userId id model
            in
            ( { model
                | dmChannels = SeqDict.insert dmChannelId dmChannel2 model.dmChannels
                , users =
                    NonemptyDict.insert
                        session.userId
                        (User.setLastViewedMessage
                            (GuildOrDmId (GuildOrDmId_Dm id))
                            threadRouteWithMessage
                            user
                        )
                        (readerIsViewingDm id.otherUserId session.userId threadRouteWithMessage model)
                , sendMessageRateLimits = sendMessageRateLimits
                , sessions = sessions
              }
            , Command.batch
                [ Local_SendEncryptedMessage time id fileHashes contentAndEmbeds threadRouteWithReplyTo
                    |> LocalChangeResponse changeId
                    |> Lamdera.sendToFrontend clientId
                , Broadcast.toDmChannelExcludingOne
                    clientId
                    session.userId
                    id
                    (\id2 ->
                        Server_SendEncryptedMessage
                            session.userId
                            (User.backendToFrontendForUser user)
                            time
                            id2
                            fileHashes
                            contentAndEmbeds
                            threadRouteWithReplyTo
                    )
                    model
                , notificationCmd
                ]
            )

        Err () ->
            ( model, invalidChangeResponse changeId clientId )


sendDm :
    BackendModel
    -> Time.Posix
    -> Time.Zone
    -> ClientId
    -> ChangeId
    -> Id UserId
    -> ThreadRouteWithMaybeMessage
    -> NonemptyString
    -> SeqDict (Id FileId) FileData
    -> List EmojiOrCustomEmoji
    -> UserSession
    -> BackendUser
    -> BackendUser
    -> DmChannelId
    -> BackendDmChannel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
sendDm model time timezone clientId changeId otherUserId threadRouteWithReplyTo text attachedFiles emojis session user otherUser dmChannelId dmChannel =
    let
        richText : Nonempty (RichText (Id UserId))
        richText =
            RichText.fromNonemptyString
                timezone
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
                    LocalState.createThreadMessageBackend threadId (UserTextMessage message) dmChannel

                ( sessions, notificationCmds ) =
                    Broadcast.broadcastDm
                        changeId
                        time
                        timezone
                        clientId
                        session.userId
                        (User.backendToFrontendForUser user)
                        otherUserId
                        text
                        message
                        threadRouteWithReplyTo
                        attachedFiles
                        emojis
                        stickers
                        model
            in
            ( { model
                | dmChannels = SeqDict.insert dmChannelId dmChannel2 model.dmChannels
                , users =
                    NonemptyDict.insert
                        session.userId
                        ({ user
                            | lastViewedThreadMessage =
                                SeqDict.insert
                                    ( GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId }), threadId )
                                    messageId
                                    user.lastViewedThreadMessage
                         }
                            |> User.addRecentlyUsedEmojis emojis
                        )
                        (readerIsViewingDm otherUserId session.userId (ViewThreadWithMessage threadId messageId) model)
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
                    LocalState.createChannelMessageBackend (Message.UserTextMessage message) dmChannel

                ( sessions, notificationCmds ) =
                    Broadcast.broadcastDm
                        changeId
                        time
                        timezone
                        clientId
                        session.userId
                        (User.backendToFrontendForUser user)
                        otherUserId
                        text
                        message
                        threadRouteWithReplyTo
                        attachedFiles
                        emojis
                        stickers
                        model
            in
            ( { model
                | dmChannels = SeqDict.insert dmChannelId dmChannel2 model.dmChannels
                , users =
                    NonemptyDict.insert
                        session.userId
                        ({ user
                            | lastViewedMessage =
                                SeqDict.insert (GuildOrDmId (GuildOrDmId_Dm { otherUserId = otherUserId })) messageId user.lastViewedMessage
                         }
                            |> User.addRecentlyUsedEmojis emojis
                        )
                        (readerIsViewingDm otherUserId session.userId (NoThreadWithMessage messageId) model)
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
    -> Drawing.AnchorType
    -> Drawing.LocalChange
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDrawingChange sessionId clientId changeId guildOrDmId anchor change model =
    let
        localMsg : LocalChange
        localMsg =
            Local_Drawing guildOrDmId anchor change
    in
    case guildOrDmId of
        GuildOrDmId (GuildOrDmId_Guild { guildId, channelId }) ->
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
                                                    (case anchor of
                                                        Drawing.MessageAnchor threadRoute anchor2 ->
                                                            LocalState.drawingHandleChangeHelperBackend
                                                                userId
                                                                change
                                                                threadRoute
                                                                anchor2
                                                                channel

                                                        Drawing.DateDividerAnchor threadRoute date ->
                                                            LocalState.drawingHandleDateDivider
                                                                threadRoute
                                                                date
                                                                userId
                                                                change
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
                                    (Server_Drawing userId guildOrDmId anchor change |> ServerChange)
                                    model
                                ]
                            )

                        Nothing ->
                            ( model, invalidChangeResponse changeId clientId )
                )

        GuildOrDmId (GuildOrDmId_Dm { otherUserId }) ->
            asDmUser
                model
                sessionId
                { otherUserId = otherUserId }
                (\session _ _ dmChannelId dmChannel ->
                    ( { model
                        | dmChannels =
                            SeqDict.insert dmChannelId
                                (case anchor of
                                    Drawing.MessageAnchor threadRoute anchor2 ->
                                        LocalState.drawingHandleChangeHelperBackend
                                            session.userId
                                            change
                                            threadRoute
                                            anchor2
                                            dmChannel

                                    Drawing.DateDividerAnchor threadRoute date ->
                                        LocalState.drawingHandleDateDivider
                                            threadRoute
                                            date
                                            session.userId
                                            change
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
                            { otherUserId = otherUserId }
                            (\otherUserId2 ->
                                Server_Drawing session.userId (GuildOrDmId (GuildOrDmId_Dm otherUserId2)) anchor change
                            )
                            model
                        ]
                    )
                )

        DiscordGuildOrDmId (DiscordGuildOrDmId_Guild { currentUserId, guildId, channelId }) ->
            asDiscordGuildChannelMember
                model
                sessionId
                { guildId = guildId, channelId = channelId, currentUserId = currentUserId }
                (\session _ _ guild channel ->
                    ( { model
                        | discordGuilds =
                            SeqDict.insert
                                guildId
                                { guild
                                    | channels =
                                        SeqDict.insert
                                            channelId
                                            (case anchor of
                                                Drawing.MessageAnchor threadRoute anchor2 ->
                                                    LocalState.drawingHandleChangeHelperBackend
                                                        currentUserId
                                                        change
                                                        threadRoute
                                                        anchor2
                                                        channel

                                                Drawing.DateDividerAnchor threadRoute date ->
                                                    LocalState.drawingHandleDateDivider
                                                        threadRoute
                                                        date
                                                        currentUserId
                                                        change
                                                        channel
                                            )
                                            guild.channels
                                }
                                model.discordGuilds
                      }
                    , Command.batch
                        [ LocalChangeResponse changeId localMsg
                            |> Lamdera.sendToFrontend clientId
                        , Broadcast.toDiscordGuildChannelExcludingOne
                            clientId
                            guildId
                            channelId
                            (Server_Drawing session.userId guildOrDmId anchor change |> ServerChange)
                            model
                        ]
                    )
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
                                (case anchor of
                                    Drawing.MessageAnchor (NoThreadWithMessage messageId) anchor2 ->
                                        LocalState.drawingHandleChangeNoThreadBackend
                                            data.currentUserId
                                            anchor2
                                            change
                                            messageId
                                            dmChannel

                                    Drawing.DateDividerAnchor NoThread date ->
                                        { dmChannel
                                            | dateDividerDrawings =
                                                SeqDictHelper.updateOrInsert
                                                    date
                                                    (\maybe ->
                                                        Maybe.withDefault Drawing.emptyDrawing maybe
                                                            |> Drawing.handleLocalChange data.currentUserId change
                                                    )
                                                    dmChannel.dateDividerDrawings
                                        }

                                    _ ->
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
                            (Server_Drawing session.userId guildOrDmId anchor change |> ServerChange)
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

        LoginWithRecoveryPasswordRequest _ _ _ ->
            ToBackendLog_LoginWithRecoveryPasswordRequest

        GetLoginTokenRequest _ ->
            ToBackendLog_GetLoginTokenRequest

        AdminToBackend _ ->
            ToBackendLog_AdminToBackend

        LogOutRequest _ ->
            ToBackendLog_LogOutRequest

        LocalModelChangeRequest _ localChange ->
            case localChange of
                Local_Invalid ->
                    ToBackendLog_Local_Invalid

                Local_Admin _ ->
                    ToBackendLog_Local_Admin

                Local_SendMessage _ _ _ _ _ _ _ ->
                    ToBackendLog_Local_SendMessage

                Local_Discord_SendMessage _ _ _ _ _ _ ->
                    ToBackendLog_Local_Discord_SendMessage

                Local_NewChannel _ _ _ _ ->
                    ToBackendLog_Local_NewChannel

                Local_EditChannel _ _ _ _ ->
                    ToBackendLog_Local_EditChannel

                Local_DeleteChannel _ _ ->
                    ToBackendLog_Local_DeleteChannel

                Local_EditGuildName _ _ ->
                    ToBackendLog_Local_EditGuildName

                Local_DeleteGuild _ ->
                    ToBackendLog_Local_DeleteGuild

                Local_LeaveGuild _ ->
                    ToBackendLog_Local_LeaveGuild

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

                Local_SendEditMessage _ _ _ _ _ _ ->
                    ToBackendLog_Local_SendEditMessage

                Local_Discord_SendEditGuildMessage _ _ _ _ _ _ _ ->
                    ToBackendLog_Local_Discord_SendEditGuildMessage

                Local_Discord_SendEditDmMessage _ _ _ _ _ ->
                    ToBackendLog_Local_Discord_SendEditDmMessage

                Local_MemberEditTyping _ _ _ ->
                    ToBackendLog_Local_MemberEditTyping

                Local_SetLastViewed _ _ ->
                    ToBackendLog_Local_SetLastViewed

                Local_DeleteMessage _ _ ->
                    ToBackendLog_Local_DeleteMessage

                Local_CurrentlyViewing _ _ ->
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

                Local_ExpandUserOptionSection _ ->
                    ToBackendLog_Local_ExpandUserOptionSection

                Local_SetSheepGameQuestions _ ->
                    ToBackendLog_Local_SetSheepGameQuestions

                Local_CollapseUserOptionSection _ ->
                    ToBackendLog_Local_CollapseUserOptionSection

                Local_SetEmailNotifications _ ->
                    ToBackendLog_Local_SetEmailNotifications

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

                Local_SetEmojiSkinTone _ ->
                    ToBackendLog_Local_SetEmojiSkinTone

                Local_SetUserColor _ ->
                    ToBackendLog_Local_SetUserColor

                Local_AddCustomEmojisToUser _ ->
                    ToBackendLog_Local_AddCustomEmojisToUser

                Local_VoiceChatChange _ ->
                    ToBackendLog_Local_VoiceChatChange

                Local_Game _ _ ->
                    ToBackendLog_Local_Game

                Local_Drawing _ _ _ ->
                    ToBackendLog_Local_Drawing

                Local_SetMuteChannel _ _ _ ->
                    ToBackendLog_Local_SetMuteChannel

                Local_SetMuteThread _ _ _ _ ->
                    ToBackendLog_Local_SetMuteThread

                Local_SetMuteDiscordChannel _ _ _ _ ->
                    ToBackendLog_Local_SetMuteDiscordChannel

                Local_SetMuteDiscordThread _ _ _ _ _ ->
                    ToBackendLog_Local_SetMuteDiscordThread

                Local_SetMuteGuild _ _ ->
                    ToBackendLog_Local_SetMuteGuild

                Local_SetMuteDiscordGuild _ _ _ ->
                    ToBackendLog_Local_SetMuteDiscordGuild

                Local_RequestE2ee _ ->
                    ToBackendLog_Local_RequestE2ee

                Local_DeclineE2eeRequestAsInitiator _ ->
                    ToBackendLog_Local_CancelE2eeRequest

                Local_DeclineE2eeRequest _ ->
                    ToBackendLog_Local_DeclineE2eeRequest

                Local_SetPublicKey _ _ ->
                    ToBackendLog_Local_SetPublicKey

                Local_EncryptOldMessages _ _ ->
                    ToBackendLog_Local_EncryptOldMessages

                Local_DisableE2ee _ _ ->
                    ToBackendLog_Local_DisableE2ee

                Local_DecryptOldMessages _ _ _ ->
                    ToBackendLog_Local_DecryptOldMessages

                Local_SetE2eeRisksAccepted _ ->
                    ToBackendLog_Local_SetE2eeRisksAccepted

                Local_AcceptE2ee _ _ _ ->
                    ToBackendLog_Local_AcceptE2ee

                Local_SendEncryptedMessage _ _ _ _ _ ->
                    ToBackendLog_Local_SendEncryptedMessage

                Local_SendEncryptedEditMessage _ _ _ _ _ ->
                    ToBackendLog_Local_SendEncryptedEditMessage

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

        ExportChannelRequest _ ->
            ToBackendLog_ExportChannelRequest


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


asGuildMemberRpc :
    BackendModel
    -> SessionId
    -> ClientId
    -> Id GuildId
    -> (UserSession -> BackendUser -> BackendGuild -> ( Result Http.Error String, BackendModel, Cmd BackendMsg ))
    -> ( Result Http.Error String, BackendModel, Cmd BackendMsg )
asGuildMemberRpc model sessionId clientId guildId func =
    case ( SeqDict.get sessionId model.sessions, SeqDict.get sessionId model.connections ) of
        ( Just session, Just connections ) ->
            if NonemptyDict.member clientId connections then
                case ( NonemptyDict.get session.userId model.users, SeqDict.get guildId model.guilds ) of
                    ( Just user, Just guild ) ->
                        case MembersAndOwner.isMember session.userId guild.membersAndOwner of
                            IsNotMember ->
                                rpcInvalidRequest model

                            IsMember ->
                                func session user guild

                            IsOwner ->
                                func session user guild

                    _ ->
                        rpcInvalidRequest model

            else
                rpcInvalidRequest model

        _ ->
            rpcInvalidRequest model


rpcInvalidRequest : BackendModel -> ( Result Http.Error value, BackendModel, Cmd BackendMsg )
rpcInvalidRequest model =
    ( Err (Http.BadBody "Invalid request"), model, Cmd.none )


asDiscordGuildChannelMember :
    BackendModel
    -> SessionId
    -> Viewing_DiscordChannelId
    ->
        (UserSession
         -> DiscordFullUserData
         -> BackendUser
         -> DiscordBackendGuild
         -> DiscordBackendChannel
         ->
            ( BackendModel
            , Command BackendOnly ToFrontend BackendMsg
            )
        )
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordGuildChannelMember model sessionId id func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            case
                ( NonemptyDict.get session.userId model.users
                , SeqDict.get id.guildId model.discordGuilds
                , SeqDict.get id.currentUserId model.discordUsers
                )
            of
                ( Just user, Just guild, Just (FullData discordUser) ) ->
                    case SeqDict.get id.channelId guild.channels of
                        Just channel ->
                            if
                                LocalState.canViewDiscordChannel id.guildId channel guild id.currentUserId
                                    && (discordUser.linkedTo == session.userId)
                            then
                                case MembersAndOwner.isMember id.currentUserId guild.membersAndOwner of
                                    IsNotMember ->
                                        ( model, Command.none )

                                    IsMember ->
                                        func session discordUser user guild channel

                                    IsOwner ->
                                        func session discordUser user guild channel

                            else
                                ( model, Command.none )

                        Nothing ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


asDiscordGuildMember :
    BackendModel
    -> SessionId
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.UserId
    ->
        (UserSession
         -> DiscordFullUserData
         -> BackendUser
         -> DiscordBackendGuild
         ->
            ( BackendModel
            , Command BackendOnly ToFrontend BackendMsg
            )
        )
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


asDiscordGuildChannelMember_AllowUserThatNeedsAuthAgain :
    BackendModel
    -> SessionId
    -> ClientId
    -> Viewing_DiscordChannelId
    ->
        (UserSession
         -> ConnectionData
         -> NeedsAuthAgainData
         -> BackendUser
         -> DiscordBackendGuild
         -> DiscordBackendChannel
         ->
            ( BackendModel
            , Command BackendOnly ToFrontend BackendMsg
            )
        )
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDiscordGuildChannelMember_AllowUserThatNeedsAuthAgain model sessionId clientId { guildId, channelId, currentUserId } func =
    case
        ( SeqDict.get sessionId model.sessions
        , SeqDict.get sessionId model.connections |> Maybe.andThen (NonemptyDict.get clientId)
        )
    of
        ( Just session, Just connection ) ->
            case
                ( NonemptyDict.get session.userId model.users
                , SeqDict.get guildId model.discordGuilds
                )
            of
                ( Just user, Just guild ) ->
                    case ( SeqDict.get channelId guild.channels, SeqDict.get currentUserId model.discordUsers ) of
                        ( Just channel, Just (FullData discordUser) ) ->
                            if
                                LocalState.canViewDiscordChannel guildId channel guild currentUserId
                                    && (discordUser.linkedTo == session.userId)
                            then
                                case MembersAndOwner.isMember currentUserId guild.membersAndOwner of
                                    IsNotMember ->
                                        ( model, Command.none )

                                    IsMember ->
                                        func
                                            session
                                            connection
                                            { user = discordUser.user
                                            , linkedTo = discordUser.linkedTo
                                            , icon = discordUser.icon
                                            , linkedAt = discordUser.linkedAt
                                            }
                                            user
                                            guild
                                            channel

                                    IsOwner ->
                                        func
                                            session
                                            connection
                                            { user = discordUser.user
                                            , linkedTo = discordUser.linkedTo
                                            , icon = discordUser.icon
                                            , linkedAt = discordUser.linkedAt
                                            }
                                            user
                                            guild
                                            channel

                            else
                                ( model, Command.none )

                        ( Just channel, Just (NeedsAuthAgain discordUser) ) ->
                            if
                                LocalState.canViewDiscordChannel guildId channel guild currentUserId
                                    && (discordUser.linkedTo == session.userId)
                            then
                                case MembersAndOwner.isMember currentUserId guild.membersAndOwner of
                                    IsNotMember ->
                                        ( model, Command.none )

                                    IsMember ->
                                        func session connection discordUser user guild channel

                                    IsOwner ->
                                        func session connection discordUser user guild channel

                            else
                                ( model, Command.none )

                        _ ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        _ ->
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
    -> Viewing_DmId
    -> (UserSession -> BackendUser -> BackendUser -> DmChannelId -> BackendDmChannel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asDmUser model sessionId { otherUserId } func =
    case SeqDict.get sessionId model.sessions of
        Just session ->
            let
                dmChannelId =
                    DmChannelId.fromUserIds session.userId otherUserId
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


asDmUserRpc :
    BackendModel
    -> SessionId
    -> ClientId
    -> Viewing_DmId
    -> (UserSession -> BackendUser -> BackendUser -> DmChannelId -> BackendDmChannel -> ( Result Http.Error String, BackendModel, Cmd BackendMsg ))
    -> ( Result Http.Error String, BackendModel, Cmd BackendMsg )
asDmUserRpc model sessionId clientId { otherUserId } func =
    case ( SeqDict.get sessionId model.sessions, SeqDict.get sessionId model.connections ) of
        ( Just session, Just connections ) ->
            if NonemptyDict.member clientId connections then
                let
                    dmChannelId =
                        DmChannelId.fromUserIds session.userId otherUserId
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
                            rpcInvalidRequest model

                    _ ->
                        rpcInvalidRequest model

            else
                rpcInvalidRequest model

        _ ->
            rpcInvalidRequest model


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
    -> Viewing_DiscordDmId
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
    -> Viewing_DiscordDmId
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


decryptOldMessages :
    Time.Posix
    -> ClientId
    -> ChangeId
    -> LocalChange
    -> BackendModel
    -> List ( ThreadRouteWithMessage, MessageContent (Id UserId) )
    -> UserSession
    -> DmChannelId
    -> BackendDmChannel
    -> ( BackendModel, Command BackendOnly ToFrontend backendMsg )
decryptOldMessages time clientId changeId localMsg model messages session dmChannelId dmChannel =
    case dmChannel.e2ee of
        DmChannel.E2eeEnabled _ ->
            let
                dmChannel2 : BackendDmChannel
                dmChannel2 =
                    List.foldl
                        (\( threadRoute, content ) channel ->
                            case threadRoute of
                                NoThreadWithMessage messageId ->
                                    { channel
                                        | messages =
                                            DmChannel.updateArray
                                                messageId
                                                (Message.toDecrypted content)
                                                channel.messages
                                    }

                                ViewThreadWithMessage threadId messageId ->
                                    { channel
                                        | threads =
                                            SeqDict.updateIfExists
                                                threadId
                                                (\thread ->
                                                    { thread
                                                        | messages =
                                                            DmChannel.updateArray
                                                                messageId
                                                                (Message.toDecrypted content)
                                                                thread.messages
                                                    }
                                                )
                                                channel.threads
                                    }
                        )
                        dmChannel
                        messages
            in
            if channelDataToDecrypt dmChannel2 == { channel = SeqDict.empty, threads = SeqDict.empty } then
                ( { model
                    | dmChannels =
                        SeqDict.insert
                            dmChannelId
                            { dmChannel2 | e2ee = DmChannel.E2eeDisabled (Just ( session.userId, time )) }
                            model.dmChannels
                  }
                , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
                )

            else
                ( model, invalidChangeResponse changeId clientId )

        DmChannel.E2eeDisabled _ ->
            ( model, invalidChangeResponse changeId clientId )

        DmChannel.E2eeRequestedBy ( id, sessionIdHash ) ->
            ( model, invalidChangeResponse changeId clientId )

        DmChannel.E2eeDeclinedBy id ->
            ( model, invalidChangeResponse changeId clientId )


encryptOldMessages :
    ClientId
    -> ChangeId
    -> LocalChange
    -> BackendModel
    -> List ( ThreadRouteWithMessage, SeqSet FileHash, EncryptedData (MessageContent (Id UserId)) )
    -> DmChannelId
    -> BackendDmChannel
    -> ( BackendModel, Command BackendOnly ToFrontend backendMsg )
encryptOldMessages clientId changeId localMsg model messages dmChannelId dmChannel =
    case dmChannel.e2ee of
        DmChannel.E2eeEnabled _ ->
            ( { model
                | dmChannels =
                    SeqDict.insert
                        dmChannelId
                        (List.foldl
                            (\( threadRoute, fileHashes, encryptedData ) channel ->
                                case threadRoute of
                                    NoThreadWithMessage messageId ->
                                        { channel
                                            | messages =
                                                DmChannel.updateArray
                                                    messageId
                                                    (Message.toEncrypted fileHashes encryptedData)
                                                    channel.messages
                                        }

                                    ViewThreadWithMessage threadId messageId ->
                                        { channel
                                            | threads =
                                                SeqDict.updateIfExists
                                                    threadId
                                                    (\thread ->
                                                        { thread
                                                            | messages =
                                                                DmChannel.updateArray
                                                                    messageId
                                                                    (Message.toEncrypted fileHashes encryptedData)
                                                                    thread.messages
                                                        }
                                                    )
                                                    channel.threads
                                        }
                            )
                            dmChannel
                            messages
                        )
                        model.dmChannels
              }
            , LocalChangeResponse changeId localMsg |> Lamdera.sendToFrontend clientId
            )

        _ ->
            ( model, invalidChangeResponse changeId clientId )
