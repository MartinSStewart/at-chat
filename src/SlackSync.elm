module SlackSync exposing (..)

import BackendExtra
import Broadcast
import ChannelName exposing (ChannelName)
import CustomEmoji exposing (CustomEmojiData, CustomEmojiUrl(..), EmojiName)
import DmChannel
import Drawing
import Duration exposing (Duration)
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera exposing (SessionId)
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Effect.Websocket as Websocket
import Emoji exposing (EmojiOrCustomEmoji(..))
import FileName
import FileStatus exposing (FileData, FileHash, FileId, IsEncrypted(..))
import Id exposing (AnyGuildOrDmId, ChannelMessageId, CustomEmojiId, Id, SlackGuildOrDmId(..), ThreadMessageId, ThreadRoute(..), ThreadRouteWithMessage(..), UserId)
import IdArray exposing (IdArray)
import List.Extra
import List.Nonempty exposing (Nonempty)
import LocalState exposing (SlackFrontendChannel, SlackFrontendDmChannel, SlackFrontendWorkspace)
import Message exposing (ChangeAttachments(..), Message(..), RepliedTo(..), UserTextMessageData)
import NonemptyDict exposing (NonemptyDict)
import NonemptyExtra
import NonemptySet exposing (NonemptySet)
import OneToOne exposing (OneToOne)
import PersonName exposing (PersonName)
import Quantity
import Random
import RichText exposing (RichText)
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Slack exposing (SlackCookie, SlackToken)
import SlackEmoji
import Thread exposing (SlackBackendThread)
import Types exposing (BackendModel, BackendMsg(..), LoadedSlackWorkspace, ServerChange(..), SlackBackendChannel, SlackBackendWorkspace, SlackDmChannel, SlackFileData, SlackLinkedUser, SlackUserData(..), ToFrontend)
import User exposing (BackendUser)
import UserSession exposing (SlackFrontendUser, UserSession)
import VisibleMessages


newChannelMaxMessages : Int
newChannelMaxMessages =
    50


{-| Takes messages oldest first. Messages with nothing at-chat can show are left out.
-}
messagesAndLinks :
    SeqDict (Slack.Id Slack.FileId) SlackFileData
    -> SeqDict String (Id CustomEmojiId)
    -> List Slack.Message
    ->
        ( IdArray messageId (Message messageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
        , OneToOne (Slack.Id Slack.MessageId) (Id messageId)
        )
messagesAndLinks slackFiles customEmojis messages =
    let
        converted : List ( Slack.Id Slack.MessageId, Message messageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId) )
        converted =
            List.filterMap
                (\message -> toMessage slackFiles customEmojis message |> Maybe.map (Tuple.pair message.id))
                messages
    in
    ( IdArray.fromList (List.map Tuple.second converted)
    , List.indexedMap (\index ( slackId, _ ) -> ( slackId, Id.fromInt index )) converted |> OneToOne.fromList
    )


