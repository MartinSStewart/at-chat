module DeleteUserAndFiles exposing (deleteAccounts, deleteFiles, orphanedDiscordGuilds, orphanedFiles, orphanedSlackDmChannels, orphanedSlackWorkspaces, removeDeletedFiles)

import Array
import Codec
import CustomEmoji exposing (CustomEmojiData, CustomEmojiUrl(..))
import Discord
import DiscordSync
import DiscordUserData exposing (DiscordUserData(..))
import DmChannel exposing (BackendDmChannel)
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Effect.Websocket as Websocket
import FileStatus exposing (BackendFileData, FileHash)
import Game
import Id exposing (ChannelId, ChannelMessageId, Id, ThreadMessageId, UserId)
import IdArray exposing (IdArray)
import List.Nonempty
import LocalState exposing (BackendGuild, DiscordBackendGuild, FrontendGuild, WebsocketClosedEvent(..))
import Maybe.Extra
import Message exposing (Message(..))
import MessageArray exposing (MessageArray)
import NonemptyDict
import NonemptySet
import Pages.Home
import PersonName
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SheepGame
import Slack
import SlackSync
import Sticker exposing (StickerData, StickerUrl(..))
import Types exposing (BackendModel, BackendMsg(..), LoginData, SlackUserData(..), ToFrontend)
import User exposing (BackendUserStatus(..))
import UserAgent
import UserSession exposing (UserSession)


deleteAccounts : Time.Posix -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
deleteAccounts time model =
    let
        usersToDelete : SeqSet (Id UserId)
        usersToDelete =
            NonemptyDict.foldl
                (\userId user set ->
                    case user.deleteAccountAt of
                        Just deleteAt ->
                            if not user.isAdmin && Time.posixToMillis deleteAt <= Time.posixToMillis time then
                                SeqSet.insert userId set

                            else
                                set

                        Nothing ->
                            set
                )
                SeqSet.empty
                model.users
    in
    if SeqSet.isEmpty usersToDelete then
        ( model, Command.none )

    else
        let
            ( discordUsers, closeWebsockets ) =
                SeqDict.foldl
                    (\discordUserId discordUser ( dict, cmds ) ->
                        case discordUser of
                            FullData data ->
                                if SeqSet.member data.linkedTo usersToDelete then
                                    ( SeqDict.insert
                                        discordUserId
                                        (BasicData { user = Discord.userToPartialUser data.user, icon = data.icon })
                                        dict
                                    , case data.connection.websocketHandle of
                                        Just connection ->
                                            Task.perform
                                                (WebsocketClosedByBackendForUser discordUserId Nothing)
                                                (DiscordSync.websocketClose
                                                    (WebsocketClosed_UnlinkDiscordUser discordUserId)
                                                    connection
                                                )
                                                :: cmds

                                        Nothing ->
                                            cmds
                                    )

                                else
                                    ( dict, cmds )

                            NeedsAuthAgain data ->
                                if SeqSet.member data.linkedTo usersToDelete then
                                    ( SeqDict.insert
                                        discordUserId
                                        (BasicData { user = Discord.userToPartialUser data.user, icon = data.icon })
                                        dict
                                    , cmds
                                    )

                                else
                                    ( dict, cmds )

                            BasicData _ ->
                                ( dict, cmds )
                    )
                    ( model.discordUsers, [] )
                    model.discordUsers

            ( model2, closeSlackWebsockets ) =
                SeqDict.foldl
                    (\slackUserId slackUser ( modelAcc, cmds ) ->
                        case slackUser of
                            SlackFullData linkedUser ->
                                if SeqSet.member linkedUser.linkedTo usersToDelete then
                                    ( SlackSync.unlinkUser slackUserId linkedUser modelAcc
                                    , case linkedUser.websocket of
                                        Just connection ->
                                            Task.perform (\() -> SlackWebsocketClosedByBackend) (Websocket.close connection)
                                                :: cmds

                                        Nothing ->
                                            cmds
                                    )

                                else
                                    ( modelAcc, cmds )

                            SlackBasicData _ ->
                                ( modelAcc, cmds )
                    )
                    ( model, [] )
                    model.slackUsers
        in
        ( { model2
            | users =
                NonemptyDict.map
                    (\userId user ->
                        if SeqSet.member userId usersToDelete then
                            User.init
                                user.createdAt
                                (PersonName.fromStringLossy ("<delete_user_" ++ Id.toString userId ++ ">"))
                                DeletedUser
                                False

                        else
                            user
                    )
                    model2.users
            , sessions = SeqDict.filter (\_ session -> not (SeqSet.member session.userId usersToDelete)) model2.sessions
            , guilds = SeqDict.map (\_ guild -> deleteMessagesInGuild usersToDelete guild) model2.guilds
            , deletedGuilds =
                SeqDict.map
                    (\_ deleted -> { deleted | guild = deleteMessagesInGuild usersToDelete deleted.guild })
                    model2.deletedGuilds
            , dmChannels = SeqDict.map (\_ dmChannel -> deleteMessagesInChannel usersToDelete dmChannel) model2.dmChannels
            , discordUsers = discordUsers
          }
        , Command.batch (closeWebsockets ++ closeSlackWebsockets)
        )


