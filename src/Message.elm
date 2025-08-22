module Message exposing (Message(..), UserTextMessageData, addReactionEmoji, removeReactionEmoji)

import Emoji exposing (Emoji)
import FileStatus exposing (FileData, FileId)
import Id exposing (Id, MessageId, UserId)
import List.Nonempty exposing (Nonempty)
import NonemptySet exposing (NonemptySet)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import SeqSet
import Time


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Id UserId) (SeqDict Emoji (NonemptySet (Id UserId)))
    | DeletedMessage Time.Posix


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , content : Nonempty RichText
    , reactions : SeqDict Emoji (NonemptySet (Id UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Id MessageId)
    , attachedFiles : SeqDict (Id FileId) FileData
    }


addReactionEmoji : Id UserId -> Emoji -> Message -> Message
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


removeReactionEmoji : Id UserId -> Emoji -> Message -> Message
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
