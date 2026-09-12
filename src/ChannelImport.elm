module ChannelImport exposing (Error(..), ImportedChannel, decode)

{-| Reads a channel export back into the channel it was written from.

A Discord DM is attributed to Discord accounts, so each of its messages is moved over to
the at-chat account that Discord account is linked to. A Discord guild channel can't come
across yet: its threads point back at Discord message ids, which is a harder question than
swapping out who wrote what.

Encrypted messages can't come back either. Their keys never left the devices of the people
in that conversation, so each one is imported as a deleted message and counted, and the
count is reported to whoever did the importing.

-}

import ChannelDescription exposing (ChannelDescription)
import ChannelExport exposing (ChannelExport(..))
import ChannelName exposing (ChannelName)
import Codec
import Date exposing (Date)
import Discord
import DiscordUserData exposing (DiscordUserData(..))
import Drawing exposing (Drawing)
import Effect.Time as Time
import Emoji exposing (EmojiOrCustomEmoji)
import Game
import Id exposing (ChannelMessageId, Id, UserId)
import IdArray exposing (IdArray)
import Message exposing (Message(..), MessageContent, UserTextMessageDrawings)
import NonemptySet exposing (NonemptySet)
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
                    stripEncryptedInThreads channel.threads
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
                    stripEncryptedInThreads channel.threads
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
                linkedUserId : Discord.Id Discord.UserId -> Id UserId
                linkedUserId discordUserId =
                    case SeqDict.get discordUserId model.discordUsers of
                        Just (FullData data) ->
                            data.linkedTo

                        Just (NeedsAuthAgain data) ->
                            data.linkedTo

                        Just (BasicData _) ->
                            dummyUserId

                        Nothing ->
                            dummyUserId

                ( messages, messagesEncrypted ) =
                    stripEncrypted linkedUserId channel.messages
            in
            { createdAt = Nothing
            , createdBy = Nothing
            , name = Nothing
            , description = Nothing
            , messages = messages
            , threads = SeqDict.empty
            , dateDividerDrawings =
                SeqDict.map (\_ drawing -> mapDrawing linkedUserId drawing) channel.dateDividerDrawings
            , games = SeqDict.empty
            , encryptedMessages = messagesEncrypted
            }
                |> Ok

        Err error ->
            Err (NotAChannelExport error)


{-| Stands in for a Discord account that isn't linked to an at-chat one, since a message
still has to say who wrote it.
-}
dummyUserId : Id UserId
dummyUserId =
    Id.fromInt -1


{-| Threads only ever arrive from at-chat's own channels, which are already written in terms
of at-chat users, so nothing needs moving over here.
-}
stripEncryptedInThreads :
    SeqDict (Id ChannelMessageId) BackendThread
    -> ( SeqDict (Id ChannelMessageId) BackendThread, Int )
stripEncryptedInThreads threads =
    SeqDict.foldl
        (\threadId thread ( result, count ) ->
            let
                ( messages, encrypted ) =
                    stripEncrypted identity thread.messages
            in
            ( SeqDict.insert threadId { thread | messages = messages } result, count + encrypted )
        )
        ( SeqDict.empty, 0 )
        threads


{-| A message nobody here holds the key to is left as the hole it leaves behind, dated the
same as the message that used to be there.
-}
stripEncrypted :
    (userIdA -> Id UserId)
    -> IdArray messageId (Message messageId userIdA)
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
                            ( UserTextMessage
                                { createdAt = data.createdAt
                                , createdBy = mapUserId data.createdBy
                                , content = mapContent mapUserId data.content
                                , reactions = mapReactions mapUserId data.reactions
                                , editedAt = data.editedAt
                                , repliedTo = data.repliedTo
                                , drawings = Maybe.map (mapMessageDrawings mapUserId) data.drawings
                                }
                                :: list
                            , encrypted
                            )

                        UserJoinedMessage createdAt userId reactions drawings ->
                            ( UserJoinedMessage
                                createdAt
                                (mapUserId userId)
                                (mapReactions mapUserId reactions)
                                (mapDrawing mapUserId drawings)
                                :: list
                            , encrypted
                            )

                        DeletedMessage createdAt ->
                            ( DeletedMessage createdAt :: list, encrypted )

                        CallStarted data ->
                            ( CallStarted
                                { startedAt = data.startedAt
                                , endedAt = data.endedAt
                                , startedBy = mapUserId data.startedBy
                                , reactions = mapReactions mapUserId data.reactions
                                , timestampDrawings = mapDrawing mapUserId data.timestampDrawings
                                , cardDrawings = mapDrawing mapUserId data.cardDrawings
                                }
                                :: list
                            , encrypted
                            )

                        GameStarted data ->
                            ( GameStarted
                                { startedAt = data.startedAt
                                , startedBy = mapUserId data.startedBy
                                , reactions = mapReactions mapUserId data.reactions
                                , gameType = data.gameType
                                , timestampDrawings = mapDrawing mapUserId data.timestampDrawings
                                , cardDrawings = mapDrawing mapUserId data.cardDrawings
                                }
                                :: list
                            , encrypted
                            )
                )
                ( [], 0 )
                messages
    in
    ( IdArray.fromList (List.reverse reversed), count )


mapContent : (userIdA -> userIdB) -> MessageContent userIdA -> MessageContent userIdB
mapContent mapUserId content =
    { content = RichText.mapUserId mapUserId content.content
    , embeds = content.embeds
    , attachedFiles = content.attachedFiles
    }


mapReactions :
    (userIdA -> userIdB)
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userIdA)
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userIdB)
mapReactions mapUserId reactions =
    SeqDict.map (\_ users -> NonemptySet.map mapUserId users) reactions


mapMessageDrawings :
    (userIdA -> userIdB)
    -> UserTextMessageDrawings userIdA
    -> UserTextMessageDrawings userIdB
mapMessageDrawings mapUserId drawings =
    { timestampDrawings = mapDrawing mapUserId drawings.timestampDrawings
    , userIconDrawings = mapDrawing mapUserId drawings.userIconDrawings
    , imageAttachmentDrawings =
        SeqDict.map (\_ drawing -> mapDrawing mapUserId drawing) drawings.imageAttachmentDrawings
    , embedDrawings = SeqDict.map (\_ drawing -> mapDrawing mapUserId drawing) drawings.embedDrawings
    }


mapDrawing : (userIdA -> userIdB) -> Drawing userIdA -> Drawing userIdB
mapDrawing mapUserId drawing =
    { finished =
        List.map
            (\stroke -> { createdBy = mapUserId stroke.createdBy, points = stroke.points })
            drawing.finished
    , inProgress =
        SeqDict.toList drawing.inProgress
            |> List.map (\( userId, stroke ) -> ( mapUserId userId, stroke ))
            |> SeqDict.fromList
    , undone =
        SeqDict.toList drawing.undone
            |> List.map (\( userId, strokes ) -> ( mapUserId userId, strokes ))
            |> SeqDict.fromList
    }
