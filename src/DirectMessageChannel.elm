module DirectMessageChannel exposing
    ( DirectMessageChannel
    , DirectMessageChannelId
    , LastTypedAt
    , addMessage
    , channelIdFromUserIds
    , includesUserId
    , init
    )

import Array exposing (Array)
import Discord.Id
import Id exposing (Id(..), UserId)
import List.Nonempty exposing (Nonempty)
import Message exposing (Message(..))
import OneToOne exposing (OneToOne)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import Time


type alias DirectMessageChannel =
    { messages : Array Message
    , lastTypedAt : SeqDict (Id UserId) LastTypedAt
    , linkedMessageIds : OneToOne (Discord.Id.Id Discord.Id.MessageId) Int
    }


type DirectMessageChannelId
    = DirectMessageChannelId (Id UserId) (Id UserId)


type alias LastTypedAt =
    { time : Time.Posix, messageIndex : Maybe Int }


init : DirectMessageChannel
init =
    { messages = Array.empty
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    }


channelIdFromUserIds : Id UserId -> Id UserId -> DirectMessageChannelId
channelIdFromUserIds (Id userIdA) (Id userIdB) =
    DirectMessageChannelId (min userIdA userIdB |> Id) (max userIdA userIdB |> Id)


includesUserId : Id UserId -> DirectMessageChannelId -> Bool
includesUserId userId (DirectMessageChannelId userIdA userIdB) =
    userId == userIdA || userId == userIdB


addMessage :
    Time.Posix
    -> Maybe (Discord.Id.Id Discord.Id.MessageId)
    -> Id UserId
    -> Id UserId
    -> Nonempty RichText
    -> SeqDict DirectMessageChannelId DirectMessageChannel
    -> SeqDict DirectMessageChannelId DirectMessageChannel
addMessage time maybeDiscordId sender receiver richText directMessages =
    SeqDict.update
        (channelIdFromUserIds sender receiver)
        (\maybe ->
            let
                a =
                    Maybe.withDefault init maybe
            in
            { a
                | messages =
                    Array.push
                        (UserTextMessage
                            { createdAt = time
                            , createdBy = sender
                            , content = richText
                            , reactions = SeqDict.empty
                            , editedAt = Nothing
                            , repliedTo = Nothing
                            }
                        )
                        a.messages
                , linkedMessageIds =
                    case maybeDiscordId of
                        Just discordId ->
                            OneToOne.insert discordId (Array.length a.messages - 1) a.linkedMessageIds

                        Nothing ->
                            a.linkedMessageIds
            }
                |> Just
        )
        directMessages
