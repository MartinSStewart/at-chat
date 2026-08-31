module Message exposing
    ( CallStartedData
    , ChangeAttachments(..)
    , ContentAndEmbeds
    , EncryptedUserTextMessageData
    , GameStartedData
    , GameType(..)
    , Message(..)
    , MessageNoReply(..)
    , UserTextMessageData
    , UserTextMessageDataNoReply
    , addEmbed
    , addReactionEmoji
    , contentAndEmbedsCodec
    , createdAt
    , drawing
    , editUserTextMessage
    , encryptedUserTextMessageFrontend
    , handleDrawingChange
    , reactionEmojis
    , removeReactionEmoji
    , toEncrypted
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
import Encryption exposing (EncryptedData)
import FileStatus exposing (FileData, FileId)
import Id exposing (Id, StickerId, UserId)
import List.Nonempty exposing (Nonempty)
import NonemptySet exposing (NonemptySet)
import Quantity
import RichText exposing (RichText)
import SecretId exposing (SecretId, ServerSecret)
import SeqDict exposing (SeqDict)
import SeqDictHelper
import SeqSet
import Serialize
import Sticker exposing (StickerData)
import Time
import Url exposing (Url)


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
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
    | GameType_SheepGame


maxEmbeds : number
maxEmbeds =
    10


userTextMessageNoEmbeds :
    Time.Posix
    -> userId
    -> Nonempty (RichText userId)
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    -> Maybe (Id messageId)
    -> SeqDict (Id FileId) FileData
    -> UserTextMessageData messageId userId
userTextMessageNoEmbeds createdAt2 createdBy content reactions repliedTo attachedFiles =
    { createdAt = createdAt2
    , createdBy = createdBy
    , content = content
    , reactions = reactions
    , editedAt = Nothing
    , repliedTo = repliedTo
    , attachedFiles = attachedFiles
    , embeds = Array.empty
    , timestampDrawings = Drawing.emptyDrawing
    , userIconDrawings = Drawing.emptyDrawing
    , imageAttachmentDrawings = SeqDict.empty
    , embedDrawings = SeqDict.empty
    }


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


{-| An encrypted message, as both people in the conversation hold it. There are no embeds
because working them out means reading the message, which nothing outside the two of them
can do.
-}
encryptedUserTextMessageFrontend :
    Time.Posix
    -> Id UserId
    -> EncryptedData (ContentAndEmbeds (Id UserId))
    -> Maybe (Id messageId)
    -> SeqDict (Id FileId) FileData
    -> Message messageId (Id UserId)
encryptedUserTextMessageFrontend createdAt2 createdBy contentAndEmbeds repliedTo attachedFiles =
    EncryptedUserTextMessage
        { encryptedData = contentAndEmbeds
        , createdAt = createdAt2
        , createdBy = createdBy
        , reactions = SeqDict.empty
        , editedAt = Nothing
        , repliedTo = repliedTo
        , attachedFiles = attachedFiles
        , timestampDrawings = Drawing.emptyDrawing
        , userIconDrawings = Drawing.emptyDrawing
        , imageAttachmentDrawings = SeqDict.empty
        , embedDrawings = SeqDict.empty
        }


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

        EncryptedUserTextMessage _ ->
            message

        UserJoinedMessage _ _ _ _ ->
            message

        DeletedMessage _ ->
            message

        CallStarted _ ->
            message

        GameStarted _ ->
            message


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


toEncrypted : EncryptedData (ContentAndEmbeds userId) -> Message messageId userId -> Message messageId userId
toEncrypted encryptedData message =
    case message of
        UserTextMessage data ->
            EncryptedUserTextMessage
                { encryptedData = encryptedData
                , createdAt = data.createdAt
                , createdBy = data.createdBy
                , reactions = data.reactions
                , editedAt = data.editedAt
                , repliedTo = data.repliedTo
                , attachedFiles = data.attachedFiles
                , timestampDrawings = data.timestampDrawings
                , userIconDrawings = data.userIconDrawings
                , imageAttachmentDrawings = data.imageAttachmentDrawings
                , embedDrawings = data.embedDrawings
                }

        EncryptedUserTextMessage encryptedUserTextMessageData ->
            message

        UserJoinedMessage posix userId seqDict _ ->
            message

        DeletedMessage posix ->
            message

        CallStarted callStartedData ->
            message

        GameStarted gameStartedData ->
            message


type alias ContentAndEmbeds userId =
    { content : Nonempty (RichText userId), embeds : Array Embed }


type alias EncryptedUserTextMessageData messageId userId =
    { encryptedData : EncryptedData (ContentAndEmbeds userId)
    , createdAt : Time.Posix
    , createdBy : userId
    , reactions : SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Id messageId)
    , attachedFiles : SeqDict (Id FileId) FileData
    , timestampDrawings : Drawing userId
    , userIconDrawings : Drawing userId
    , imageAttachmentDrawings : SeqDict (Id FileId) (Drawing userId)
    , -- Keyed by the index of the embed the drawing is attached to
      embedDrawings : SeqDict Int (Drawing userId)
    }


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


