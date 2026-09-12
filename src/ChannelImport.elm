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
import DiscordUserData exposing (DiscordUserData(..))
import Drawing exposing (Drawing)
import Effect.Time as Time
import Game
import Id exposing (ChannelMessageId, Id, ThreadMessageId, UserId)
import IdArray exposing (IdArray)
import Message exposing (Message(..))
import NonemptySet
import RichText
import SeqDict exposing (SeqDict)
import Thread exposing (BackendThread)
import Types exposing (BackendModel)


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


decode : String -> BackendModel -> Result Error ImportedChannel
decode text model =
    case ChannelExport.decode text of
        Ok (GuildChannelExport channel) ->
            let
                ( messages, messagesEncrypted ) =
                    stripEncrypted identity channel.messages

                ( threads, threadsEncrypted ) =
                    stripEncryptedInThreads identity channel.threads
            in
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
                |> Ok

        Ok (DmChannelExport channel) ->
            let
                ( messages, messagesEncrypted ) =
                    stripEncrypted identity channel.messages

                ( threads, threadsEncrypted ) =
                    stripEncryptedInThreads identity channel.threads
            in
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
                |> Ok

        Ok (DiscordGuildChannelExport _) ->
            Err DiscordChannelsCantBeImported

        Ok (DiscordDmChannelExport channel) ->
            let
                ( messages, messagesEncrypted ) =
                    stripEncrypted
                        (\discordUserId ->
                            case SeqDict.get discordUserId model.discordUsers of
                                Just (FullData data) ->
                                    data.linkedTo

                                Just (NeedsAuthAgain data) ->
                                    data.linkedTo

                                Just (BasicData _) ->
                                    dummyUserId

                                Nothing ->
                                    dummyUserId
                        )
                        channel.messages
            in
            { createdAt = Nothing
            , createdBy = Nothing
            , name = Nothing
            , description = Nothing
            , messages = messages
            , threads = SeqDict.empty
            , dateDividerDrawings = channel.dateDividerDrawings
            , games = channel.games
            , encryptedMessages = messagesEncrypted
            }
                |> Ok

        Err error ->
            Err (NotAChannelExport error)


stripEncryptedInThreads :
    (userIdOld -> Maybe (Id UserId))
    -> SeqDict (Id ChannelMessageId) { a | messages : IdArray ThreadMessageId (Message ThreadMessageId userIdOld) }
    -> ( SeqDict (Id ChannelMessageId) { a | messages : IdArray ThreadMessageId (Message ThreadMessageId (Id UserId)) }, Int )
stripEncryptedInThreads mapUserId threads =
    SeqDict.foldl
        (\threadId thread ( result, count ) ->
            let
                ( messages, encrypted ) =
                    stripEncrypted mapUserId thread.messages
            in
            ( SeqDict.insert threadId { thread | messages = messages } result, count + encrypted )
        )
        ( SeqDict.empty, 0 )
        threads


dummyUserId : Id UserId
dummyUserId =
    Id.fromInt -1


{-| A message nobody here holds the key to is left as the hole it leaves behind, dated the
same as the message that used to be there.
-}
stripEncrypted :
    (userIdOld -> Id UserId)
    -> IdArray messageId (Message messageId userIdOld)
    -> ( IdArray messageId (Message messageId (Id UserId)), Int )
stripEncrypted mapUserId messages =
    let
        ( reversed, count ) =
            IdArray.foldl
                (\message ( list, encrypted ) ->
                    case message of
                        EncryptedUserTextMessage data ->
                            ( DeletedMessage data.createdAt :: list, encrypted + 1 )

                        UserTextMessage data ->
                            let
                                content =
                                    data.content
                            in
                            ( { createdAt = data.createdAt
                              , createdBy = mapUserId data.createdBy
                              , content = { content | content = RichText.mapUserId mapUserId content.content }
                              , reactions = SeqDict.map (\_ a -> NonemptySet.map mapUserId a) data.reactions
                              , editedAt = data.editedAt
                              , repliedTo = mapUserId
                              , drawings = data.drawings
                              }
                                :: list
                            , encrypted
                            )

                        UserJoinedMessage posix userId seqDict drawing ->
                            ( message :: list, encrypted )

                        DeletedMessage posix ->
                            ( message :: list, encrypted )

                        CallStarted callStartedData ->
                            ( message :: list, encrypted )

                        GameStarted gameStartedData ->
                            ( message :: list, encrypted )
                )
                ( [], 0 )
                messages
    in
    ( IdArray.fromList (List.reverse reversed), count )