deleteMessagesInGuild : SeqSet (Id UserId) -> BackendGuild -> BackendGuild
deleteMessagesInGuild usersToDelete guild =
    { guild | channels = SeqDict.map (\_ channel -> deleteMessagesInChannel usersToDelete channel) guild.channels }


deleteMessagesInChannel :
    SeqSet (Id UserId)
    ->
        { a
            | messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId) (Id ChannelId))
            , threads : SeqDict (Id ChannelMessageId) { b | messages : IdArray ThreadMessageId (Message ThreadMessageId (Id UserId) (Id ChannelId)) }
        }
    ->
        { a
            | messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId) (Id ChannelId))
            , threads : SeqDict (Id ChannelMessageId) { b | messages : IdArray ThreadMessageId (Message ThreadMessageId (Id UserId) (Id ChannelId)) }
        }
deleteMessagesInChannel usersToDelete channel =
    { channel
        | messages = IdArray.map (\_ message -> deleteMessageBy usersToDelete message) channel.messages
        , threads =
            SeqDict.map
                (\_ thread -> { thread | messages = IdArray.map (\_ message -> deleteMessageBy usersToDelete message) thread.messages })
                channel.threads
    }


deleteMessageBy : SeqSet (Id UserId) -> Message messageId (Id UserId) channelId -> Message messageId (Id UserId) channelId
deleteMessageBy usersToDelete message =
    case message of
        UserTextMessage data ->
            if SeqSet.member data.createdBy usersToDelete then
                DeletedMessage data.createdAt

            else
                message

        EncryptedUserTextMessage data ->
            if SeqSet.member data.createdBy usersToDelete then
                DeletedMessage data.createdAt

            else
                message

        UserJoinedMessage _ _ _ _ ->
            message

        DeletedMessage _ ->
            message

        CallStarted _ ->
            message

        GameStarted _ ->
            message


orphanedDiscordGuilds : BackendModel -> SeqSet (Discord.Id Discord.GuildId)
orphanedDiscordGuilds model =
    let
        linkedDiscordUsers : SeqDict (Discord.Id Discord.UserId) ()
        linkedDiscordUsers =
            SeqDict.foldl
                (\discordUserId discordUser dict ->
                    case discordUser of
                        FullData _ ->
                            SeqDict.insert discordUserId () dict

                        NeedsAuthAgain _ ->
                            SeqDict.insert discordUserId () dict

                        BasicData _ ->
                            dict
                )
                SeqDict.empty
                model.discordUsers
    in
    SeqDict.foldl
        (\guildId guild set ->
            if LocalState.canViewDiscordGuild linkedDiscordUsers guild.membersAndOwner then
                set

            else
                SeqSet.insert guildId set
        )
        SeqSet.empty
        model.discordGuilds


orphanedSlackWorkspaces : BackendModel -> SeqSet (Slack.Id Slack.TeamId)
orphanedSlackWorkspaces model =
    let
        linkedTeams : SeqSet (Slack.Id Slack.TeamId)
        linkedTeams =
            SeqDict.values (linkedSlackUsers model) |> SeqSet.fromList
    in
    SeqDict.foldl
        (\teamId _ set ->
            if SeqSet.member teamId linkedTeams then
                set

            else
                SeqSet.insert teamId set
        )
        SeqSet.empty
        model.slackWorkspaces


orphanedSlackDmChannels : BackendModel -> SeqSet (Slack.Id Slack.DmChannelId)
orphanedSlackDmChannels model =
    let
        linked : SeqDict (Slack.Id Slack.UserId) (Slack.Id Slack.TeamId)
        linked =
            linkedSlackUsers model
    in
    SeqDict.foldl
        (\channelId dmChannel set ->
            if List.any (\slackUserId -> SeqDict.member slackUserId linked) (NonemptySet.toList dmChannel.members) then
                set

            else
                SeqSet.insert channelId set
        )
        SeqSet.empty
        model.slackDmChannels


