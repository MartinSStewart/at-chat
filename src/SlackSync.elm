module SlackSync exposing
    ( conversationFromHistory
    , dmChannelsToFrontend
    , linkedUsers
    , newChannelMaxMessages
    , toMessage
    , userDataName
    , usersToFrontend
    , workspacesToFrontend
    )

import Drawing
import Id exposing (ChannelMessageId, Id, UserId)
import IdArray exposing (IdArray)
import LocalState exposing (SlackFrontendChannel, SlackFrontendDmChannel, SlackFrontendWorkspace)
import Message exposing (Message(..), RepliedTo(..))
import NonemptyDict exposing (NonemptyDict)
import NonemptySet
import OneToOne exposing (OneToOne)
import PersonName exposing (PersonName)
import RichText
import SeqDict exposing (SeqDict)
import SeqSet
import Slack
import Thread exposing (SlackBackendThread)
import Types exposing (SlackBackendChannel, SlackBackendWorkspace, SlackDmChannel, SlackUserData(..))
import User exposing (BackendUser)
import UserSession exposing (SlackFrontendUser)
import VisibleMessages


newChannelMaxMessages : Int
newChannelMaxMessages =
    50


{-| Takes messages oldest first. Messages with nothing at-chat can show (only files for now) are
left out.
-}
messagesAndLinks :
    List Slack.Message
    ->
        ( IdArray messageId (Message messageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
        , OneToOne (Slack.Id Slack.MessageId) (Id messageId)
        )
messagesAndLinks messages =
    let
        converted : List ( Slack.Id Slack.MessageId, Message messageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId) )
        converted =
            List.filterMap
                (\message -> toMessage message |> Maybe.map (Tuple.pair message.id))
                messages
    in
    ( IdArray.fromList (List.map Tuple.second converted)
    , List.indexedMap (\index ( slackId, _ ) -> ( slackId, Id.fromInt index )) converted |> OneToOne.fromList
    )


{-| A conversation built from its history, newest first as Slack gives it.
-}
conversationFromHistory :
    Slack.History
    ->
        { messages : IdArray ChannelMessageId (Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
        , linkedMessageIds : OneToOne (Slack.Id Slack.MessageId) (Id ChannelMessageId)
        , threads : SeqDict (Id ChannelMessageId) SlackBackendThread
        }
conversationFromHistory history =
    let
        ( messages, linkedMessageIds ) =
            messagesAndLinks (List.reverse history.messages)
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
                                messagesAndLinks replies
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


toMessage : Slack.Message -> Maybe (Message messageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
toMessage message =
    case message.content of
        Slack.TextMessage { text, blocks } ->
            RichText.fromSlack text blocks
                |> Maybe.map
                    (\content ->
                        Message.userTextMessageNoEmbeds
                            message.createdAt
                            message.user
                            content
                            SeqDict.empty
                            NoReply
                            SeqDict.empty
                            |> UserTextMessage
                    )

        Slack.JoinedChannel ->
            UserJoinedMessage message.createdAt message.user SeqDict.empty Drawing.emptyDrawing |> Just


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
        , messages = Thread.loadMessages False channel.messages
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
                , messages = Thread.loadMessages False dmChannel.messages
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
                SlackBasicData user ->
                    if List.member user.teamId teams then
                        Just { name = userName user, icon = Nothing, color = RichText.defaultColor }

                    else
                        Nothing

                SlackFullData linkedUser ->
                    if List.member linkedUser.user.teamId teams then
                        { name = userName linkedUser.user
                        , icon = Nothing
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

        SlackBasicData user ->
            userName user |> PersonName.toString
