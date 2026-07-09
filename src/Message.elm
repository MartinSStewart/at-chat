module Message exposing
    ( ChangeAttachments(..)
    , GameType(..)
    , Message(..)
    , MessageNoReply(..)
    , MessageState(..)
    , MessageStateNoReply(..)
    , UserTextMessageData
    , UserTextMessageDataNoReply
    , addEmbed
    , addReactionEmoji
    , createdAt
    , drawing
    , editUserTextMessage
    , handleDrawingChange
    , reactionEmojis
    , removeReactionEmoji
    , userJoined
    , userTextMessageBackend
    , userTextMessageFrontend
    , userTextMessageNoEmbeds
    )

import Array exposing (Array)
import Drawing exposing (Drawing)
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
import SeqDictHelper
import SeqSet
import Sticker exposing (StickerData)
import Time
import Url exposing (Url)


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict EmojiOrCustomEmoji (NonemptySet userId)) (Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    , timestampDrawings : Drawing userId
    , cardDrawings : Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Drawing userId
    , cardDrawings : Drawing userId
    }


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


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
    , timestampDrawings = Drawing.emptyDrawing
    , userIconDrawings = Drawing.emptyDrawing
    , imageAttachmentDrawings = SeqDict.empty
    , embedDrawings = SeqDict.empty
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
    ->
        ( UserTextMessageData messageId userId
        , Command BackendOnly toMsg ( Url, Result Http.Error EmbedData )
        , SeqDict (Id StickerId) StickerData
        )
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
      , timestampDrawings = Drawing.emptyDrawing
      , userIconDrawings = Drawing.emptyDrawing
      , imageAttachmentDrawings = SeqDict.empty
      , embedDrawings = SeqDict.empty
      }
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
    , timestampDrawings = Drawing.emptyDrawing
    , userIconDrawings = Drawing.emptyDrawing
    , imageAttachmentDrawings = SeqDict.empty
    , embedDrawings = SeqDict.empty
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

        UserJoinedMessage _ _ _ _ ->
            message

        DeletedMessage _ ->
            message

        CallStarted _ ->
            message

        GameStarted _ ->
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
    , timestampDrawings : Drawing userId
    , userIconDrawings : Drawing userId
    , imageAttachmentDrawings : SeqDict (Id FileId) (Drawing userId)
    , -- Keyed by the index of the embed the drawing is attached to
      embedDrawings : SeqDict Int (Drawing userId)
    }


type MessageStateNoReply userId
    = MessageLoaded_NoReply (MessageNoReply userId)
    | MessageUnloaded_NoReply


type MessageNoReply userId
    = UserTextMessage_NoReply (UserTextMessageDataNoReply userId)
    | UserJoinedMessage_NoReply Time.Posix userId (SeqDict EmojiOrCustomEmoji (NonemptySet userId))
    | DeletedMessage_NoReply Time.Posix
    | CallStarted_NoReply Time.Posix userId (SeqDict EmojiOrCustomEmoji (NonemptySet userId))
    | GoMatchStarted_NoReply Time.Posix (SeqDict EmojiOrCustomEmoji (NonemptySet userId))


type alias UserTextMessageDataNoReply userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Nonempty (RichText userId)
    , reactions : SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , attachedFiles : SeqDict (Id FileId) FileData
    }


userJoined : Time.Posix -> userId -> Message messageId userId
userJoined time userId =
    UserJoinedMessage time userId SeqDict.empty Drawing.emptyDrawing


handleDrawingChange : userId -> Drawing.MessageAnchor -> Drawing.LocalChange -> Message messageId userId -> Message messageId userId
handleDrawingChange changeBy anchorType change message =
    case message of
        UserTextMessage data ->
            case anchorType of
                Drawing.UserIconAnchor ->
                    UserTextMessage { data | userIconDrawings = Drawing.handleLocalChange changeBy change data.userIconDrawings }

                Drawing.TimestampAnchor ->
                    UserTextMessage { data | timestampDrawings = Drawing.handleLocalChange changeBy change data.timestampDrawings }

                Drawing.ImageAttachmentAnchor fileId ->
                    UserTextMessage
                        { data
                            | imageAttachmentDrawings =
                                SeqDict.update
                                    fileId
                                    (\maybe ->
                                        Maybe.withDefault Drawing.emptyDrawing maybe
                                            |> Drawing.handleLocalChange changeBy change
                                            |> Just
                                    )
                                    data.imageAttachmentDrawings
                        }

                Drawing.EmbedImageAnchor embedIndex ->
                    UserTextMessage
                        { data
                            | embedDrawings =
                                SeqDict.update
                                    embedIndex
                                    (\maybe ->
                                        Maybe.withDefault Drawing.emptyDrawing maybe
                                            |> Drawing.handleLocalChange changeBy change
                                            |> Just
                                    )
                                    data.embedDrawings
                        }

                Drawing.CardAnchor ->
                    message

        UserJoinedMessage time userId reactions drawings ->
            UserJoinedMessage time userId reactions drawings

        DeletedMessage _ ->
            message

        CallStarted callStarted ->
            case anchorType of
                Drawing.TimestampAnchor ->
                    CallStarted
                        { callStarted
                            | timestampDrawings =
                                Drawing.handleLocalChange changeBy change callStarted.timestampDrawings
                        }

                Drawing.UserIconAnchor ->
                    message

                Drawing.ImageAttachmentAnchor id ->
                    message

                Drawing.EmbedImageAnchor int ->
                    message

                Drawing.CardAnchor ->
                    CallStarted
                        { callStarted
                            | cardDrawings =
                                Drawing.handleLocalChange changeBy change callStarted.cardDrawings
                        }

        GameStarted gameStarted ->
            case anchorType of
                Drawing.TimestampAnchor ->
                    GameStarted
                        { gameStarted
                            | timestampDrawings =
                                Drawing.handleLocalChange changeBy change gameStarted.timestampDrawings
                        }

                Drawing.UserIconAnchor ->
                    message

                Drawing.ImageAttachmentAnchor id ->
                    message

                Drawing.EmbedImageAnchor int ->
                    message

                Drawing.CardAnchor ->
                    GameStarted
                        { gameStarted
                            | cardDrawings =
                                Drawing.handleLocalChange changeBy change gameStarted.cardDrawings
                        }


