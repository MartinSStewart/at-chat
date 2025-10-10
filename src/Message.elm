module Message exposing (Message(..), MessageNoReply(..), MessageState(..), MessageStateNoReply(..), UserTextMessageData, UserTextMessageDataNoReply, addReactionEmoji, removeReactionEmoji)

import Emoji exposing (Emoji)
import FileStatus exposing (FileData, FileId)
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty)
import NonemptySet exposing (NonemptySet)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import SeqSet
import Time


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict Emoji (NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Nonempty (RichText userId)
    , reactions : SeqDict Emoji (NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Id messageId)
    , attachedFiles : SeqDict (Id FileId) FileData
    }


type MessageStateNoReply userId
    = MessageLoaded_NoReply (MessageNoReply userId)
    | MessageUnloaded_NoReply


type MessageNoReply userId
    = UserTextMessage_NoReply (UserTextMessageDataNoReply userId)
    | UserJoinedMessage_NoReply Time.Posix userId (SeqDict Emoji (NonemptySet userId))
    | DeletedMessage_NoReply Time.Posix


type alias UserTextMessageDataNoReply userId =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , content : Nonempty (RichText userId)
    , reactions : SeqDict Emoji (NonemptySet (Id UserId))
    , editedAt : Maybe Time.Posix
    , attachedFiles : SeqDict (Id FileId) FileData
    }


addReactionEmoji : userId -> Emoji -> Message messageId userId -> Message messageId userId
addReactionEmoji userId emoji message =
    case message of
        UserTextMessage message2 ->
            { message2
                | reactions =
                    SeqDict.update
                        emoji
                        (\maybeSet ->
                            (case maybeSet of
                                Just nonempty ->
                                    NonemptySet.insert userId nonempty

                                Nothing ->
                                    NonemptySet.singleton userId
                            )
                                |> Just
                        )
                        message2.reactions
            }
                |> UserTextMessage

        UserJoinedMessage time userJoined reactions ->
            UserJoinedMessage
                time
                userJoined
                (SeqDict.update
                    emoji
                    (\maybeSet ->
                        (case maybeSet of
                            Just nonempty ->
                                NonemptySet.insert userId nonempty

                            Nothing ->
                                NonemptySet.singleton userId
                        )
                            |> Just
                    )
                    reactions
                )

        DeletedMessage _ ->
            message


removeReactionEmoji : userId -> Emoji -> Message messageId userId -> Message messageId userId
removeReactionEmoji userId emoji message =
    case message of
        UserTextMessage message2 ->
            { message2
                | reactions =
                    SeqDict.update
                        emoji
                        (\maybeSet ->
                            case maybeSet of
                                Just nonempty ->
                                    NonemptySet.toSeqSet nonempty
                                        |> SeqSet.remove userId
                                        |> NonemptySet.fromSeqSet

                                Nothing ->
                                    Nothing
                        )
                        message2.reactions
            }
                |> UserTextMessage

        UserJoinedMessage time userJoined reactions ->
            UserJoinedMessage
                time
                userJoined
                (SeqDict.update
                    emoji
                    (\maybeSet ->
                        case maybeSet of
                            Just nonempty ->
                                NonemptySet.toSeqSet nonempty
                                    |> SeqSet.remove userId
                                    |> NonemptySet.fromSeqSet

                            Nothing ->
                                Nothing
                    )
                    reactions
                )

        DeletedMessage _ ->
            message
