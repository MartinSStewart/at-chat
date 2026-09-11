module ChannelImport exposing (Error(..), ImportedChannel, decode)

{-| Reads a channel export back into the channel it was written from. Only at-chat's own
channels can be imported. A Discord channel is exported as the Discord data it is, which
means its messages are attributed to Discord accounts and its threads point back at
Discord message ids, so there's nothing sensible to do with one here yet.

Encrypted messages can't come back either. Their keys never left the devices of the people
in that conversation, so each one is imported as a deleted message and counted, and the
count is reported to whoever did the importing.

-}

import ChannelDescription exposing (ChannelDescription)
import ChannelExport exposing (ChannelExport(..))
import ChannelName exposing (ChannelName)
import Codec
import Date exposing (Date)
import Drawing exposing (Drawing)
import Effect.Time as Time
import Game
import Id exposing (ChannelMessageId, Id, UserId)
import IdArray exposing (IdArray)
import Message exposing (Message(..))
import SeqDict exposing (SeqDict)
import Thread exposing (BackendThread)


type Error
    = NotAChannelExport Codec.Error
    | DiscordChannelsCantBeImported


{-| The name and the two `createdAt`/`createdBy` fields are missing for a DM export, which
carries no channel of its own for them to describe.
-}
type alias ImportedChannel =
    { createdAt : Maybe Time.Posix
    , createdBy : Maybe (Id UserId)
    , name : Maybe ChannelName
    , description : Maybe ChannelDescription
    , messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId))
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    , games : SeqDict (Id ChannelMessageId) Game.BackendGameData
    , encryptedMessages : Int
    }


decode : String -> Result Error ImportedChannel
decode text =
    case ChannelExport.decode text of
        Ok (GuildChannelExport channel) ->
            let
                ( messages, messagesEncrypted ) =
                    stripEncrypted channel.messages

                ( threads, threadsEncrypted ) =
                    stripEncryptedInThreads channel.threads
            in
            Ok
                { createdAt = Just channel.createdAt
                , createdBy = Just channel.createdBy
                , name = Just channel.name
                , description = Just channel.description
                , messages = messages
                , threads = threads
                , dateDividerDrawings = channel.dateDividerDrawings
                , games = channel.games
                , encryptedMessages = messagesEncrypted + threadsEncrypted
                }

        Ok (DmChannelExport channel) ->
            let
                ( messages, messagesEncrypted ) =
                    stripEncrypted channel.messages

                ( threads, threadsEncrypted ) =
                    stripEncryptedInThreads channel.threads
            in
            Ok
                { createdAt = Nothing
                , createdBy = Nothing
                , name = Nothing
                , description = Nothing
                , messages = messages
                , threads = threads
                , dateDividerDrawings = channel.dateDividerDrawings
                , games = channel.games
                , encryptedMessages = messagesEncrypted + threadsEncrypted
                }

        Ok (DiscordGuildChannelExport _) ->
            Err DiscordChannelsCantBeImported

        Ok (DiscordDmChannelExport _) ->
            Err DiscordChannelsCantBeImported

        Err error ->
            Err (NotAChannelExport error)


stripEncryptedInThreads :
    SeqDict (Id ChannelMessageId) BackendThread
    -> ( SeqDict (Id ChannelMessageId) BackendThread, Int )
stripEncryptedInThreads threads =
    SeqDict.foldl
        (\threadId thread ( result, count ) ->
            let
                ( messages, encrypted ) =
                    stripEncrypted thread.messages
            in
            ( SeqDict.insert threadId { thread | messages = messages } result, count + encrypted )
        )
        ( SeqDict.empty, 0 )
        threads


{-| A message nobody here holds the key to is left as the hole it leaves behind, dated the
same as the message that used to be there.
-}
stripEncrypted :
    IdArray messageId (Message messageId (Id UserId))
    -> ( IdArray messageId (Message messageId (Id UserId)), Int )
stripEncrypted messages =
    let
        ( reversed, count ) =
            IdArray.foldl
                (\message ( list, encrypted ) ->
                    case message of
                        EncryptedUserTextMessage data ->
                            ( DeletedMessage data.createdAt :: list, encrypted + 1 )

                        _ ->
                            ( message :: list, encrypted )
                )
                ( [], 0 )
                messages
    in
    ( IdArray.fromList (List.reverse reversed), count )
