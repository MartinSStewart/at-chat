module SlackSync exposing
    ( basicUserToFrontend
    , conversationFromHistory
    , dmChannelsToFrontend
    , linkedUsers
    , newChannelMaxMessages
    , toMessage
    , unlinkUser
    , userDataName
    , usersToFrontend
    , workspacesToFrontend
    )

import DmChannel
import Drawing
import Emoji exposing (EmojiOrCustomEmoji(..))
import FileName
import FileStatus exposing (FileData, FileHash, FileId, IsEncrypted(..))
import Id exposing (ChannelMessageId, Id, UserId)
import IdArray exposing (IdArray)
import List.Nonempty
import LocalState exposing (SlackFrontendChannel, SlackFrontendDmChannel, SlackFrontendWorkspace)
import Message exposing (Message(..), RepliedTo(..))
import NonemptyDict exposing (NonemptyDict)
import NonemptyExtra
import NonemptySet exposing (NonemptySet)
import OneToOne exposing (OneToOne)
import PersonName exposing (PersonName)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import SeqSet
import Slack
import SlackEmoji
import Thread exposing (SlackBackendThread)
import Types exposing (BackendModel, SlackBackendChannel, SlackBackendWorkspace, SlackDmChannel, SlackFileData, SlackLinkedUser, SlackUserData(..))
import User exposing (BackendUser)
import UserSession exposing (SlackFrontendUser)
import VisibleMessages


newChannelMaxMessages : Int
newChannelMaxMessages =
    50


{-| Takes messages oldest first. Messages with nothing at-chat can show are left out.
-}
messagesAndLinks :
    SeqDict (Slack.Id Slack.FileId) SlackFileData
    -> List Slack.Message
    ->
        ( IdArray messageId (Message messageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
        , OneToOne (Slack.Id Slack.MessageId) (Id messageId)
        )
messagesAndLinks slackFiles messages =
    let
        converted : List ( Slack.Id Slack.MessageId, Message messageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId) )
        converted =
            List.filterMap
                (\message -> toMessage slackFiles message |> Maybe.map (Tuple.pair message.id))
                messages
    in
    ( IdArray.fromList (List.map Tuple.second converted)
    , List.indexedMap (\index ( slackId, _ ) -> ( slackId, Id.fromInt index )) converted |> OneToOne.fromList
    )