linkedSlackUsers : BackendModel -> SeqDict (Slack.Id Slack.UserId) (Slack.Id Slack.TeamId)
linkedSlackUsers model =
    SeqDict.foldl
        (\slackUserId slackUser dict ->
            case slackUser of
                SlackFullData linkedUser ->
                    SeqDict.insert slackUserId linkedUser.user.teamId dict

                SlackBasicData _ ->
                    dict
        )
        SeqDict.empty
        model.slackUsers


deleteFiles : SecretId ServerSecret -> List FileHash -> Task BackendOnly Http.Error ()
deleteFiles serverSecret fileHashes =
    Http.task
        { method = "POST"
        , url = FileStatus.domain ++ "/file/internal/delete-files"
        , body = Http.jsonBody (Codec.encoder (Codec.list FileStatus.fileHashCodec) fileHashes)
        , headers = [ FileStatus.secretKeyHeader serverSecret ]
        , resolver =
            Http.stringResolver
                (\result ->
                    case result of
                        Http.BadStatus_ metadata body ->
                            Http.BadBody
                                ("Status code: " ++ String.fromInt metadata.statusCode ++ ", body: " ++ body)
                                |> Err

                        Http.GoodStatus_ _ _ ->
                            Ok ()

                        Http.BadUrl_ string ->
                            Err (Http.BadUrl string)

                        Http.Timeout_ ->
                            Err Http.Timeout

                        Http.NetworkError_ ->
                            Err Http.NetworkError
                )
        , timeout = Just Duration.minute
        }


removeDeletedFiles : List FileHash -> BackendModel -> BackendModel
removeDeletedFiles deleted model =
    let
        deletedSet : SeqSet FileHash
        deletedSet =
            SeqSet.fromList deleted
    in
    { model
        | files = List.foldl SeqDict.remove model.files deleted
        , discordAttachments =
            SeqDict.filter
                (\_ attachment -> not (SeqSet.member attachment.fileHash deletedSet))
                model.discordAttachments
        , slackFiles =
            SeqDict.filter
                (\_ file -> not (SeqSet.member file.fileHash deletedSet))
                model.slackFiles
    }


orphanedFiles : BackendModel -> SeqDict FileHash BackendFileData
orphanedFiles model =
    List.foldl SeqDict.remove model.files (usedFiles model)


usedFiles : BackendModel -> List FileHash
usedFiles model =
    let
        previewLoginData : LoginData
        previewLoginData =
            Pages.Home.previewLoginData UserAgent.init
    in
    List.concat
        [ NonemptyDict.values model.users |> List.Nonempty.toList |> List.filterMap .icon
        , SeqDict.values model.discordUsers |> List.filterMap DiscordUserData.icon
        , SeqDict.values model.guilds |> List.concatMap guildFiles
        , SeqDict.values model.deletedGuilds |> List.concatMap (\deleted -> guildFiles deleted.guild)
        , SeqDict.values model.discordGuilds |> List.concatMap discordGuildFiles
        , SeqDict.values model.dmChannels |> List.concatMap dmChannelFiles
        , SeqDict.values model.discordDmChannels |> List.concatMap (\dmChannel -> messagesFiles dmChannel.messages)
        , SeqDict.values model.slackUsers |> List.filterMap slackUserIcon
        , SeqDict.values model.slackWorkspaces
            |> List.concatMap
                (\workspace ->
                    Maybe.Extra.toList workspace.icon
                        ++ List.concatMap
                            (\channel ->
                                messagesFiles channel.messages
                                    ++ List.concatMap (\thread -> messagesFiles thread.messages) (SeqDict.values channel.threads)
                            )
                            (SeqDict.values workspace.channels)
                )
        , SeqDict.values model.slackDmChannels
            |> List.concatMap
                (\dmChannel ->
                    messagesFiles dmChannel.messages
                        ++ List.concatMap (\thread -> messagesFiles thread.messages) (SeqDict.values dmChannel.threads)
                )
        , SeqDict.values model.sessions |> List.concatMap savedSheepGameQuestionFiles
        , SeqDict.values model.stickers |> List.filterMap stickerFile
        , SeqDict.values model.customEmojis |> List.filterMap customEmojiFile
        , SeqDict.values previewLoginData.guilds |> List.concatMap frontendGuildFiles
        , SeqDict.values previewLoginData.discordGuilds |> List.filterMap .icon
        , Maybe.Extra.toList previewLoginData.user.icon ++ List.filterMap .icon (SeqDict.values previewLoginData.otherUsers)
        ]