drawing : Drawing.MessageAnchor -> Message messageId userId -> Drawing userId
drawing anchor message =
    case message of
        UserTextMessage data ->
            case anchor of
                Drawing.UserIconAnchor ->
                    data.userIconDrawings

                Drawing.TimestampAnchor ->
                    data.timestampDrawings

                Drawing.ImageAttachmentAnchor fileId ->
                    SeqDict.get fileId data.imageAttachmentDrawings |> Maybe.withDefault Drawing.emptyDrawing

                Drawing.EmbedImageAnchor embedIndex ->
                    SeqDict.get embedIndex data.embedDrawings |> Maybe.withDefault Drawing.emptyDrawing

                Drawing.CardAnchor ->
                    Drawing.emptyDrawing

        UserJoinedMessage _ _ _ drawings ->
            drawings

        DeletedMessage _ ->
            Drawing.emptyDrawing

        CallStarted callStarted ->
            case anchor of
                Drawing.UserIconAnchor ->
                    Drawing.emptyDrawing

                Drawing.TimestampAnchor ->
                    callStarted.timestampDrawings

                Drawing.ImageAttachmentAnchor id ->
                    Drawing.emptyDrawing

                Drawing.EmbedImageAnchor int ->
                    Drawing.emptyDrawing

                Drawing.CardAnchor ->
                    callStarted.cardDrawings

        GameStarted gameStarted ->
            case anchor of
                Drawing.UserIconAnchor ->
                    Drawing.emptyDrawing

                Drawing.TimestampAnchor ->
                    gameStarted.timestampDrawings

                Drawing.ImageAttachmentAnchor id ->
                    Drawing.emptyDrawing

                Drawing.EmbedImageAnchor int ->
                    Drawing.emptyDrawing

                Drawing.CardAnchor ->
                    gameStarted.cardDrawings


createdAt : Message messageId userId -> Time.Posix
createdAt message =
    case message of
        UserTextMessage data ->
            data.createdAt

        UserJoinedMessage time _ _ _ ->
            time

        DeletedMessage time ->
            time

        CallStarted callStarted ->
            callStarted.startedAt

        GameStarted gameStarted ->
            gameStarted.startedAt


addReactionEmoji : userId -> EmojiOrCustomEmoji -> Message messageId userId -> Message messageId userId
addReactionEmoji userId emoji message =
    case message of
        UserTextMessage message2 ->
            { message2 | reactions = addReactionEmojiHelper userId emoji message2.reactions } |> UserTextMessage

        UserJoinedMessage time userJoinedId reactions drawings ->
            UserJoinedMessage time userJoinedId (addReactionEmojiHelper userId emoji reactions) drawings

        DeletedMessage _ ->
            message

        CallStarted callStarted ->
            CallStarted { callStarted | reactions = addReactionEmojiHelper userId emoji callStarted.reactions }

        GameStarted gameStarted ->
            GameStarted { gameStarted | reactions = addReactionEmojiHelper userId emoji gameStarted.reactions }


addReactionEmojiHelper : userId -> EmojiOrCustomEmoji -> SeqDict EmojiOrCustomEmoji (NonemptySet userId) -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
addReactionEmojiHelper userId emoji reactions =
    SeqDictHelper.addToSet emoji userId reactions


removeReactionEmoji : userId -> EmojiOrCustomEmoji -> Message messageId userId -> Message messageId userId
removeReactionEmoji userId emoji message =
    case message of
        UserTextMessage message2 ->
            { message2 | reactions = removeReactionEmojiHelper userId emoji message2.reactions } |> UserTextMessage

        UserJoinedMessage time userJoinedId reactions drawings ->
            UserJoinedMessage time userJoinedId (removeReactionEmojiHelper userId emoji reactions) drawings

        DeletedMessage _ ->
            message

        CallStarted callStarted ->
            CallStarted { callStarted | reactions = removeReactionEmojiHelper userId emoji callStarted.reactions }

        GameStarted gameStarted ->
            GameStarted { gameStarted | reactions = removeReactionEmojiHelper userId emoji gameStarted.reactions }


removeReactionEmojiHelper : userId -> EmojiOrCustomEmoji -> SeqDict EmojiOrCustomEmoji (NonemptySet userId) -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
removeReactionEmojiHelper userId emoji reactions =
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
        reactions


reactionEmojis : Message messageId userId -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
reactionEmojis message =
    case message of
        UserTextMessage data ->
            data.reactions

        UserJoinedMessage _ _ reactions _ ->
            reactions

        DeletedMessage _ ->
            SeqDict.empty

        CallStarted callStarted ->
            callStarted.reactions

        GameStarted gameStarted ->
            gameStarted.reactions