handleDrawingChangeHelper :
    userId
    -> Drawing.LocalChange
    -> Drawing.MessageAnchor
    ->
        { b
            | userIconDrawings : Drawing userId
            , timestampDrawings : Drawing userId
            , imageAttachmentDrawings : SeqDict (Id FileId) (Drawing userId)
            , embedDrawings : SeqDict Int (Drawing userId)
        }
    ->
        { b
            | userIconDrawings : Drawing userId
            , timestampDrawings : Drawing userId
            , imageAttachmentDrawings : SeqDict (Id FileId) (Drawing userId)
            , embedDrawings : SeqDict Int (Drawing userId)
        }
handleDrawingChangeHelper changeBy change anchorType data =
    case anchorType of
        Drawing.UserIconAnchor ->
            { data | userIconDrawings = Drawing.handleLocalChange changeBy change data.userIconDrawings }

        Drawing.TimestampAnchor ->
            { data | timestampDrawings = Drawing.handleLocalChange changeBy change data.timestampDrawings }

        Drawing.ImageAttachmentAnchor fileId ->
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
            data


handleDrawingChange : userId -> Drawing.MessageAnchor -> Drawing.LocalChange -> Message messageId userId -> Message messageId userId
handleDrawingChange changeBy anchorType change message =
    case message of
        UserTextMessage data ->
            handleDrawingChangeHelper changeBy change anchorType data |> UserTextMessage

        EncryptedUserTextMessage data ->
            handleDrawingChangeHelper changeBy change anchorType data |> EncryptedUserTextMessage

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

                Drawing.ImageAttachmentAnchor _ ->
                    message

                Drawing.EmbedImageAnchor _ ->
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

                Drawing.ImageAttachmentAnchor _ ->
                    message

                Drawing.EmbedImageAnchor _ ->
                    message

                Drawing.CardAnchor ->
                    GameStarted
                        { gameStarted
                            | cardDrawings =
                                Drawing.handleLocalChange changeBy change gameStarted.cardDrawings
                        }


userTextMessageDrawing :
    Drawing.MessageAnchor
    ->
        { a
            | userIconDrawings : Drawing userId
            , timestampDrawings : Drawing userId
            , imageAttachmentDrawings : SeqDict (Id FileId) (Drawing userId)
            , embedDrawings : SeqDict Int (Drawing userId)
        }
    -> Drawing userId
userTextMessageDrawing anchor data =
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


drawing : Drawing.MessageAnchor -> Message messageId userId -> Drawing userId
drawing anchor message =
    case message of
        UserTextMessage data ->
            userTextMessageDrawing anchor data

        EncryptedUserTextMessage data ->
            userTextMessageDrawing anchor data

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

                Drawing.ImageAttachmentAnchor _ ->
                    Drawing.emptyDrawing

                Drawing.EmbedImageAnchor _ ->
                    Drawing.emptyDrawing

                Drawing.CardAnchor ->
                    callStarted.cardDrawings

        GameStarted gameStarted ->
            case anchor of
                Drawing.UserIconAnchor ->
                    Drawing.emptyDrawing

                Drawing.TimestampAnchor ->
                    gameStarted.timestampDrawings

                Drawing.ImageAttachmentAnchor _ ->
                    Drawing.emptyDrawing

                Drawing.EmbedImageAnchor _ ->
                    Drawing.emptyDrawing

                Drawing.CardAnchor ->
                    gameStarted.cardDrawings


createdAt : Message messageId userId -> Time.Posix
createdAt message =
    case message of
        UserTextMessage data ->
            data.createdAt

        EncryptedUserTextMessage data ->
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
            UserTextMessage { message2 | reactions = addReactionEmojiHelper userId emoji message2.reactions }

        EncryptedUserTextMessage message2 ->
            EncryptedUserTextMessage { message2 | reactions = addReactionEmojiHelper userId emoji message2.reactions }

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
            UserTextMessage { message2 | reactions = removeReactionEmojiHelper userId emoji message2.reactions }

        EncryptedUserTextMessage message2 ->
            EncryptedUserTextMessage { message2 | reactions = removeReactionEmojiHelper userId emoji message2.reactions }

        UserJoinedMessage time userJoinedId reactions drawings ->
            UserJoinedMessage time userJoinedId (removeReactionEmojiHelper userId emoji reactions) drawings

        DeletedMessage _ ->
            message

        CallStarted callStarted ->
            CallStarted { callStarted | reactions = removeReactionEmojiHelper userId emoji callStarted.reactions }

        GameStarted gameStarted ->
            GameStarted { gameStarted | reactions = removeReactionEmojiHelper userId emoji gameStarted.reactions }


removeReactionEmojiHelper :
    userId
    -> EmojiOrCustomEmoji
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
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

        EncryptedUserTextMessage data ->
            data.reactions

        UserJoinedMessage _ _ reactions _ ->
            reactions

        DeletedMessage _ ->
            SeqDict.empty

        CallStarted callStarted ->
            callStarted.reactions

        GameStarted gameStarted ->
            gameStarted.reactions


