module Message exposing
    ( Message(..)
    , MessageNoReply(..)
    , MessageState(..)
    , MessageStateNoReply(..)
    , UserTextMessageData
    , UserTextMessageDataNoReply
    , addEmbed
    , addReactionEmoji
    , createdAt
    , removeReactionEmoji
    , userTextMessage
    )

import Array exposing (Array)
import Dict
import Effect.Command as Command exposing (Command)
import Effect.Http as Http
import Emoji exposing (Emoji)
import FileStatus exposing (FileData, FileId)
import Id exposing (Id)
import Iso8601
import Json.Decode
import Json.Encode
import List.Nonempty exposing (Nonempty)
import NonemptySet exposing (NonemptySet)
import RichText exposing (Embed(..), EmbedData, RichText)
import SeqDict exposing (SeqDict)
import SeqSet
import Time


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict Emoji (NonemptySet userId))
    | DeletedMessage Time.Posix


maxEmbeds : number
maxEmbeds =
    10


userTextMessage :
    Time.Posix
    -> userId
    -> Nonempty (RichText userId)
    -> Maybe (Id messageId)
    -> SeqDict (Id FileId) FileData
    -> ( Message messageId userId, Command r toMsg ( Int, Result Http.Error EmbedData ) )
userTextMessage createdAt2 createdBy content repliedTo attachedFiles =
    let
        hyperlinks : List String
        hyperlinks =
            RichText.hyperlinks content |> List.take maxEmbeds
    in
    ( { createdAt = createdAt2
      , createdBy = createdBy
      , content = content
      , reactions = SeqDict.empty
      , editedAt = Nothing
      , repliedTo = repliedTo
      , attachedFiles = attachedFiles
      , embeds = Array.initialize (List.length hyperlinks) (\_ -> EmbedLoading)
      }
        |> UserTextMessage
    , List.indexedMap
        (\index hyperlink ->
            Http.post
                { url = FileStatus.domain ++ "/file/embed"
                , body = Json.Encode.object [ ( "url", Json.Encode.string hyperlink ) ] |> Http.jsonBody
                , expect = Http.expectJson (Tuple.pair index) decodeEmbedData
                }
        )
        hyperlinks
        |> Command.batch
    )


addEmbed : ( Int, Result e EmbedData ) -> Message messageId userId -> Message messageId userId
addEmbed ( embedIndex, result ) message =
    case message of
        UserTextMessage message2 ->
            UserTextMessage
                { message2
                    | embeds =
                        Array.set
                            embedIndex
                            (case result of
                                Ok embed ->
                                    EmbedLoaded embed

                                Err _ ->
                                    EmbedFailedToLoad
                            )
                            message2.embeds
                }

        UserJoinedMessage _ _ _ ->
            message

        DeletedMessage _ ->
            message


decodeEmbedData : Json.Decode.Decoder EmbedData
decodeEmbedData =
    Json.Decode.map
        (\dict ->
            { title = Dict.get "og:title" dict
            , image = Dict.get "og:image" dict
            , content = Dict.get "og:description" dict |> Maybe.withDefault ""
            , createdAt =
                case Dict.get "article:published_time" dict of
                    Just time ->
                        Iso8601.toTime time |> Result.toMaybe

                    Nothing ->
                        Nothing
            , favicon = Dict.get "og:logo" dict
            }
        )
        (Json.Decode.dict Json.Decode.string)


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
    , embeds : Array Embed
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
    , createdBy : userId
    , content : Nonempty (RichText userId)
    , reactions : SeqDict Emoji (NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , attachedFiles : SeqDict (Id FileId) FileData
    }


createdAt : Message messageId userId -> Time.Posix
createdAt message =
    case message of
        UserTextMessage data ->
            data.createdAt

        UserJoinedMessage time _ _ ->
            time

        DeletedMessage time ->
            time


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