{-| A conversation built from its history, newest first as Slack gives it.
-}
conversationFromHistory :
    SeqDict (Slack.Id Slack.FileId) SlackFileData
    -> SeqDict String (Id CustomEmojiId)
    -> Slack.History
    ->
        { messages : IdArray ChannelMessageId (Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
        , linkedMessageIds : OneToOne (Slack.Id Slack.MessageId) (Id ChannelMessageId)
        , threads : SeqDict (Id ChannelMessageId) SlackBackendThread
        }
conversationFromHistory slackFiles customEmojis history =
    let
        ( messages, linkedMessageIds ) =
            messagesAndLinks slackFiles customEmojis (List.reverse history.messages)
    in
    { messages = messages
    , linkedMessageIds = linkedMessageIds
    , threads =
        SeqDict.foldl
            (\parentId replies dict ->
                case OneToOne.second parentId linkedMessageIds of
                    Just threadId ->
                        let
                            ( threadMessages, threadLinks ) =
                                messagesAndLinks slackFiles customEmojis replies
                        in
                        if IdArray.length threadMessages > 0 then
                            SeqDict.insert threadId { messages = threadMessages, linkedMessageIds = threadLinks } dict

                        else
                            dict

                    Nothing ->
                        dict
            )
            SeqDict.empty
            history.replies
    }


{-| Files that haven't been copied to at-chat are left out.
-}
toMessage :
    SeqDict (Slack.Id Slack.FileId) SlackFileData
    -> SeqDict String (Id CustomEmojiId)
    -> Slack.Message
    -> Maybe (Message messageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
toMessage slackFiles customEmojis message =
    case message.content of
        Slack.TextMessage { text, blocks, files } ->
            let
                attachedFiles : SeqDict (Id FileId) FileData
                attachedFiles =
                    List.filterMap
                        (\file -> SeqDict.get file.id slackFiles |> Maybe.map (fileData file))
                        files
                        |> List.indexedMap (\index fileData2 -> ( Id.fromInt (index + 1), fileData2 ))
                        |> SeqDict.fromList

                attachedFileNodes : List (RichText (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
                attachedFileNodes =
                    List.map RichText.AttachedFile (SeqDict.keys attachedFiles)
            in
            (case RichText.fromSlack customEmojis text blocks of
                Just content ->
                    NonemptyExtra.appendList content attachedFileNodes |> Just

                Nothing ->
                    List.Nonempty.fromList attachedFileNodes
            )
                |> Maybe.map
                    (\content ->
                        Message.userTextMessageNoEmbeds
                            message.createdAt
                            message.user
                            content
                            (reactions customEmojis message.reactions)
                            NoReply
                            attachedFiles
                            |> UserTextMessage
                    )

        Slack.JoinedChannel ->
            UserJoinedMessage message.createdAt message.user (reactions customEmojis message.reactions) Drawing.emptyDrawing |> Just


fileData : Slack.File -> SlackFileData -> FileData
fileData file { fileHash, metadata } =
    { fileName = FileName.fromString file.name
    , fileSize = file.size
    , metadata = metadata
    , contentType = FileStatus.contentType file.mimetype
    , fileHash = fileHash
    , isEncrypted = IsNotEncrypted
    }


{-| Reactions with custom emoji added to the workspace since it was linked are left out.
-}
reactions : SeqDict String (Id CustomEmojiId) -> List Slack.Reaction -> SeqDict EmojiOrCustomEmoji (NonemptySet (Slack.Id Slack.UserId))
reactions customEmojis slackReactions =
    List.foldl
        (\reaction dict ->
            case ( emojiFromSlackName customEmojis reaction.name, NonemptySet.fromList reaction.users ) of
                ( Just emoji, Just users ) ->
                    SeqDict.insert emoji users dict

                ( Just _, Nothing ) ->
                    dict

                ( Nothing, Just _ ) ->
                    dict

                ( Nothing, Nothing ) ->
                    dict
        )
        SeqDict.empty
        slackReactions


emojiFromSlackName : SeqDict String (Id CustomEmojiId) -> String -> Maybe EmojiOrCustomEmoji
emojiFromSlackName customEmojis name =
    case SlackEmoji.fromSlackName name of
        Just emoji ->
            Just (EmojiOrCustomEmoji_Emoji emoji)

        Nothing ->
            case SeqDict.get name customEmojis of
                Just customEmojiId ->
                    Just (EmojiOrCustomEmoji_CustomEmoji customEmojiId)

                Nothing ->
                    Nothing


{-| What to call each custom emoji when sending it to Slack. An emoji is always added before its
aliases, so it goes by its own name rather than an alias's.
-}
customEmojiNames : SeqDict String (Id CustomEmojiId) -> SeqDict (Id CustomEmojiId) String
customEmojiNames customEmojis =
    SeqDict.foldl
        (\name customEmojiId dict ->
            if SeqDict.member customEmojiId dict then
                dict

            else
                SeqDict.insert customEmojiId name dict
        )
        SeqDict.empty
        customEmojis


emojiToSlackName : SeqDict String (Id CustomEmojiId) -> EmojiOrCustomEmoji -> Maybe String
emojiToSlackName customEmojis emoji =
    case emoji of
        EmojiOrCustomEmoji_Emoji unicodeEmoji ->
            SlackEmoji.toSlackName unicodeEmoji

        EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
            SeqDict.get customEmojiId (customEmojiNames customEmojis)


teamCustomEmojis : Slack.Id Slack.TeamId -> BackendModel -> SeqDict String (Id CustomEmojiId)
teamCustomEmojis teamId model =
    case SeqDict.get teamId model.slackWorkspaces of
        Just workspace ->
            workspace.customEmojis

        Nothing ->
            SeqDict.empty


userName : Slack.User -> PersonName
userName user =
    (if user.displayName /= "" then
        user.displayName

     else if user.realName /= "" then
        user.realName

     else
        user.name
    )
        |> PersonName.fromStringLossy


{-| Drops the credentials and the channel memberships. Closing the websocket is left to the caller.
-}
unlinkUser : Slack.Id Slack.UserId -> SlackLinkedUser -> BackendModel -> BackendModel
unlinkUser slackUserId linkedUser model =
    { model
        | slackUsers =
            SeqDict.insert
                slackUserId
                (SlackBasicData { user = linkedUser.user, icon = linkedUser.icon })
                model.slackUsers
        , slackWorkspaces =
            SeqDict.updateIfExists
                linkedUser.user.teamId
                (\workspace ->
                    { workspace
                        | channels =
                            SeqDict.map
                                (\_ channel -> { channel | linkedMembers = SeqSet.remove slackUserId channel.linkedMembers })
                                workspace.channels
                    }
                )
                model.slackWorkspaces
        , pendingSlackReconnects = SeqDict.remove slackUserId model.pendingSlackReconnects
    }


handleSlackWebsocketEvent :
    SlackLinkedUser
    -> Slack.WebsocketEvent
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleSlackWebsocketEvent linkedUser event model =
    case event of
        Slack.WebsocketRelayReady ->
            case linkedUser.websocket of
                Just connection ->
                    ( model
                    , Websocket.sendString
                        connection
                        (Slack.websocketRelayRequest model.serverSecret linkedUser.cookie linkedUser.token)
                        |> Task.attempt (SlackWebsocketSentData linkedUser.user.id)
                    )

                Nothing ->
                    ( model, Command.none )

        Slack.WebsocketMessageCreated channelString message ->
            case
                ( slackChannelFromWebsocket linkedUser message.user channelString model
                , ( toMessage model.slackFiles (teamCustomEmojis linkedUser.user.teamId model) message, toMessage model.slackFiles (teamCustomEmojis linkedUser.user.teamId model) message )
                )
            of
                ( Just guildOrDmId, ( Just (UserTextMessage data), Just (UserTextMessage threadData) ) ) ->
                    if SeqDict.member (slackPendingSendKey guildOrDmId) model.pendingSlackSends then
                        -- Probably the message at-chat is sending right now. SentSlackMessage adds it instead.
                        ( model, Command.none )

                    else
                        let
                            ( data2, embedCmds ) =
                                Message.loadEmbeds model.serverSecret data

                            ( threadData2, _ ) =
                                Message.loadEmbeds model.serverSecret threadData

                            parentId : Slack.Id Slack.MessageId -> List ThreadRoute
                            parentId slackParentId =
                                case
                                    getSlackConversation guildOrDmId model
                                        |> Maybe.andThen (\conversation -> OneToOne.second slackParentId conversation.linkedMessageIds)
                                of
                                    Just threadId ->
                                        [ ViewThread threadId ]

                                    Nothing ->
                                        []

                            threadRoutes : List ThreadRoute
                            threadRoutes =
                                case message.inThread of
                                    Slack.NotAReply ->
                                        [ NoThread ]

                                    Slack.ReplyTo slackParentId ->
                                        parentId slackParentId

                                    Slack.BroadcastReplyTo slackParentId ->
                                        NoThread :: parentId slackParentId
                        in
                        List.foldl
                            (\threadRoute ( model2, cmds ) ->
                                case
                                    updateSlackConversation
                                        guildOrDmId
                                        (addToSlackConversation threadRoute message.id (UserTextMessage data2) (UserTextMessage threadData2))
                                        model2
                                of
                                    Just ( model3, threadRouteWithMessage ) ->
                                        let
                                            ( model4, notificationCmds ) =
                                                slackMessageAdded message.createdAt guildOrDmId threadRouteWithMessage data2 model3
                                        in
                                        ( model4
                                        , Broadcast.toSlack
                                            guildOrDmId
                                            (Server_Slack_SendMessage message.createdAt guildOrDmId threadRoute data2.content.content data2.content.attachedFiles (slackThreadStarter guildOrDmId threadRoute model4) |> ServerChange)
                                            model4
                                            :: Command.map identity (SlackGotMessageEmbed guildOrDmId threadRouteWithMessage) embedCmds
                                            :: notificationCmds
                                            ++ cmds
                                        )

                                    Nothing ->
                                        ( model2, cmds )
                            )
                            ( model, [] )
                            threadRoutes
                            |> Tuple.mapSecond Command.batch

                ( Nothing, _ ) ->
                    refreshSlackConversations linkedUser model

                _ ->
                    ( model, Command.none )

        Slack.WebsocketMessageChanged channelString message editedAt ->
            case
                ( slackChannelFromWebsocket linkedUser message.user channelString model
                , toMessage model.slackFiles (teamCustomEmojis linkedUser.user.teamId model) message
                )
            of
                ( Just guildOrDmId, Just (UserTextMessage data) ) ->
                    let
                        content : Nonempty (RichText (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
                        content =
                            data.content.content
                    in
                    case
                        updateSlackConversation
                            guildOrDmId
                            (\conversation -> editSlackMessage editedAt message.user content message.id conversation |> Just)
                            model
                    of
                        Just ( model2, edited ) ->
                            ( model2
                            , List.map
                                (\threadRoute ->
                                    Broadcast.toSlack
                                        guildOrDmId
                                        (Server_Slack_EditMessage editedAt message.user guildOrDmId threadRoute content |> ServerChange)
                                        model2
                                )
                                edited
                                |> Command.batch
                            )

                        Nothing ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Slack.WebsocketMessageDeleted channelString author slackMessageId ->
            case slackChannelFromWebsocket linkedUser author channelString model of
                Just guildOrDmId ->
                    case
                        updateSlackConversation
                            guildOrDmId
                            (\conversation -> deleteSlackMessage author slackMessageId conversation |> Just)
                            model
                    of
                        Just ( model2, deleted ) ->
                            ( model2
                            , List.map
                                (\threadRoute ->
                                    Broadcast.toSlack
                                        guildOrDmId
                                        (Server_Slack_DeleteMessage guildOrDmId threadRoute |> ServerChange)
                                        model2
                                )
                                deleted
                                |> Command.batch
                            )

                        Nothing ->
                            ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        Slack.WebsocketReactionAdded { user, reaction, channel, messageId } ->
            case
                ( slackChannelFromWebsocket linkedUser user channel model
                , emojiFromSlackName (teamCustomEmojis linkedUser.user.teamId model) reaction
                )
            of
                ( Just guildOrDmId, Just emoji ) ->
                    case
                        updateSlackConversation
                            guildOrDmId
                            (\conversation ->
                                let
                                    locations : List ThreadRouteWithMessage
                                    locations =
                                        slackMessageLocations messageId conversation
                                in
                                ( List.foldl (LocalState.addReactionEmoji emoji user) conversation locations, locations ) |> Just
                            )
                            model
                    of
                        Just ( model2, locations ) ->
                            ( model2
                            , List.map
                                (\threadRoute ->
                                    Broadcast.toSlack
                                        guildOrDmId
                                        (Server_Slack_AddReactionEmoji user guildOrDmId threadRoute emoji |> ServerChange)
                                        model2
                                )
                                locations
                                |> Command.batch
                            )

                        Nothing ->
                            ( model, Command.none )

                ( Just _, Nothing ) ->
                    ( model, Command.none )

                ( Nothing, Just _ ) ->
                    ( model, Command.none )

                ( Nothing, Nothing ) ->
                    ( model, Command.none )

        Slack.WebsocketReactionRemoved { user, reaction, channel, messageId } ->
            case
                ( slackChannelFromWebsocket linkedUser user channel model
                , emojiFromSlackName (teamCustomEmojis linkedUser.user.teamId model) reaction
                )
            of
                ( Just guildOrDmId, Just emoji ) ->
                    case
                        updateSlackConversation
                            guildOrDmId
                            (\conversation ->
                                let
                                    locations : List ThreadRouteWithMessage
                                    locations =
                                        slackMessageLocations messageId conversation
                                in
                                ( List.foldl (LocalState.removeReactionEmoji emoji user) conversation locations, locations ) |> Just
                            )
                            model
                    of
                        Just ( model2, locations ) ->
                            ( model2
                            , List.map
                                (\threadRoute ->
                                    Broadcast.toSlack
                                        guildOrDmId
                                        (Server_Slack_RemoveReactionEmoji user guildOrDmId threadRoute emoji |> ServerChange)
                                        model2
                                )
                                locations
                                |> Command.batch
                            )

                        Nothing ->
                            ( model, Command.none )

                ( Just _, Nothing ) ->
                    ( model, Command.none )

                ( Nothing, Just _ ) ->
                    ( model, Command.none )

                ( Nothing, Nothing ) ->
                    ( model, Command.none )

        Slack.WebsocketHello ->
            ( { model
                | slackUsers =
                    SeqDict.insert
                        linkedUser.user.id
                        (SlackFullData { linkedUser | reconnect = { failedAttempts = 0, seed = linkedUser.reconnect.seed } })
                        model.slackUsers
              }
            , if linkedUser.reconnect.failedAttempts > 0 then
                catchUpSlackConversations linkedUser model

              else
                Command.none
            )

        Slack.WebsocketUserChanged user ->
            case SeqDict.get user.id model.slackUsers of
                Just (SlackBasicData existing) ->
                    if user.teamId /= linkedUser.user.teamId || existing.user == user then
                        ( model, Command.none )

                    else if existing.user.image == user.image then
                        slackUserChanged user existing.icon model

                    else
                        ( model, uploadSlackImage model.serverSecret user.image |> Task.perform (GotChangedSlackUser user) )

                Just (SlackFullData existing) ->
                    if user.teamId /= linkedUser.user.teamId || existing.user == user then
                        ( model, Command.none )

                    else if existing.user.image == user.image then
                        slackUserChanged user existing.icon model

                    else
                        ( model, uploadSlackImage model.serverSecret user.image |> Task.perform (GotChangedSlackUser user) )

                Nothing ->
                    ( model, Command.none )

        Slack.WebsocketTeamRenamed name ->
            let
                teamId : Slack.Id Slack.TeamId
                teamId =
                    linkedUser.user.teamId

                model2 : BackendModel
                model2 =
                    { model
                        | slackWorkspaces =
                            SeqDict.updateIfExists teamId (\workspace -> { workspace | name = name }) model.slackWorkspaces
                    }
            in
            ( model2
            , Broadcast.toSlackTeam teamId (Server_Slack_WorkspaceRenamed teamId name |> ServerChange) model2
            )

        Slack.WebsocketConversationsChanged ->
            refreshSlackConversations linkedUser model

        Slack.WebsocketCustomEmojiAdded name source ->
            let
                teamId : Slack.Id Slack.TeamId
                teamId =
                    linkedUser.user.teamId

                emojis :
                    { tasks : List (Task BackendOnly Never ( Id CustomEmojiId, Result Http.Error FileStatus.UploadResponse ))
                    , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
                    , workspaceEmojis : SeqDict String (Id CustomEmojiId)
                    }
                emojis =
                    addSlackCustomEmojis
                        model.serverSecret
                        [ ( name, source ) ]
                        { tasks = [], customEmojis = model.customEmojis, workspaceEmojis = teamCustomEmojis teamId model }
            in
            case ( SeqDict.member name (teamCustomEmojis teamId model), SeqDict.get name emojis.workspaceEmojis ) of
                ( False, Just customEmojiId ) ->
                    case SeqDict.get customEmojiId emojis.customEmojis of
                        Just customEmoji ->
                            let
                                linkedTo : List (Id UserId)
                                linkedTo =
                                    SeqDict.foldl
                                        (\_ userData list ->
                                            case userData of
                                                SlackFullData linkedUser2 ->
                                                    if linkedUser2.user.teamId == teamId then
                                                        linkedUser2.linkedTo :: list

                                                    else
                                                        list

                                                SlackBasicData _ ->
                                                    list
                                        )
                                        []
                                        model.slackUsers

                                model2 : BackendModel
                                model2 =
                                    { model
                                        | customEmojis = emojis.customEmojis
                                        , slackWorkspaces =
                                            SeqDict.updateIfExists
                                                teamId
                                                (\workspace -> { workspace | customEmojis = emojis.workspaceEmojis })
                                                model.slackWorkspaces
                                        , users =
                                            List.foldl
                                                (\userId users ->
                                                    NonemptyDict.updateIfExists
                                                        userId
                                                        (\user -> { user | availableCustomEmojis = SeqSet.insert customEmojiId user.availableCustomEmojis })
                                                        users
                                                )
                                                model.users
                                                linkedTo
                                    }
                            in
                            ( model2
                            , Command.batch
                                [ Broadcast.toSlackTeam
                                    teamId
                                    (Server_Slack_CustomEmojiAdded teamId customEmojiId customEmoji |> ServerChange)
                                    model2
                                , case emojis.tasks of
                                    [] ->
                                        Command.none

                                    _ ->
                                        Task.sequence emojis.tasks
                                            |> Task.andThen (\results -> Task.map (GotSlackCustomEmojis teamId results) Time.now)
                                            |> Task.perform identity
                                ]
                            )

                        Nothing ->
                            ( model, Command.none )

                _ ->
                    ( model, Command.none )

        Slack.WebsocketChannelRenamed channelId name ->
            let
                teamId : Slack.Id Slack.TeamId
                teamId =
                    linkedUser.user.teamId

                channelName : ChannelName
                channelName =
                    ChannelName.fromStringLossy name

                model2 : BackendModel
                model2 =
                    { model
                        | slackWorkspaces =
                            SeqDict.updateIfExists
                                teamId
                                (\workspace ->
                                    { workspace
                                        | channels =
                                            SeqDict.updateIfExists
                                                channelId
                                                (\channel -> { channel | name = channelName })
                                                workspace.channels
                                    }
                                )
                                model.slackWorkspaces
                    }
            in
            ( model2
            , Broadcast.toSlackTeam teamId (Server_Slack_ChannelRenamed teamId channelId channelName |> ServerChange) model2
            )

        Slack.WebsocketTeamDomainChanged domain ->
            ( { model
                | slackWorkspaces =
                    SeqDict.updateIfExists
                        linkedUser.user.teamId
                        (\workspace -> { workspace | domain = domain })
                        model.slackWorkspaces
              }
            , Command.none
            )

        Slack.WebsocketOtherEvent ->
            ( model, Command.none )


{-| Custom emoji we haven't seen in this workspace before get an at-chat custom emoji each. Aliases
go by the emoji they name, and aliases of Slack's standard emoji are left out.
-}
addSlackCustomEmojis :
    SecretId ServerSecret
    -> List ( String, Slack.CustomEmojiSource )
    ->
        { tasks : List (Task BackendOnly Never ( Id CustomEmojiId, Result Http.Error FileStatus.UploadResponse ))
        , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
        , workspaceEmojis : SeqDict String (Id CustomEmojiId)
        }
    ->
        { tasks : List (Task BackendOnly Never ( Id CustomEmojiId, Result Http.Error FileStatus.UploadResponse ))
        , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
        , workspaceEmojis : SeqDict String (Id CustomEmojiId)
        }
addSlackCustomEmojis secretKey slackEmojis state =
    let
        state2 =
            List.foldl
                (\( name, source ) acc ->
                    case source of
                        Slack.CustomEmojiImage url ->
                            case slackCustomEmojiName name of
                                Just emojiName ->
                                    if SeqDict.member name acc.workspaceEmojis || not (Slack.isCustomEmojiHostedBySlack url) then
                                        acc

                                    else
                                        let
                                            customEmojiId : Id CustomEmojiId
                                            customEmojiId =
                                                Id.nextId acc.customEmojis
                                        in
                                        { tasks =
                                            (FileStatus.uploadUrl secretKey url []
                                                |> Task.map Ok
                                                |> Task.onError (\error -> Task.succeed (Err error))
                                                |> Task.map (Tuple.pair customEmojiId)
                                            )
                                                :: acc.tasks
                                        , customEmojis =
                                            SeqDict.insert
                                                customEmojiId
                                                { url = CustomEmojiLoading
                                                , name = emojiName
                                                , isAnimated = String.endsWith ".gif" url
                                                }
                                                acc.customEmojis
                                        , workspaceEmojis = SeqDict.insert name customEmojiId acc.workspaceEmojis
                                        }

                                Nothing ->
                                    acc

                        Slack.CustomEmojiAlias _ ->
                            acc
                )
                state
                slackEmojis
    in
    List.foldl
        (\( name, source ) acc ->
            case source of
                Slack.CustomEmojiImage _ ->
                    acc

                Slack.CustomEmojiAlias target ->
                    case SeqDict.get target acc.workspaceEmojis of
                        Just customEmojiId ->
                            { acc | workspaceEmojis = SeqDict.insert name customEmojiId acc.workspaceEmojis }

                        Nothing ->
                            acc
        )
        state2
        slackEmojis


{-| Slack's emoji names can have characters at-chat's can't, such as dashes, and can be a single
character.
-}
slackCustomEmojiName : String -> Maybe EmojiName
slackCustomEmojiName name =
    let
        name2 : String
        name2 =
            String.map
                (\char ->
                    if Char.isAlphaNum char || char == '_' then
                        char

                    else
                        '_'
                )
                name
                |> String.left 32
    in
    case CustomEmoji.emojiNameFromString name2 of
        Ok emojiName ->
            Just emojiName

        Err () ->
            case CustomEmoji.emojiNameFromString (name2 ++ "_") of
                Ok emojiName ->
                    Just emojiName

                Err () ->
                    Nothing


receivedSlackWebsocketEvent :
    SlackLinkedUser
    -> Slack.WebsocketEvent
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
receivedSlackWebsocketEvent linkedUser event model =
    let
        ( model2, lookUpCmd ) =
            lookUpUnknownSlackUsers linkedUser (websocketEventUserIds event) model
    in
    case List.filter (\file -> not (SeqDict.member file.id model2.slackFiles)) (websocketEventFiles event) of
        [] ->
            let
                ( model3, cmd ) =
                    handleSlackWebsocketEvent linkedUser event model2
            in
            ( model3, Command.batch [ cmd, lookUpCmd ] )

        newFiles ->
            ( model2
            , Command.batch
                [ uploadSlackFiles model2.serverSecret linkedUser.cookie linkedUser.token newFiles
                    |> Task.perform (SlackMessageFilesUploaded linkedUser.user.id event)
                , lookUpCmd
                ]
            )


{-| Loads the messages posted while the websocket was down, and handles them as if they had come
through it. Replies in threads that were already there before are missed.
-}
catchUpSlackConversations : SlackLinkedUser -> BackendModel -> Command BackendOnly ToFrontend BackendMsg
catchUpSlackConversations linkedUser model =
    let
        newestMessage : OneToOne (Slack.Id Slack.MessageId) (Id ChannelMessageId) -> Maybe (Slack.Id Slack.MessageId)
        newestMessage linkedMessageIds =
            OneToOne.toList linkedMessageIds
                |> List.map (\( slackMessageId, _ ) -> Slack.idToString slackMessageId)
                |> List.maximum
                |> Maybe.map Slack.Id

        catchUp : Slack.Id channelId -> Slack.Id Slack.MessageId -> Task BackendOnly Never (List Slack.WebsocketEvent)
        catchUp channelId oldest =
            Slack.messagesSince model.serverSecret linkedUser.cookie linkedUser.token channelId oldest
                |> Task.map (List.map (Slack.WebsocketMessageCreated (Slack.idToString channelId)))

        channels : List (Task BackendOnly Never (List Slack.WebsocketEvent))
        channels =
            case SeqDict.get linkedUser.user.teamId model.slackWorkspaces of
                Just workspace ->
                    SeqDict.toList workspace.channels
                        |> List.filterMap
                            (\( channelId, channel ) ->
                                if SeqSet.member linkedUser.user.id channel.linkedMembers then
                                    newestMessage channel.linkedMessageIds |> Maybe.map (catchUp channelId)

                                else
                                    Nothing
                            )

                Nothing ->
                    []

        dmChannels : List (Task BackendOnly Never (List Slack.WebsocketEvent))
        dmChannels =
            SeqDict.toList model.slackDmChannels
                |> List.filterMap
                    (\( dmChannelId, dmChannel ) ->
                        if NonemptySet.member linkedUser.user.id dmChannel.members then
                            newestMessage dmChannel.linkedMessageIds |> Maybe.map (catchUp dmChannelId)

                        else
                            Nothing
                    )
    in
    Task.sequence (channels ++ dmChannels)
        |> Task.map List.concat
        |> Task.perform (CaughtUpSlackMessages linkedUser.user.id)


{-| Returns the new message's ts, and the Slack ID of each file. Files that can't be read from
at-chat's storage are left out.
-}
sendSlackMessage :
    SecretId ServerSecret
    -> SlackLinkedUser
    -> Slack.Id channelId
    -> Maybe (Slack.Id Slack.MessageId)
    -> String
    -> List Slack.RichTextElement
    -> SeqDict (Id FileId) FileData
    -> Task BackendOnly Slack.HttpError ( Slack.Id Slack.MessageId, List ( Slack.Id Slack.FileId, FileData ) )
sendSlackMessage secretKey slackUser channelId maybeThreadId text blocks attachedFiles =
    if SeqDict.isEmpty attachedFiles then
        Slack.postMessage secretKey slackUser.cookie slackUser.token channelId maybeThreadId text blocks
            |> Task.map (\messageId -> ( messageId, [] ))

    else
        SeqDict.values attachedFiles
            |> List.map
                (\fileData2 ->
                    Http.task
                        { method = "GET"
                        , headers = []
                        , url = FileStatus.fileUrl fileData2.contentType fileData2.fileHash
                        , body = Http.emptyBody
                        , resolver =
                            Http.bytesResolver
                                (\response ->
                                    case response of
                                        Http.GoodStatus_ _ body ->
                                            Ok
                                                ( fileData2
                                                , { fileName = FileName.toString fileData2.fileName
                                                  , contentType = FileStatus.contentTypeHeader fileData2.contentType
                                                  , bytes = body
                                                  }
                                                )

                                        _ ->
                                            Err ()
                                )
                        , timeout = Duration.seconds 30 |> Just
                        }
                        |> Task.map Just
                        |> Task.onError (\() -> Task.succeed Nothing)
                )
            |> Task.sequence
            |> Task.andThen
                (\files ->
                    case List.filterMap identity files of
                        (( _, first ) :: rest) as files2 ->
                            Slack.postMessageWithFiles
                                secretKey
                                slackUser.cookie
                                slackUser.token
                                channelId
                                maybeThreadId
                                blocks
                                (Nonempty first (List.map Tuple.second rest))
                                |> Task.map
                                    (\( messageId, fileIds ) ->
                                        ( messageId, List.map2 Tuple.pair (List.Nonempty.toList fileIds) (List.map Tuple.first files2) )
                                    )

                        [] ->
                            Slack.postMessage secretKey slackUser.cookie slackUser.token channelId maybeThreadId text blocks
                                |> Task.map (\messageId -> ( messageId, [] ))
                )


{-| Adds what loadSlackWorkspaceData loaded, keeping the messages of conversations we already had.
The workspace's custom emoji start out loading and are copied to at-chat afterwards, so linking
doesn't wait on them, and the at-chat user the Slack account is linked to can use all of them.
-}
addLoadedSlackWorkspace :
    Slack.Id Slack.TeamId
    -> Slack.Id Slack.UserId
    -> LoadedSlackWorkspace
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
addLoadedSlackWorkspace teamId slackUserId { channels, dmChannels, users, selfIcon, workspaceIcon, files, customEmojis } model =
    let
        slackFiles : SeqDict (Slack.Id Slack.FileId) SlackFileData
        slackFiles =
            SeqDict.union files model.slackFiles

        emojis :
            { tasks : List (Task BackendOnly Never ( Id CustomEmojiId, Result Http.Error FileStatus.UploadResponse ))
            , customEmojis : SeqDict (Id CustomEmojiId) CustomEmojiData
            , workspaceEmojis : SeqDict String (Id CustomEmojiId)
            }
        emojis =
            addSlackCustomEmojis
                model.serverSecret
                customEmojis
                { tasks = [], customEmojis = model.customEmojis, workspaceEmojis = teamCustomEmojis teamId model }

        model2 : BackendModel
        model2 =
            { model
                | customEmojis = emojis.customEmojis
                , users =
                    case SeqDict.get slackUserId model.slackUsers of
                        Just (SlackFullData linkedUser) ->
                            NonemptyDict.updateIfExists
                                linkedUser.linkedTo
                                (\user ->
                                    { user
                                        | availableCustomEmojis =
                                            SeqDict.values emojis.workspaceEmojis
                                                |> SeqSet.fromList
                                                |> SeqSet.union user.availableCustomEmojis
                                    }
                                )
                                model.users

                        Just (SlackBasicData _) ->
                            model.users

                        Nothing ->
                            model.users
            }
    in
    ( addLoadedSlackWorkspaceHelper teamId slackUserId slackFiles emojis.workspaceEmojis channels dmChannels users selfIcon workspaceIcon model2
    , case emojis.tasks of
        [] ->
            Command.none

        _ ->
            Task.sequence emojis.tasks
                |> Task.andThen (\results -> Task.map (GotSlackCustomEmojis teamId results) Time.now)
                |> Task.perform identity
    )


addLoadedSlackWorkspaceHelper :
    Slack.Id Slack.TeamId
    -> Slack.Id Slack.UserId
    -> SeqDict (Slack.Id Slack.FileId) SlackFileData
    -> SeqDict String (Id CustomEmojiId)
    -> List ( Slack.Channel, Slack.History )
    -> List ( Slack.DmChannel, Slack.History )
    -> List ( Slack.User, Maybe FileHash )
    -> Maybe FileHash
    -> Maybe FileHash
    -> BackendModel
    -> BackendModel
addLoadedSlackWorkspaceHelper teamId slackUserId slackFiles workspaceEmojis channels dmChannels users selfIcon workspaceIcon model =
    { model
        | slackFiles = slackFiles
        , slackWorkspaces =
            SeqDict.updateIfExists
                teamId
                (\workspace ->
                    { workspace
                        | icon = workspaceIcon
                        , customEmojis = workspaceEmojis
                        , channels =
                            List.foldl
                                (\( channel, channelHistory ) dict ->
                                    SeqDict.insert
                                        channel.id
                                        (case SeqDict.get channel.id dict of
                                            Just existing ->
                                                { existing
                                                    | name = ChannelName.fromStringLossy channel.name
                                                    , isPrivate = channel.isPrivate
                                                    , linkedMembers = SeqSet.insert slackUserId existing.linkedMembers
                                                }

                                            Nothing ->
                                                let
                                                    conversation =
                                                        conversationFromHistory slackFiles workspaceEmojis channelHistory
                                                in
                                                { name = ChannelName.fromStringLossy channel.name
                                                , isPrivate = channel.isPrivate
                                                , linkedMembers = SeqSet.singleton slackUserId
                                                , messages = conversation.messages
                                                , linkedMessageIds = conversation.linkedMessageIds
                                                , threads = conversation.threads
                                                }
                                        )
                                        dict
                                )
                                (SeqDict.map
                                    (\_ channel -> { channel | linkedMembers = SeqSet.remove slackUserId channel.linkedMembers })
                                    workspace.channels
                                )
                                channels
                    }
                )
                model.slackWorkspaces
        , slackDmChannels =
            List.foldl
                (\( dmChannel, dmHistory ) dict ->
                    SeqDict.insert
                        dmChannel.id
                        (case SeqDict.get dmChannel.id dict of
                            Just existing ->
                                { existing | members = dmChannel.members }

                            Nothing ->
                                let
                                    conversation =
                                        conversationFromHistory slackFiles workspaceEmojis dmHistory
                                in
                                { teamId = teamId
                                , members = dmChannel.members
                                , messages = conversation.messages
                                , linkedMessageIds = conversation.linkedMessageIds
                                , threads = conversation.threads
                                }
                        )
                        dict
                )
                model.slackDmChannels
                dmChannels
        , slackUsers =
            List.foldl
                (\( user, icon ) dict ->
                    SeqDict.insert
                        user.id
                        (case SeqDict.get user.id dict of
                            Just (SlackFullData linkedUser) ->
                                SlackFullData { linkedUser | user = user, icon = icon }

                            Just (SlackBasicData _) ->
                                SlackBasicData { user = user, icon = icon }

                            Nothing ->
                                SlackBasicData { user = user, icon = icon }
                        )
                        dict
                )
                (SeqDict.updateIfExists
                    slackUserId
                    (\userData ->
                        case userData of
                            SlackFullData linkedUser ->
                                SlackFullData { linkedUser | icon = selfIcon }

                            SlackBasicData basicData ->
                                SlackBasicData { basicData | icon = selfIcon }
                    )
                    model.slackUsers
                )
                users
    }


{-| Reloads the linked Slack user's list of channels and DMs, for when they've joined or left one
or a message arrives in one we don't have. New channels start out read like they do when linking,
while new DMs keep their messages unread since they are usually what caused the refresh.
-}
refreshSlackConversations : SlackLinkedUser -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
refreshSlackConversations linkedUser model =
    if SeqSet.member linkedUser.user.id model.refreshingSlackConversations then
        ( model, Command.none )

    else
        ( { model | refreshingSlackConversations = SeqSet.insert linkedUser.user.id model.refreshingSlackConversations }
        , Slack.userBoot model.serverSecret linkedUser.cookie linkedUser.token
            |> Task.andThen
                (\{ self, team } ->
                    loadSlackWorkspaceData model linkedUser.cookie linkedUser.token self team
                        |> Task.map (Tuple.pair team.id)
                )
            |> Task.onError (\error -> Time.now |> Task.andThen (\time -> Task.fail ( time, error )))
            |> Task.attempt (RefreshedSlackConversations linkedUser.user.id)
        )


{-| Every linked Slack account in the workspace gets the same profile change, so this runs once
per account but only the first one changes anything.
-}
slackUserChanged : Slack.User -> Maybe FileHash -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
slackUserChanged user icon model =
    case SeqDict.get user.id model.slackUsers of
        Just userData ->
            let
                userData2 : SlackUserData
                userData2 =
                    case userData of
                        SlackBasicData _ ->
                            SlackBasicData { user = user, icon = icon }

                        SlackFullData linkedUser ->
                            SlackFullData { linkedUser | user = user, icon = icon }

                model2 : BackendModel
                model2 =
                    { model | slackUsers = SeqDict.insert user.id userData2 model.slackUsers }
            in
            ( model2
            , Broadcast.toSlackTeam
                user.teamId
                (Server_Slack_UserLoaded user.id (slackUserToFrontend model2.users userData2) |> ServerChange)
                model2
            )

        Nothing ->
            ( model, Command.none )


{-| Keeps up the last viewed message of everyone reading the conversation, marks the message
read for whoever wrote it, gives a red dot to the linked accounts it mentions and notifies them.
-}
slackMessageAdded :
    Time.Posix
    -> SlackGuildOrDmId
    -> ThreadRouteWithMessage
    -> UserTextMessageData messageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId)
    -> BackendModel
    -> ( BackendModel, List (Command BackendOnly ToFrontend BackendMsg) )
slackMessageAdded time guildOrDmId threadRouteWithMessage data model =
    let
        threadRoute : ThreadRoute
        threadRoute =
            Id.threadRouteWithoutMessage threadRouteWithMessage

        ( sessions, notificationCmds ) =
            Broadcast.slackMessageNotification time guildOrDmId threadRoute data model

        viewers : List ( Id UserId, AnyGuildOrDmId )
        viewers =
            Broadcast.usersViewingSlackConversation guildOrDmId threadRoute model

        authorLinkedTo : Maybe (Id UserId)
        authorLinkedTo =
            case SeqDict.get (slackAuthor guildOrDmId) model.slackUsers of
                Just (SlackFullData linkedUser) ->
                    Just linkedUser.linkedTo

                Just (SlackBasicData _) ->
                    Nothing

                Nothing ->
                    Nothing

        users2 : NonemptyDict (Id UserId) BackendUser
        users2 =
            List.foldl
                (\( userId, viewerGuildOrDmId ) usersAcc ->
                    NonemptyDict.updateIfExists
                        userId
                        (LocalState.incrementLastViewedMessageBackend viewerGuildOrDmId threadRouteWithMessage)
                        usersAcc
                )
                model.users
                viewers

        users3 : NonemptyDict (Id UserId) BackendUser
        users3 =
            case authorLinkedTo of
                Just userId ->
                    NonemptyDict.updateIfExists
                        userId
                        (User.setLastViewedMessage (SlackGuildOrDmId guildOrDmId) threadRouteWithMessage)
                        users2

                Nothing ->
                    users2

        users4 : NonemptyDict (Id UserId) BackendUser
        users4 =
            case guildOrDmId of
                SlackGuildOrDmId_Workspace { teamId, channelId } ->
                    SeqSet.foldl
                        (\mentioned usersAcc ->
                            case SeqDict.get mentioned model.slackUsers of
                                Just (SlackFullData linkedUser) ->
                                    if
                                        (Just linkedUser.linkedTo == authorLinkedTo)
                                            || List.any (\( viewer, _ ) -> viewer == linkedUser.linkedTo) viewers
                                    then
                                        usersAcc

                                    else
                                        NonemptyDict.updateIfExists
                                            linkedUser.linkedTo
                                            (User.addSlackDirectMention teamId channelId threadRoute)
                                            usersAcc

                                Just (SlackBasicData _) ->
                                    usersAcc

                                Nothing ->
                                    usersAcc
                        )
                        users3
                        (Broadcast.slackMentionedMembers teamId channelId data.content.content model)

                SlackGuildOrDmId_Dm _ ->
                    users3
    in
    ( { model | users = users4, sessions = sessions }, notificationCmds )


type alias SlackConversation =
    { messages : IdArray ChannelMessageId (Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
    , linkedMessageIds : OneToOne (Slack.Id Slack.MessageId) (Id ChannelMessageId)
    , threads : SeqDict (Id ChannelMessageId) SlackBackendThread
    }


{-| Sent along with a thread reply, since the message the thread started from may be too old for the
frontend to have loaded, and the thread is named after it.
-}
slackThreadStarter : SlackGuildOrDmId -> ThreadRoute -> BackendModel -> Maybe (Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
slackThreadStarter guildOrDmId threadRoute model =
    case threadRoute of
        ViewThread threadId ->
            getSlackConversation guildOrDmId model |> Maybe.andThen (\conversation -> IdArray.get threadId conversation.messages)

        NoThread ->
            Nothing


getSlackConversation : SlackGuildOrDmId -> BackendModel -> Maybe SlackConversation
getSlackConversation guildOrDmId model =
    case guildOrDmId of
        SlackGuildOrDmId_Workspace { teamId, channelId } ->
            LocalState.getSlackWorkspaceAndChannel teamId channelId model
                |> Maybe.map
                    (\( _, channel ) ->
                        { messages = channel.messages, linkedMessageIds = channel.linkedMessageIds, threads = channel.threads }
                    )

        SlackGuildOrDmId_Dm { channelId } ->
            SeqDict.get channelId model.slackDmChannels
                |> Maybe.map
                    (\channel ->
                        { messages = channel.messages, linkedMessageIds = channel.linkedMessageIds, threads = channel.threads }
                    )


updateSlackConversation :
    SlackGuildOrDmId
    -> (SlackConversation -> Maybe ( SlackConversation, a ))
    -> BackendModel
    -> Maybe ( BackendModel, a )
updateSlackConversation guildOrDmId updateFunc model =
    case guildOrDmId of
        SlackGuildOrDmId_Workspace { teamId, channelId } ->
            LocalState.getSlackWorkspaceAndChannel teamId channelId model
                |> Maybe.andThen
                    (\( workspace, channel ) ->
                        updateFunc { messages = channel.messages, linkedMessageIds = channel.linkedMessageIds, threads = channel.threads }
                            |> Maybe.map
                                (\( conversation, a ) ->
                                    ( { model
                                        | slackWorkspaces =
                                            SeqDict.insert
                                                teamId
                                                { workspace
                                                    | channels =
                                                        SeqDict.insert
                                                            channelId
                                                            { channel
                                                                | messages = conversation.messages
                                                                , linkedMessageIds = conversation.linkedMessageIds
                                                                , threads = conversation.threads
                                                            }
                                                            workspace.channels
                                                }
                                                model.slackWorkspaces
                                      }
                                    , a
                                    )
                                )
                    )

        SlackGuildOrDmId_Dm { channelId } ->
            SeqDict.get channelId model.slackDmChannels
                |> Maybe.andThen
                    (\channel ->
                        updateFunc { messages = channel.messages, linkedMessageIds = channel.linkedMessageIds, threads = channel.threads }
                            |> Maybe.map
                                (\( conversation, a ) ->
                                    ( { model
                                        | slackDmChannels =
                                            SeqDict.insert
                                                channelId
                                                { channel
                                                    | messages = conversation.messages
                                                    , linkedMessageIds = conversation.linkedMessageIds
                                                    , threads = conversation.threads
                                                }
                                                model.slackDmChannels
                                      }
                                    , a
                                    )
                                )
                    )


{-| Nothing if the message is already there, or it replies to a message at-chat doesn't have.
The same message is passed twice since a channel message and a thread message have different id
types.
-}
addToSlackConversation :
    ThreadRoute
    -> Slack.Id Slack.MessageId
    -> Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId)
    -> Message ThreadMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId)
    -> SlackConversation
    -> Maybe ( SlackConversation, ThreadRouteWithMessage )
addToSlackConversation threadRoute slackMessageId channelMessage threadMessage conversation =
    case threadRoute of
        NoThread ->
            if OneToOne.memberFirst slackMessageId conversation.linkedMessageIds then
                Nothing

            else
                let
                    messageId : Id ChannelMessageId
                    messageId =
                        IdArray.nextId conversation.messages
                in
                ( { conversation
                    | messages = IdArray.push channelMessage conversation.messages
                    , linkedMessageIds = OneToOne.insert slackMessageId messageId conversation.linkedMessageIds
                  }
                , NoThreadWithMessage messageId
                )
                    |> Just

        ViewThread threadId ->
            let
                thread : SlackBackendThread
                thread =
                    SeqDict.get threadId conversation.threads |> Maybe.withDefault Thread.slackBackendInit

                messageId : Id ThreadMessageId
                messageId =
                    IdArray.nextId thread.messages
            in
            if IdArray.get threadId conversation.messages == Nothing || OneToOne.memberFirst slackMessageId thread.linkedMessageIds then
                Nothing

            else
                ( { conversation
                    | threads =
                        SeqDict.insert
                            threadId
                            { messages = IdArray.push threadMessage thread.messages
                            , linkedMessageIds = OneToOne.insert slackMessageId messageId thread.linkedMessageIds
                            }
                            conversation.threads
                  }
                , ViewThreadWithMessage threadId messageId
                )
                    |> Just


{-| Slack shows a message's text in notifications, where custom emojis go by their names.
-}
slackCustomEmojiText :
    SeqDict (Id CustomEmojiId) String
    -> Nonempty (RichText (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
    -> String
    -> String
slackCustomEmojiText customEmojiNames2 richText text =
    List.foldl
        (\customEmojiId text2 ->
            String.replace
                (CustomEmoji.idToString customEmojiId)
                (case SeqDict.get customEmojiId customEmojiNames2 of
                    Just name ->
                        ":" ++ name ++ ":"

                    Nothing ->
                        ""
                )
                text2
        )
        text
        (RichText.customEmojis richText)


slackMessageTs : ThreadRouteWithMessage -> SlackConversation -> Maybe (Slack.Id Slack.MessageId)
slackMessageTs threadRoute conversation =
    case threadRoute of
        NoThreadWithMessage messageId ->
            OneToOne.first messageId conversation.linkedMessageIds

        ViewThreadWithMessage threadId messageId ->
            SeqDict.get threadId conversation.threads |> Maybe.andThen (\thread -> OneToOne.first messageId thread.linkedMessageIds)


asSlackConversationUser :
    BackendModel
    -> SessionId
    -> SlackGuildOrDmId
    -> (UserSession -> SlackLinkedUser -> Slack.Id Slack.ChannelId -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
asSlackConversationUser model sessionId guildOrDmId func =
    case guildOrDmId of
        SlackGuildOrDmId_Workspace id ->
            BackendExtra.asSlackChannelMember model sessionId id (\session slackUser _ _ -> func session slackUser id.channelId)

        SlackGuildOrDmId_Dm data ->
            -- Slack's API takes a DM's id wherever it takes a channel's
            BackendExtra.asSlackDmUser model sessionId data (\session slackUser _ -> func session slackUser (Slack.Id (Slack.idToString data.channelId)))


{-| Edits the message in every place it is in, as long as it's by the given author, and returns
where it was edited.
-}
editSlackMessage :
    Time.Posix
    -> Slack.Id Slack.UserId
    -> Nonempty (RichText (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
    -> Slack.Id Slack.MessageId
    -> SlackConversation
    -> ( SlackConversation, List ThreadRouteWithMessage )
editSlackMessage editedAt author content slackMessageId conversation =
    List.foldl
        (\threadRoute ( conversation2, edited ) ->
            case LocalState.editMessageHelper editedAt author content DoNotChangeAttachments threadRoute conversation2 of
                Ok conversation3 ->
                    ( conversation3, threadRoute :: edited )

                Err () ->
                    ( conversation2, edited )
        )
        ( conversation, [] )
        (slackMessageLocations slackMessageId conversation)


{-| Deletes the message from every place it is in, as long as it's by the given author, and returns
where it was deleted from.
-}
deleteSlackMessage : Slack.Id Slack.UserId -> Slack.Id Slack.MessageId -> SlackConversation -> ( SlackConversation, List ThreadRouteWithMessage )
deleteSlackMessage author slackMessageId conversation =
    List.foldl
        (\threadRoute ( conversation2, deleted ) ->
            case LocalState.deleteMessageBackendHelper author threadRoute conversation2 of
                Ok conversation3 ->
                    ( conversation3, threadRoute :: deleted )

                Err () ->
                    ( conversation2, deleted )
        )
        ( conversation, [] )
        (slackMessageLocations slackMessageId conversation)


{-| A reply that was also sent to the channel is in two places.
-}
slackMessageLocations : Slack.Id Slack.MessageId -> SlackConversation -> List ThreadRouteWithMessage
slackMessageLocations slackMessageId conversation =
    (case OneToOne.second slackMessageId conversation.linkedMessageIds of
        Just messageId ->
            [ NoThreadWithMessage messageId ]

        Nothing ->
            []
    )
        ++ SeqDict.foldr
            (\threadId thread list ->
                case OneToOne.second slackMessageId thread.linkedMessageIds of
                    Just messageId ->
                        ViewThreadWithMessage threadId messageId :: list

                    Nothing ->
                        list
            )
            []
            conversation.threads


addLinkedSlackUser : Time.Posix -> Id UserId -> SlackCookie -> SlackToken -> Slack.UserBoot -> BackendModel -> BackendModel
addLinkedSlackUser linkedAt userId cookie token { self, team } model =
    { model
        | slackWorkspaces =
            SeqDict.update
                team.id
                (\maybeWorkspace ->
                    { name = team.name
                    , domain = team.domain
                    , icon =
                        case maybeWorkspace of
                            Just workspace ->
                                workspace.icon

                            Nothing ->
                                Nothing
                    , channels =
                        case maybeWorkspace of
                            Just workspace ->
                                workspace.channels

                            Nothing ->
                                SeqDict.empty
                    , customEmojis =
                        case maybeWorkspace of
                            Just workspace ->
                                workspace.customEmojis

                            Nothing ->
                                SeqDict.empty
                    }
                        |> Just
                )
                model.slackWorkspaces
        , slackUsers =
            SeqDict.insert
                self.id
                (SlackFullData
                    { user = self
                    , icon =
                        case SeqDict.get self.id model.slackUsers of
                            Just (SlackFullData existing) ->
                                existing.icon

                            Just (SlackBasicData existing) ->
                                existing.icon

                            Nothing ->
                                Nothing
                    , linkedTo = userId
                    , linkedAt = linkedAt
                    , token = token
                    , cookie = cookie
                    , websocket =
                        case SeqDict.get self.id model.slackUsers of
                            Just (SlackFullData existing) ->
                                existing.websocket

                            Just (SlackBasicData _) ->
                                Nothing

                            Nothing ->
                                Nothing
                    , reconnect =
                        case SeqDict.get self.id model.slackUsers of
                            Just (SlackFullData existing) ->
                                existing.reconnect

                            Just (SlackBasicData _) ->
                                { failedAttempts = 0, seed = Time.posixToMillis linkedAt }

                            Nothing ->
                                { failedAttempts = 0, seed = Time.posixToMillis linkedAt }
                    , needsAuthAgain = False
                    }
                )
                model.slackUsers
    }


{-| Hands the at-chat user everything linking loaded, so their open tabs show it without a reload.
The frontend marks the conversations it didn't have as viewed, the same way
`markNewSlackConversationsAsViewed` does, leaving out new DMs after a refresh.
-}
slackLinkedUserLoaded :
    Slack.Id Slack.UserId
    -> Slack.Id Slack.TeamId
    -> Bool
    -> BackendModel
    -> Command BackendOnly ToFrontend BackendMsg
slackLinkedUserLoaded slackUserId teamId markNewDmsAsViewed model =
    case SeqDict.get slackUserId model.slackUsers of
        Just (SlackFullData linkedUser) ->
            let
                linked : SeqDict (Slack.Id Slack.UserId) (Slack.Id Slack.TeamId)
                linked =
                    BackendExtra.linkedSlackUsers linkedUser.linkedTo model.slackUsers
            in
            Broadcast.toUser
                Nothing
                Nothing
                linkedUser.linkedTo
                (Server_Slack_LinkedUserLoaded
                    slackUserId
                    teamId
                    { workspaces = BackendExtra.slackWorkspacesToFrontend linked model.slackWorkspaces
                    , dmChannels = BackendExtra.slackDmChannelsToFrontend linked model.slackDmChannels
                    , users = slackUsersToFrontend model.users linked model.slackUsers
                    , customEmojis =
                        SeqDict.values (teamCustomEmojis teamId model)
                            |> List.filterMap (\customEmojiId -> SeqDict.get customEmojiId model.customEmojis |> Maybe.map (Tuple.pair customEmojiId))
                            |> SeqDict.fromList
                    , markNewDmsAsViewed = markNewDmsAsViewed
                    }
                    |> ServerChange
                )
                model

        Just (SlackBasicData _) ->
            Command.none

        Nothing ->
            Command.none


{-| The channels and DMs in what was loaded that the at-chat user couldn't see before, which are
the ones their frontend doesn't have yet. A Slack account that has never been loaded before (it
isn't a member of any of the workspace's channels yet) didn't make any DMs visible.
-}
newSlackConversations :
    Slack.Id Slack.UserId
    -> Slack.Id Slack.TeamId
    -> LoadedSlackWorkspace
    -> BackendModel
    -> ( List (Slack.Id Slack.ChannelId), List (Slack.Id Slack.DmChannelId) )
newSlackConversations slackUserId teamId data model =
    case SeqDict.get slackUserId model.slackUsers of
        Just (SlackFullData linkedUser) ->
            let
                linked : SeqDict (Slack.Id Slack.UserId) (Slack.Id Slack.TeamId)
                linked =
                    BackendExtra.linkedSlackUsers linkedUser.linkedTo model.slackUsers

                existingChannels : SeqDict (Slack.Id Slack.ChannelId) SlackBackendChannel
                existingChannels =
                    case SeqDict.get teamId model.slackWorkspaces of
                        Just workspace ->
                            workspace.channels

                        Nothing ->
                            SeqDict.empty

                linkedBefore : SeqDict (Slack.Id Slack.UserId) (Slack.Id Slack.TeamId)
                linkedBefore =
                    if List.any (\channel -> SeqSet.member slackUserId channel.linkedMembers) (SeqDict.values existingChannels) then
                        linked

                    else
                        SeqDict.remove slackUserId linked
            in
            ( List.filterMap
                (\( channel, _ ) ->
                    case SeqDict.get channel.id existingChannels of
                        Just existing ->
                            if BackendExtra.isSlackChannelVisible linked existing then
                                Nothing

                            else
                                Just channel.id

                        Nothing ->
                            Just channel.id
                )
                data.channels
            , List.filterMap
                (\( dmChannel, _ ) ->
                    case SeqDict.get dmChannel.id model.slackDmChannels of
                        Just existing ->
                            if BackendExtra.isSlackDmChannelVisible linkedBefore existing then
                                Nothing

                            else
                                Just dmChannel.id

                        Nothing ->
                            Just dmChannel.id
                )
                data.dmChannels
            )

        Just (SlackBasicData _) ->
            ( [], [] )

        Nothing ->
            ( [], [] )


{-| Linking Slack loads the newest messages of every conversation, and none of them are new to
the person linking it, so conversations they've never had a last viewed message in start out read.
-}
markNewSlackConversationsAsViewed :
    Slack.Id Slack.UserId
    -> Slack.Id Slack.TeamId
    -> List (Slack.Id Slack.ChannelId)
    -> List (Slack.Id Slack.DmChannelId)
    -> BackendModel
    -> BackendModel
markNewSlackConversationsAsViewed slackUserId teamId channelIds dmChannelIds model =
    case SeqDict.get slackUserId model.slackUsers of
        Just (SlackFullData linkedUser) ->
            let
                markAsViewed : SlackGuildOrDmId -> BackendUser -> BackendUser
                markAsViewed guildOrDmId user =
                    case getSlackConversation guildOrDmId model of
                        Just conversation ->
                            if IdArray.length conversation.messages > 0 && not (SeqDict.member (SlackGuildOrDmId guildOrDmId) user.lastViewedMessage) then
                                SeqDict.foldl
                                    (\threadId thread user2 ->
                                        User.setLastViewedMessage
                                            (SlackGuildOrDmId guildOrDmId)
                                            (ViewThreadWithMessage threadId (DmChannel.latestThreadMessageId thread))
                                            user2
                                    )
                                    (User.setLastViewedMessage
                                        (SlackGuildOrDmId guildOrDmId)
                                        (NoThreadWithMessage (DmChannel.latestMessageId conversation))
                                        user
                                    )
                                    conversation.threads

                            else
                                user

                        Nothing ->
                            user

                markChannels : BackendUser -> BackendUser
                markChannels user =
                    List.foldl
                        (\channelId user2 ->
                            let
                                guildOrDmId : SlackGuildOrDmId
                                guildOrDmId =
                                    SlackGuildOrDmId_Workspace { currentUserId = slackUserId, teamId = teamId, channelId = channelId }
                            in
                            markAsViewed guildOrDmId user2
                        )
                        user
                        channelIds

                markDmChannels : BackendUser -> BackendUser
                markDmChannels user =
                    List.foldl
                        (\channelId user2 ->
                            let
                                guildOrDmId : SlackGuildOrDmId
                                guildOrDmId =
                                    SlackGuildOrDmId_Dm { currentUserId = slackUserId, channelId = channelId }
                            in
                            markAsViewed guildOrDmId user2
                        )
                        user
                        dmChannelIds
            in
            { model | users = NonemptyDict.updateIfExists linkedUser.linkedTo (\user -> markChannels user |> markDmChannels) model.users }

        Just (SlackBasicData _) ->
            model

        Nothing ->
            model


slackAuthor : SlackGuildOrDmId -> Slack.Id Slack.UserId
slackAuthor guildOrDmId =
    case guildOrDmId of
        SlackGuildOrDmId_Workspace data ->
            data.currentUserId

        SlackGuildOrDmId_Dm data ->
            data.currentUserId


{-| Copies the files to at-chat. A file that fails to copy is left out, so its message shows
without it.
-}
uploadSlackFiles :
    SecretId ServerSecret
    -> SlackCookie
    -> SlackToken
    -> List Slack.File
    -> Task BackendOnly x (SeqDict (Slack.Id Slack.FileId) SlackFileData)
uploadSlackFiles secretKey cookie token files =
    List.map
        (\file ->
            FileStatus.uploadUrl secretKey file.url (Slack.fileHeaders cookie token)
                |> Task.map
                    (\uploadResponse ->
                        Just
                            ( file.id
                            , { fileHash = uploadResponse.fileHash, metadata = FileStatus.uploadResponseMetadata uploadResponse }
                            )
                    )
                |> Task.onError (\_ -> Task.succeed Nothing)
        )
        (List.filter
            (\file -> Slack.isHostedBySlack file && file.size <= FileStatus.maxUploadSize)
            (List.Extra.uniqueBy (\file -> Slack.idToString file.id) files)
        )
        |> Task.sequence
        |> Task.map (\results -> List.filterMap identity results |> SeqDict.fromList)


{-| Profile pictures and workspace icons don't need credentials to download.
-}
uploadSlackImage : SecretId ServerSecret -> String -> Task BackendOnly x (Maybe FileHash)
uploadSlackImage secretKey url =
    if url == "" then
        Task.succeed Nothing

    else
        FileStatus.uploadUrl secretKey url []
            |> Task.map (\uploadResponse -> Just uploadResponse.fileHash)
            |> Task.onError (\_ -> Task.succeed Nothing)


{-| Loads every channel and DM the linked Slack user can see, along with the newest messages of
the channels and DMs we didn't have before, and the users in those we haven't seen yet.
-}
loadSlackWorkspaceData :
    BackendModel
    -> SlackCookie
    -> SlackToken
    -> Slack.User
    -> Slack.Team
    -> Task BackendOnly Slack.HttpError LoadedSlackWorkspace
loadSlackWorkspaceData model cookie token self team =
    let
        teamId : Slack.Id Slack.TeamId
        teamId =
            team.id

        existingChannels : SeqDict (Slack.Id Slack.ChannelId) SlackBackendChannel
        existingChannels =
            case SeqDict.get teamId model.slackWorkspaces of
                Just workspace ->
                    workspace.channels

                Nothing ->
                    SeqDict.empty

        history : Slack.Id channelId -> Task BackendOnly Slack.HttpError Slack.History
        history channelId =
            Slack.history model.serverSecret cookie token newChannelMaxMessages channelId

        noHistory : Slack.History
        noHistory =
            { messages = [], replies = SeqDict.empty }
    in
    Slack.userConversations model.serverSecret cookie token self.id
        |> Task.andThen
            (\{ channels, dmChannels } ->
                Task.map2
                    (\channels2 dmChannels2 -> { channels = channels2, dmChannels = dmChannels2 })
                    (List.map
                        (\channel ->
                            if SeqDict.member channel.id existingChannels then
                                Task.succeed ( channel, noHistory )

                            else
                                history channel.id |> Task.map (Tuple.pair channel)
                        )
                        channels
                        |> Task.sequence
                    )
                    (List.map
                        (\dmChannel ->
                            if SeqDict.member dmChannel.id model.slackDmChannels then
                                Task.succeed ( dmChannel, noHistory )

                            else
                                history dmChannel.id |> Task.map (Tuple.pair dmChannel)
                        )
                        dmChannels
                        |> Task.sequence
                    )
            )
        |> Task.andThen
            (\{ channels, dmChannels } ->
                let
                    historyUserIds : Slack.History -> List (Slack.Id Slack.UserId)
                    historyUserIds history2 =
                        List.concatMap Slack.messageUserIds history2.messages
                            ++ List.concatMap (List.concatMap Slack.messageUserIds) (SeqDict.values history2.replies)

                    unknownUserIds : List (Slack.Id Slack.UserId)
                    unknownUserIds =
                        List.concatMap (\( _, channelHistory ) -> historyUserIds channelHistory) channels
                            ++ List.concatMap
                                (\( dmChannel, dmHistory ) -> NonemptySet.toList dmChannel.members ++ historyUserIds dmHistory)
                                dmChannels
                            |> SeqSet.fromList
                            |> SeqSet.filter (\userId -> not (SeqDict.member userId model.slackUsers))
                            |> SeqSet.toList

                    usersWithoutIcon : List (Slack.Id Slack.UserId)
                    usersWithoutIcon =
                        SeqDict.toList model.slackUsers
                            |> List.filterMap
                                (\( userId, userData ) ->
                                    case userData of
                                        SlackBasicData { user, icon } ->
                                            if user.teamId == teamId && icon == Nothing then
                                                Just userId

                                            else
                                                Nothing

                                        SlackFullData _ ->
                                            Nothing
                                )
                in
                Slack.usersById model.serverSecret cookie token teamId (unknownUserIds ++ usersWithoutIcon)
                    |> Task.map (\users -> { channels = channels, dmChannels = dmChannels, users = users })
            )
        |> Task.andThen
            (\{ channels, dmChannels, users } ->
                let
                    historyFiles : Slack.History -> List Slack.File
                    historyFiles history2 =
                        List.concatMap Slack.messageFiles history2.messages
                            ++ List.concatMap (List.concatMap Slack.messageFiles) (SeqDict.values history2.replies)
                in
                Task.map5
                    (\users2 selfIcon workspaceIcon files customEmojis ->
                        { channels = channels
                        , dmChannels = dmChannels
                        , users = users2
                        , selfIcon = selfIcon
                        , workspaceIcon = workspaceIcon
                        , files = files
                        , customEmojis = customEmojis
                        }
                    )
                    (List.map
                        (\user -> uploadSlackImage model.serverSecret user.image |> Task.map (Tuple.pair user))
                        users
                        |> Task.sequence
                    )
                    (uploadSlackImage model.serverSecret self.image)
                    (case team.icon of
                        Just icon ->
                            uploadSlackImage model.serverSecret icon

                        Nothing ->
                            Task.succeed Nothing
                    )
                    (List.concatMap (\( _, channelHistory ) -> historyFiles channelHistory) channels
                        ++ List.concatMap (\( _, dmHistory ) -> historyFiles dmHistory) dmChannels
                        |> List.filter (\file -> not (SeqDict.member file.id model.slackFiles))
                        |> uploadSlackFiles model.serverSecret cookie token
                    )
                    (Slack.customEmojis model.serverSecret cookie token)
            )


{-| Linking only loads the users in the messages it loaded, so anyone else is looked up the first
time they show up.
-}
lookUpUnknownSlackUsers :
    SlackLinkedUser
    -> List (Slack.Id Slack.UserId)
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
lookUpUnknownSlackUsers linkedUser userIds model =
    let
        unknown : List (Slack.Id Slack.UserId)
        unknown =
            SeqSet.fromList userIds
                |> SeqSet.filter
                    (\userId ->
                        not (SeqDict.member userId model.slackUsers || SeqSet.member userId model.pendingSlackUserLookups)
                    )
                |> SeqSet.toList
    in
    ( { model | pendingSlackUserLookups = List.foldl SeqSet.insert model.pendingSlackUserLookups unknown }
    , List.map
        (\userId ->
            Slack.userInfo model.serverSecret linkedUser.cookie linkedUser.token linkedUser.user.teamId userId
                |> Task.andThen (\user -> uploadSlackImage model.serverSecret user.image |> Task.map (Tuple.pair user))
                |> Task.attempt (GotSlackUser userId)
        )
        unknown
        |> Command.batch
    )


websocketEventUserIds : Slack.WebsocketEvent -> List (Slack.Id Slack.UserId)
websocketEventUserIds event =
    case event of
        Slack.WebsocketMessageCreated _ message ->
            Slack.messageUserIds message

        Slack.WebsocketMessageChanged _ message _ ->
            Slack.messageUserIds message

        Slack.WebsocketMessageDeleted _ _ _ ->
            []

        Slack.WebsocketReactionAdded { user } ->
            [ user ]

        Slack.WebsocketReactionRemoved { user } ->
            [ user ]

        Slack.WebsocketRelayReady ->
            []

        Slack.WebsocketHello ->
            []

        Slack.WebsocketUserChanged _ ->
            []

        Slack.WebsocketTeamRenamed _ ->
            []

        Slack.WebsocketTeamDomainChanged _ ->
            []

        Slack.WebsocketConversationsChanged ->
            []

        Slack.WebsocketChannelRenamed _ _ ->
            []

        Slack.WebsocketCustomEmojiAdded _ _ ->
            []

        Slack.WebsocketOtherEvent ->
            []


websocketEventFiles : Slack.WebsocketEvent -> List Slack.File
websocketEventFiles event =
    case event of
        Slack.WebsocketMessageCreated _ message ->
            Slack.messageFiles message

        Slack.WebsocketMessageChanged _ message _ ->
            Slack.messageFiles message

        Slack.WebsocketMessageDeleted _ _ _ ->
            []

        Slack.WebsocketReactionAdded _ ->
            []

        Slack.WebsocketReactionRemoved _ ->
            []

        Slack.WebsocketRelayReady ->
            []

        Slack.WebsocketHello ->
            []

        Slack.WebsocketUserChanged _ ->
            []

        Slack.WebsocketTeamRenamed _ ->
            []

        Slack.WebsocketTeamDomainChanged _ ->
            []

        Slack.WebsocketConversationsChanged ->
            []

        Slack.WebsocketChannelRenamed _ _ ->
            []

        Slack.WebsocketCustomEmojiAdded _ _ ->
            []

        Slack.WebsocketOtherEvent ->
            []


slackPendingSendKey : SlackGuildOrDmId -> ( Slack.Id Slack.UserId, String )
slackPendingSendKey guildOrDmId =
    case guildOrDmId of
        SlackGuildOrDmId_Workspace { currentUserId, channelId } ->
            ( currentUserId, Slack.idToString channelId )

        SlackGuildOrDmId_Dm { currentUserId, channelId } ->
            ( currentUserId, Slack.idToString channelId )


{-| The same jittered exponential backoff as Discord's gateway: 0s, 1s, 3s, 7s… up to a minute,
each shortened by up to half. Slack's hello event resets it.
-}
nextSlackReconnectDelay : { failedAttempts : Int, seed : Int } -> ( Duration, { failedAttempts : Int, seed : Int } )
nextSlackReconnectDelay reconnect =
    let
        ( ( jitter, nextSeed ), _ ) =
            Random.step
                (Random.map2 Tuple.pair (Random.float 0.5 1) (Random.int Random.minInt Random.maxInt))
                (Random.initialSeed reconnect.seed)
    in
    ( Duration.seconds (2 ^ toFloat reconnect.failedAttempts - 1)
        |> Quantity.min (Duration.seconds 60)
        |> Quantity.multiplyBy jitter
    , { failedAttempts = reconnect.failedAttempts + 1, seed = nextSeed }
    )


{-| Slack doesn't say which channels are DMs in its websocket events, so the channel ID is
looked up in the linked user's workspace first and then among the DMs.
-}
slackChannelFromWebsocket : SlackLinkedUser -> Slack.Id Slack.UserId -> String -> BackendModel -> Maybe SlackGuildOrDmId
slackChannelFromWebsocket linkedUser author channelString model =
    let
        channelId : Slack.Id Slack.ChannelId
        channelId =
            Slack.Id channelString

        dmChannelId : Slack.Id Slack.DmChannelId
        dmChannelId =
            Slack.Id channelString
    in
    case LocalState.getSlackWorkspaceAndChannel linkedUser.user.teamId channelId model of
        Just _ ->
            SlackGuildOrDmId_Workspace { currentUserId = author, teamId = linkedUser.user.teamId, channelId = channelId }
                |> Just

        Nothing ->
            if SeqDict.member dmChannelId model.slackDmChannels then
                SlackGuildOrDmId_Dm { currentUserId = author, channelId = dmChannelId } |> Just

            else
                Nothing
