module SlackSync exposing (messagesAndLinks, newChannelMaxMessages)

import Drawing
import Id exposing (ChannelMessageId, Id)
import IdArray exposing (IdArray)
import Message exposing (Message(..), RepliedTo(..))
import OneToOne exposing (OneToOne)
import RichText
import SeqDict
import Slack


newChannelMaxMessages : Int
newChannelMaxMessages =
    50


{-| Takes messages oldest first. Messages with nothing at-chat can show (only files for now) are
left out.
-}
messagesAndLinks :
    List Slack.Message
    ->
        ( IdArray ChannelMessageId (Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId))
        , OneToOne (Slack.Id Slack.MessageId) (Id ChannelMessageId)
        )
messagesAndLinks messages =
    let
        converted : List ( Slack.Id Slack.MessageId, Message ChannelMessageId (Slack.Id Slack.UserId) (Slack.Id Slack.ChannelId) )
        converted =
            List.filterMap
                (\message ->
                    case message.content of
                        Slack.TextMessage { text, blocks } ->
                            RichText.fromSlack text blocks
                                |> Maybe.map
                                    (\content ->
                                        ( message.id
                                        , Message.userTextMessageNoEmbeds
                                            message.createdAt
                                            message.user
                                            content
                                            SeqDict.empty
                                            NoReply
                                            SeqDict.empty
                                            |> UserTextMessage
                                        )
                                    )

                        Slack.JoinedChannel ->
                            Just
                                ( message.id
                                , UserJoinedMessage message.createdAt message.user SeqDict.empty Drawing.emptyDrawing
                                )
                )
                messages
    in
    ( IdArray.fromList (List.map Tuple.second converted)
    , List.indexedMap (\index ( slackId, _ ) -> ( slackId, Id.fromInt index )) converted |> OneToOne.fromList
    )
