module Message exposing
    ( ChangeAttachments(..)
    , Message(..)
    , MessageNoReply(..)
    , MessageState(..)
    , MessageStateNoReply(..)
    , UserTextMessageData
    , UserTextMessageDataNoReply
    , addEmbed
    , addReactionEmoji
    , createdAt
    , editUserTextMessage
    , reactionEmojis
    , removeReactionEmoji
    , userTextMessageBackend
    , userTextMessageFrontend
    , userTextMessageNoEmbeds
    )

import Array exposing (Array)
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Embed exposing (Embed(..), EmbedData)
import Emoji exposing (EmojiOrCustomEmoji)
import FileStatus exposing (FileData, FileId)
import Id exposing (Id, StickerId)
import List.Nonempty exposing (Nonempty)
import NonemptySet exposing (NonemptySet)
import RichText exposing (RichText)
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import SeqSet
import Sticker exposing (StickerData)
import Time
import Url exposing (Url)


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict EmojiOrCustomEmoji (NonemptySet userId))
    | DeletedMessage Time.Posix


maxEmbeds : number
maxEmbeds =
    10


userTextMessageNoEmbeds :
    Time.Posix
    -> userId
    -> Nonempty (RichText userId)
    -> Maybe (Id messageId)
    -> SeqDict (Id FileId) FileData
    -> Message messageId userId
userTextMessageNoEmbeds createdAt2 createdBy content repliedTo attachedFiles =
    { createdAt = createdAt2
    , createdBy = createdBy
    , content = content
    , reactions = SeqDict.empty
    , editedAt = Nothing
    , repliedTo = repliedTo
    , attachedFiles = attachedFiles
    , embeds = Array.empty
    }
        |> UserTextMessage


userTextMessageBackend :
    SecretId ServerSecret
    -> Time.Posix
    -> userId
    -> Nonempty (RichText userId)
    -> Maybe (Id messageId)
    -> SeqDict (Id FileId) FileData
    -> SeqDict (Id StickerId) StickerData
    -> ( Message messageId userId, Command BackendOnly toMsg ( Url, Result Http.Error EmbedData ), SeqDict (Id StickerId) StickerData )
userTextMessageBackend secretKey createdAt2 createdBy content repliedTo attachedFiles allStickers =
    let
        hyperlinks : List Url
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
    , SeqSet.fromList hyperlinks |> SeqSet.toList |> List.map (Embed.request secretKey) |> Command.batch
    , List.foldl
        (\stickerId dict ->
            SeqDict.update
                stickerId
                (\maybe ->
                    case maybe of
                        Just _ ->
                            maybe

                        Nothing ->
                            SeqDict.get stickerId allStickers
                )
                dict
        )
        SeqDict.empty
        (RichText.stickers content)
    )


userTextMessageFrontend :
    Time.Posix
    -> userId
    -> Nonempty (RichText userId)
    -> Maybe (Id messageId)
    -> SeqDict (Id FileId) FileData
    -> Message messageId userId
userTextMessageFrontend createdAt2 createdBy content repliedTo attachedFiles =
    let
        hyperlinks : List Url
        hyperlinks =
            RichText.hyperlinks content |> List.take maxEmbeds
    in
    { createdAt = createdAt2
    , createdBy = createdBy
    , content = content
    , reactions = SeqDict.empty
    , editedAt = Nothing
    , repliedTo = repliedTo
    , attachedFiles = attachedFiles
    , embeds = Array.initialize (List.length hyperlinks) (\_ -> EmbedLoading)
    }
        |> UserTextMessage


type ChangeAttachments
    = ChangeAttachments (SeqDict (Id FileId) FileData)
    | DoNotChangeAttachments


editUserTextMessage :
    Time.Posix
    -> Nonempty (RichText userId)
    -> ChangeAttachments
    -> UserTextMessageData messageId userId
    -> UserTextMessageData messageId userId
editUserTextMessage time newContent attachedFiles data =
    let
        oldUrls : SeqDict Url EmbedData
        oldUrls =
            List.indexedMap
                (\index link ->
                    case Array.get index data.embeds of
                        Just (EmbedLoaded embed) ->
                            ( link, embed )

                        Just EmbedLoading ->
                            ( link, Embed.empty )

                        Nothing ->
                            ( link, Embed.empty )
                )
                (RichText.hyperlinks data.content)
                |> SeqDict.fromList
    in
    { data
        | editedAt = Just time
        , content = newContent
        , attachedFiles =
            case attachedFiles of
                ChangeAttachments attachedFiles2 ->
                    attachedFiles2

                DoNotChangeAttachments ->
                    data.attachedFiles
        , embeds =
            RichText.hyperlinks newContent
                |> List.map
                    (\url ->
                        SeqDict.get url oldUrls
                            |> Maybe.withDefault Embed.empty
                            |> EmbedLoaded
                    )
                |> Array.fromList
    }


addEmbed : ( Url, Result e EmbedData ) -> Message messageId userId -> Message messageId userId
addEmbed ( url, result ) message =
    case message of
        UserTextMessage message2 ->
            UserTextMessage
                { message2
                    | embeds =
                        RichText.hyperlinks message2.content
                            |> List.indexedMap Tuple.pair
                            |> List.foldl
                                (\( index, hyperlink ) array ->
                                    if hyperlink == url then
                                        Array.set
                                            index
                                            (case result of
                                                Ok embed ->
                                                    EmbedLoaded embed

                                                Err _ ->
                                                    EmbedLoaded Embed.empty
                                            )
                                            array

                                    else
                                        array
                                )
                                message2.embeds
                }

        UserJoinedMessage _ _ _ ->
            message

        DeletedMessage _ ->
            message


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Nonempty (RichText userId)
    , reactions : SeqDict EmojiOrCustomEmoji (NonemptySet userId)
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
    | UserJoinedMessage_NoReply Time.Posix userId (SeqDict EmojiOrCustomEmoji (NonemptySet userId))
    | DeletedMessage_NoReply Time.Posix


type alias UserTextMessageDataNoReply userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Nonempty (RichText userId)
    , reactions : SeqDict EmojiOrCustomEmoji (NonemptySet userId)
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


addReactionEmoji : userId -> EmojiOrCustomEmoji -> Message messageId userId -> Message messageId userId
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


removeReactionEmoji : userId -> EmojiOrCustomEmoji -> Message messageId userId -> Message messageId userId
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


reactionEmojis : Message messageId userId -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
reactionEmojis message =
    case message of
        UserTextMessage data ->
            data.reactions

        UserJoinedMessage _ _ reactions ->
            reactions

        DeletedMessage _ ->
            SeqDict.empty
