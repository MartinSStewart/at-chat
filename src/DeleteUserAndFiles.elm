module DeleteUserAndFiles exposing (deleteAccounts, deleteFiles, orphanedFiles, removeDeletedFiles)

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
import Pages.Home
import PersonName
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SheepGame
import Sticker exposing (StickerData, StickerUrl(..))
import Types exposing (BackendModel, BackendMsg(..), LoginData, ToFrontend)
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
        in
        ( { model
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
                    model.users
            , sessions = SeqDict.filter (\_ session -> not (SeqSet.member session.userId usersToDelete)) model.sessions
            , guilds = SeqDict.map (\_ guild -> deleteMessagesInGuild usersToDelete guild) model.guilds
            , deletedGuilds =
                SeqDict.map
                    (\_ deleted -> { deleted | guild = deleteMessagesInGuild usersToDelete deleted.guild })
                    model.deletedGuilds
            , dmChannels = SeqDict.map (\_ dmChannel -> deleteMessagesInChannel usersToDelete dmChannel) model.dmChannels
            , discordUsers = discordUsers
          }
        , Command.batch closeWebsockets
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
        , SeqDict.values model.sessions |> List.concatMap savedSheepGameQuestionFiles
        , SeqDict.values model.stickers |> List.filterMap stickerFile
        , SeqDict.values model.customEmojis |> List.filterMap customEmojiFile
        , SeqDict.values previewLoginData.guilds |> List.concatMap frontendGuildFiles
        , SeqDict.values previewLoginData.discordGuilds |> List.filterMap .icon
        , Maybe.Extra.toList previewLoginData.user.icon ++ List.filterMap .icon (SeqDict.values previewLoginData.otherUsers)
        ]


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