contentAndEmbedsCodec : Serialize.Codec e (ContentAndEmbeds (Id UserId))
contentAndEmbedsCodec =
    Serialize.record ContentAndEmbeds
        |> Serialize.field .content (nonemptyCodec (RichText.codec Id.codec))
        |> Serialize.field .embeds (Serialize.array embedCodec)
        |> Serialize.finishRecord


nonemptyCodec : Serialize.Codec e a -> Serialize.Codec e (Nonempty a)
nonemptyCodec a =
    Serialize.customType
        (\nonemptyEncoder value ->
            case value of
                List.Nonempty.Nonempty argA argB ->
                    nonemptyEncoder argA argB
        )
        |> Serialize.variant2 List.Nonempty.Nonempty a (Serialize.list a)
        |> Serialize.finishCustomType


embedCodec : Serialize.Codec e Embed
embedCodec =
    Serialize.customType
        (\embedLoadingEncoder embedLoadedEncoder value ->
            case value of
                Embed.EmbedLoading ->
                    embedLoadingEncoder

                Embed.EmbedLoaded argA ->
                    embedLoadedEncoder argA
        )
        |> Serialize.variant0 Embed.EmbedLoading
        |> Serialize.variant1 Embed.EmbedLoaded embedDataCodec
        |> Serialize.finishCustomType


embedDataCodec : Serialize.Codec e EmbedData
embedDataCodec =
    Serialize.record EmbedData
        |> Serialize.field .title (Serialize.maybe Serialize.string)
        |> Serialize.field .image (Serialize.maybe embedImageDataCodec)
        |> Serialize.field .description (Serialize.maybe Serialize.string)
        |> Serialize.field .createdAt (Serialize.maybe posixCodec)
        |> Serialize.finishRecord


embedImageDataCodec : Serialize.Codec e Embed.EmbedImageData
embedImageDataCodec =
    Serialize.record Embed.EmbedImageData
        |> Serialize.field .url Serialize.string
        |> Serialize.field .imageSize (Serialize.tuple (quantityCodec Serialize.int) (quantityCodec Serialize.int))
        |> Serialize.field .format (Serialize.maybe embedImageFormatCodec)
        |> Serialize.finishRecord


quantityCodec : Serialize.Codec e number -> Serialize.Codec e (Quantity.Quantity number units)
quantityCodec number =
    Serialize.customType
        (\quantityEncoder value ->
            case value of
                Quantity.Quantity argA ->
                    quantityEncoder argA
        )
        |> Serialize.variant1 Quantity.Quantity number
        |> Serialize.finishCustomType


embedImageFormatCodec : Serialize.Codec e Embed.EmbedImageFormat
embedImageFormatCodec =
    Serialize.customType
        (\pngEncoder jpegEncoder gifEncoder webPEncoder pnmEncoder tiffEncoder tgaEncoder ddsEncoder bmpEncoder icoEncoder hdrEncoder openExrEncoder farbfeldEncoder avifEncoder qoiEncoder value ->
            case value of
                Embed.Png ->
                    pngEncoder

                Embed.Jpeg ->
                    jpegEncoder

                Embed.Gif ->
                    gifEncoder

                Embed.WebP ->
                    webPEncoder

                Embed.Pnm ->
                    pnmEncoder

                Embed.Tiff ->
                    tiffEncoder

                Embed.Tga ->
                    tgaEncoder

                Embed.Dds ->
                    ddsEncoder

                Embed.Bmp ->
                    bmpEncoder

                Embed.Ico ->
                    icoEncoder

                Embed.Hdr ->
                    hdrEncoder

                Embed.OpenExr ->
                    openExrEncoder

                Embed.Farbfeld ->
                    farbfeldEncoder

                Embed.Avif ->
                    avifEncoder

                Embed.Qoi ->
                    qoiEncoder
        )
        |> Serialize.variant0 Embed.Png
        |> Serialize.variant0 Embed.Jpeg
        |> Serialize.variant0 Embed.Gif
        |> Serialize.variant0 Embed.WebP
        |> Serialize.variant0 Embed.Pnm
        |> Serialize.variant0 Embed.Tiff
        |> Serialize.variant0 Embed.Tga
        |> Serialize.variant0 Embed.Dds
        |> Serialize.variant0 Embed.Bmp
        |> Serialize.variant0 Embed.Ico
        |> Serialize.variant0 Embed.Hdr
        |> Serialize.variant0 Embed.OpenExr
        |> Serialize.variant0 Embed.Farbfeld
        |> Serialize.variant0 Embed.Avif
        |> Serialize.variant0 Embed.Qoi
        |> Serialize.finishCustomType


posixCodec : Serialize.Codec e Time.Posix
posixCodec =
    Serialize.map Time.millisToPosix Time.posixToMillis Serialize.int