slackUserIcon : SlackUserData -> Maybe FileHash
slackUserIcon userData =
    case userData of
        SlackBasicData basicData ->
            basicData.icon

        SlackFullData linkedUser ->
            linkedUser.icon


guildFiles : BackendGuild -> List FileHash
guildFiles guild =
    Maybe.Extra.toList guild.icon
        ++ List.concatMap
            (\channel ->
                messagesFiles channel.messages
                    ++ List.concatMap (\thread -> messagesFiles thread.messages) (SeqDict.values channel.threads)
                    ++ List.concatMap gameFiles (SeqDict.values channel.games)
            )
            (SeqDict.values guild.channels)


frontendGuildFiles : FrontendGuild -> List FileHash
frontendGuildFiles guild =
    Maybe.Extra.toList guild.icon
        ++ List.concatMap
            (\channel ->
                frontendMessagesFiles channel.messages
                    ++ List.concatMap (\thread -> frontendMessagesFiles thread.messages) (SeqDict.values channel.threads)
            )
            (SeqDict.values guild.channels)


discordGuildFiles : DiscordBackendGuild -> List FileHash
discordGuildFiles guild =
    Maybe.Extra.toList guild.icon
        ++ List.concatMap
            (\channel ->
                messagesFiles channel.messages
                    ++ List.concatMap (\thread -> messagesFiles thread.messages) (SeqDict.values channel.threads)
            )
            (SeqDict.values guild.channels)


dmChannelFiles : BackendDmChannel -> List FileHash
dmChannelFiles dmChannel =
    messagesFiles dmChannel.messages
        ++ List.concatMap (\thread -> messagesFiles thread.messages) (SeqDict.values dmChannel.threads)
        ++ List.concatMap gameFiles (SeqDict.values dmChannel.games)


messagesFiles : IdArray messageId (Message messageId userId channelId) -> List FileHash
messagesFiles messages =
    IdArray.toList messages |> List.concatMap messageFiles


frontendMessagesFiles : MessageArray messageId userId channelId -> List FileHash
frontendMessagesFiles messages =
    MessageArray.toList messages |> List.concatMap (\( _, message ) -> messageFiles message)


messageFiles : Message messageId userId channelId -> List FileHash
messageFiles message =
    case message of
        UserTextMessage data ->
            SeqDict.values data.content.attachedFiles |> List.map .fileHash

        EncryptedUserTextMessage data ->
            SeqSet.toList data.fileHashes

        UserJoinedMessage _ _ _ _ ->
            []

        DeletedMessage _ ->
            []

        CallStarted _ ->
            []

        GameStarted _ ->
            []


gameFiles : Game.BackendGameData -> List FileHash
gameFiles gameData =
    case gameData of
        Game.GameData_Go _ _ ->
            []

        Game.GameData_WordSpellingGame _ _ _ ->
            []

        Game.GameData_SheepGame setup actions shared ->
            List.Nonempty.toList setup.questions
                ++ List.filterMap sheepGameActionInput (Array.toList actions)
                ++ List.concatMap (\answers -> List.filterMap identity (IdArray.toList answers)) (SeqDict.values shared.answers)
                ++ List.filterMap identity (SeqDict.values shared.notes)
                |> List.concatMap (\input -> SeqDict.values input.attachedFiles |> List.map .fileHash)


sheepGameActionInput : SheepGame.ActionWithTime -> Maybe SheepGame.ValidatedInput
sheepGameActionInput action =
    case action.change of
        SheepGame.SubmittedAnswer _ input ->
            input

        SheepGame.ChangedNotes _ input ->
            input

        _ ->
            Nothing


savedSheepGameQuestionFiles : UserSession -> List FileHash
savedSheepGameQuestionFiles session =
    IdArray.toList session.savedSheepGameQuestions
        |> List.concatMap (\question -> FileStatus.onlyUploadedFiles question.attachedFiles |> SeqDict.values |> List.map .fileHash)


stickerFile : StickerData -> Maybe FileHash
stickerFile sticker =
    case sticker.url of
        StickerInternal fileHash _ ->
            Just fileHash

        DiscordStandardSticker _ ->
            Nothing

        StickerLoading ->
            Nothing


customEmojiFile : CustomEmojiData -> Maybe FileHash
customEmojiFile customEmoji =
    case customEmoji.url of
        CustomEmojiInternal fileHash _ ->
            Just fileHash

        CustomEmojiLoading ->
            Nothing