{-| A conversation built from its history, newest first as Slack gives it.
-}
conversationFromHistory :
    SeqDict (Slack.Id Slack.FileId) SlackFileData
    -> Slack.History
    ->
        { messages : IdArray ChannelMessageId (Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
        , linkedMessageIds : OneToOne (Slack.Id Slack.MessageId) (Id ChannelMessageId)
        , threads : SeqDict (Id ChannelMessageId) SlackBackendThread
        }
conversationFromHistory slackFiles history =
    let
        ( messages, linkedMessageIds ) =
            messagesAndLinks slackFiles (List.reverse history.messages)
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
                                messagesAndLinks slackFiles replies
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
    -> Slack.Message
    -> Maybe (Message messageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
toMessage slackFiles message =
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
            (case RichText.fromSlack text blocks of
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
                            (reactions message.reactions)
                            NoReply
                            attachedFiles
                            |> UserTextMessage
                    )

        Slack.JoinedChannel ->
            UserJoinedMessage message.createdAt message.user (reactions message.reactions) Drawing.emptyDrawing |> Just


fileData : Slack.File -> SlackFileData -> FileData
fileData file { fileHash, metadata } =
    { fileName = FileName.fromString file.name
    , fileSize = file.size
    , metadata = metadata
    , contentType = FileStatus.contentType file.mimetype
    , fileHash = fileHash
    , isEncrypted = IsNotEncrypted
    }


{-| Slack's custom emoji aren't in at-chat so reactions with them are left out.
-}
reactions : List Slack.Reaction -> SeqDict EmojiOrCustomEmoji (NonemptySet (Slack.Id Slack.UserId))
reactions slackReactions =
    List.foldl
        (\reaction dict ->
            case ( SlackEmoji.fromSlackName reaction.name, NonemptySet.fromList reaction.users ) of
                ( Just emoji, Just users ) ->
                    SeqDict.insert (EmojiOrCustomEmoji_Emoji emoji) users dict

                ( Just _, Nothing ) ->
                    dict

                ( Nothing, Just _ ) ->
                    dict

                ( Nothing, Nothing ) ->
                    dict
        )
        SeqDict.empty
        slackReactions


{-| The Slack accounts an at-chat user has linked, and the workspace each one is in.
-}
linkedUsers : Id UserId -> SeqDict (Slack.Id Slack.UserId) SlackUserData -> SeqDict (Slack.Id Slack.UserId) (Slack.Id Slack.TeamId)
linkedUsers userId slackUsers =
    SeqDict.foldl
        (\slackUserId userData dict ->
            case userData of
                SlackFullData linked ->
                    if linked.linkedTo == userId then
                        SeqDict.insert slackUserId linked.user.teamId dict

                    else
                        dict

                SlackBasicData _ ->
                    dict
        )
        SeqDict.empty
        slackUsers


workspacesToFrontend :
    SeqDict (Slack.Id Slack.UserId) (Slack.Id Slack.TeamId)
    -> SeqDict (Slack.Id Slack.TeamId) SlackBackendWorkspace
    -> SeqDict (Slack.Id Slack.TeamId) SlackFrontendWorkspace
workspacesToFrontend linked workspaces =
    SeqDict.filterMap
        (\teamId workspace ->
            if List.member teamId (SeqDict.values linked) then
                { name = workspace.name
                , icon = workspace.icon
                , channels = SeqDict.filterMap (\_ channel -> channelToFrontend linked channel) workspace.channels
                }
                    |> Just

            else
                Nothing
        )
        workspaces


channelToFrontend : SeqDict (Slack.Id Slack.UserId) a -> SlackBackendChannel -> Maybe SlackFrontendChannel
channelToFrontend linked channel =
    if List.any (\slackUserId -> SeqSet.member slackUserId channel.linkedMembers) (SeqDict.keys linked) then
        { name = channel.name
        , isPrivate = channel.isPrivate
        , messages = DmChannel.loadThreadStarters channel.threads channel.messages (Thread.loadMessages False channel.messages)
        , visibleMessages = VisibleMessages.init False (IdArray.length channel.messages)
        , threads = SeqDict.map (\_ thread -> Thread.slackToFrontend False thread) channel.threads
        }
            |> Just

    else
        Nothing


dmChannelsToFrontend :
    SeqDict (Slack.Id Slack.UserId) a
    -> SeqDict (Slack.Id Slack.DmChannelId) SlackDmChannel
    -> SeqDict (Slack.Id Slack.DmChannelId) SlackFrontendDmChannel
dmChannelsToFrontend linked dmChannels =
    SeqDict.filterMap
        (\_ dmChannel ->
            if List.any (\slackUserId -> NonemptySet.member slackUserId dmChannel.members) (SeqDict.keys linked) then
                { teamId = dmChannel.teamId
                , members = dmChannel.members
                , messages = DmChannel.loadThreadStarters dmChannel.threads dmChannel.messages (Thread.loadMessages False dmChannel.messages)
                , visibleMessages = VisibleMessages.init False (IdArray.length dmChannel.messages)
                , threads = SeqDict.map (\_ thread -> Thread.slackToFrontend False thread) dmChannel.threads
                }
                    |> Just

            else
                Nothing
        )
        dmChannels


{-| Everyone in the workspaces the at-chat user has linked a Slack account in.
-}
usersToFrontend :
    NonemptyDict (Id UserId) BackendUser
    -> SeqDict (Slack.Id Slack.UserId) (Slack.Id Slack.TeamId)
    -> SeqDict (Slack.Id Slack.UserId) SlackUserData
    -> SeqDict (Slack.Id Slack.UserId) SlackFrontendUser
usersToFrontend users linked slackUsers =
    let
        teams : List (Slack.Id Slack.TeamId)
        teams =
            SeqDict.values linked
    in
    SeqDict.filterMap
        (\_ userData ->
            case userData of
                SlackBasicData { user, icon } ->
                    if List.member user.teamId teams then
                        Just (basicUserToFrontend user icon)

                    else
                        Nothing

                SlackFullData linkedUser ->
                    if List.member linkedUser.user.teamId teams then
                        { name = userName linkedUser.user
                        , icon = linkedUser.icon
                        , color =
                            case NonemptyDict.get linkedUser.linkedTo users of
                                Just user ->
                                    user.color

                                Nothing ->
                                    RichText.defaultColor
                        }
                            |> Just

                    else
                        Nothing
        )
        slackUsers


basicUserToFrontend : Slack.User -> Maybe FileHash -> SlackFrontendUser
basicUserToFrontend user icon =
    { name = userName user, icon = icon, color = RichText.defaultColor }


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


userDataName : SlackUserData -> String
userDataName userData =
    case userData of
        SlackFullData linkedUser ->
            userName linkedUser.user |> PersonName.toString

        SlackBasicData { user } ->
            userName user |> PersonName.toString


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
