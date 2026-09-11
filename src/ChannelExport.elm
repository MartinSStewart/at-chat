module ChannelExport exposing
    ( ChannelExport(..)
    , DiscordDmChannel
    , DiscordGuildChannel
    , DmChannel
    , GuildChannel
    , decode
    , discordDmChannel
    , discordDmName
    , discordGuildChannel
    , dmChannel
    , dmFileName
    , fileName
    , guildChannel
    )

{-| Writes a channel out as JSON and reads it back. The types below mirror the channel
types the backend actually holds, minus the bookkeeping that only makes sense on the
server it came from (who was last typing, which Discord message an at-chat message was
copied from), so an export carries everything a conversation is made of.
-}

import Array
import Base64
import Bytes
import ChannelDescription exposing (ChannelDescription)
import ChannelName exposing (ChannelName)
import Codec exposing (Codec)
import CodecExtra
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Date exposing (Date)
import Discord
import DiscordUserData exposing (DiscordUserData)
import DmChannel exposing (E2eeStatus)
import Drawing exposing (Drawing)
import Duration exposing (Duration)
import Effect.Time as Time
import Embed exposing (Embed)
import Emoji exposing (EmojiOrCustomEmoji)
import Encryption
import FileName exposing (FileName)
import FileStatus exposing (FileData, FileHash, FileMetadata, IsEncrypted, Orientation)
import Game
import Go
import Id exposing (ChannelMessageId, Id, UserId)
import IdArray exposing (IdArray)
import List.Nonempty exposing (Nonempty)
import LocalState exposing (BackendChannel, ChannelStatus, DiscordBackendChannel)
import Message exposing (GameType, Message, UserTextMessageDrawings)
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import OneOrGreater exposing (OneOrGreater)
import OneToOne exposing (OneToOne)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import SessionIdHash exposing (SessionIdHash)
import SheepGame
import String.Nonempty exposing (NonemptyString)
import Thread exposing (BackendThread, DiscordBackendThread, LastTypedAt)
import TimeInMinutes exposing (TimeInMinutes)
import UserSession
import WordSpellingGame


{-| A file name that's safe to hand to the browser's download prompt.
-}
fileName : ChannelName -> String
fileName channelName =
    ChannelName.toString channelName |> sanitizeFileName


{-| DM channels aren't named, so they get exported under the name of the people
in them instead.
-}
dmFileName : String -> String
dmFileName dmName =
    sanitizeFileName dmName


sanitizeFileName : String -> String
sanitizeFileName text =
    (String.map
        (\char ->
            if Char.isAlphaNum char || char == '-' || char == '_' || char == ' ' then
                char

            else
                '_'
        )
        text
        |> String.trim
    )
        ++ ".json"


type ChannelExport
    = GuildChannelExport GuildChannel
    | DmChannelExport DmChannel
    | DiscordGuildChannelExport DiscordGuildChannel
    | DiscordDmChannelExport DiscordDmChannel


type alias GuildChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , description : ChannelDescription
    , messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId))
    , status : ChannelStatus
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    , games : SeqDict (Id ChannelMessageId) Game.BackendGameData
    }


type alias DmChannel =
    { messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId))
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    , games : SeqDict (Id ChannelMessageId) Game.BackendGameData
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    , e2ee : E2eeStatus
    }


type alias DiscordGuildChannel =
    { name : ChannelName
    , description : ChannelDescription
    , isForum : Bool
    , messages : IdArray ChannelMessageId (Message ChannelMessageId (Discord.Id Discord.UserId))
    , status : ChannelStatus
    , threads : SeqDict (Id ChannelMessageId) DiscordBackendThread
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    , permissionOverwrites : List Discord.Overwrite
    }


type alias DiscordDmChannel =
    { messages : IdArray ChannelMessageId (Message ChannelMessageId (Discord.Id Discord.UserId))
    , members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    }


guildChannel : BackendChannel -> String
guildChannel channel =
    GuildChannelExport
        { createdAt = channel.createdAt
        , createdBy = channel.createdBy
        , name = channel.name
        , description = channel.description
        , messages = channel.messages
        , status = channel.status
        , threads = channel.threads
        , dateDividerDrawings = channel.dateDividerDrawings
        , games = channel.games
        }
        |> Codec.encodeToString 0 channelExportCodec


dmChannel : DmChannel.BackendDmChannel -> String
dmChannel channel =
    DmChannelExport
        { messages = channel.messages
        , threads = channel.threads
        , games = channel.games
        , dateDividerDrawings = channel.dateDividerDrawings
        , e2ee = channel.e2ee
        }
        |> Codec.encodeToString 0 channelExportCodec


discordGuildChannel : DiscordBackendChannel -> String
discordGuildChannel channel =
    DiscordGuildChannelExport
        { name = channel.name
        , description = channel.description
        , isForum = channel.isForum
        , messages = channel.messages
        , status = channel.status
        , threads = channel.threads
        , dateDividerDrawings = channel.dateDividerDrawings
        , permissionOverwrites = channel.permissionOverwrites
        }
        |> Codec.encodeToString 0 channelExportCodec


discordDmChannel : DmChannel.DiscordDmChannel -> String
discordDmChannel channel =
    DiscordDmChannelExport
        { messages = channel.messages
        , members = channel.members
        , dateDividerDrawings = channel.dateDividerDrawings
        }
        |> Codec.encodeToString 0 channelExportCodec


{-| The people in a Discord DM, for labelling the channel with. The person doing the
exporting is left out unless they're talking to themselves.
-}
discordDmName :
    SeqDict (Discord.Id Discord.UserId) DiscordUserData
    -> Discord.Id Discord.UserId
    -> DmChannel.DiscordDmChannel
    -> String
discordDmName discordUsers currentUserId channel =
    (case List.filter (\userId -> userId /= currentUserId) (List.Nonempty.toList (NonemptyDict.keys channel.members)) of
        [] ->
            [ currentUserId ]

        otherUserIds ->
            otherUserIds
    )
        |> List.map
            (\userId ->
                case SeqDict.get userId discordUsers of
                    Just discordUser ->
                        DiscordUserData.username discordUser

                    Nothing ->
                        "<unknown user>"
            )
        |> String.join ", "


decode : String -> Result Codec.Error ChannelExport
decode text =
    Codec.decodeString channelExportCodec text


channelExportCodec : Codec ChannelExport
channelExportCodec =
    Codec.custom
        (\guildChannelExportEncoder dmChannelExportEncoder discordGuildChannelExportEncoder discordDmChannelExportEncoder value ->
            case value of
                GuildChannelExport argA ->
                    guildChannelExportEncoder argA

                DmChannelExport argA ->
                    dmChannelExportEncoder argA

                DiscordGuildChannelExport argA ->
                    discordGuildChannelExportEncoder argA

                DiscordDmChannelExport argA ->
                    discordDmChannelExportEncoder argA
        )
        |> Codec.variant1 "GuildChannelExport" GuildChannelExport guildChannelCodec
        |> Codec.variant1 "DmChannelExport" DmChannelExport dmChannelCodec
        |> Codec.variant1 "DiscordGuildChannelExport" DiscordGuildChannelExport discordGuildChannelCodec
        |> Codec.variant1 "DiscordDmChannelExport" DiscordDmChannelExport discordDmChannelCodec
        |> Codec.buildCustom


guildChannelCodec : Codec GuildChannel
guildChannelCodec =
    Codec.object GuildChannel
        |> Codec.field "createdAt" .createdAt CodecExtra.time
        |> Codec.field "createdBy" .createdBy idCodec
        |> Codec.field "name" .name channelNameCodec
        |> Codec.field "description" .description channelDescriptionCodec
        |> Codec.field "messages" .messages (idArrayCodec (messageCodec idCodec))
        |> Codec.field "status" .status channelStatusCodec
        |> Codec.field "threads" .threads (seqDictCodec idCodec backendThreadCodec)
        |> Codec.field "dateDividerDrawings" .dateDividerDrawings (seqDictCodec dateCodec (drawingCodec idCodec))
        |> Codec.field "games" .games (seqDictCodec idCodec backendGameDataCodec)
        |> Codec.buildObject


dmChannelCodec : Codec DmChannel
dmChannelCodec =
    Codec.object DmChannel
        |> Codec.field "messages" .messages (idArrayCodec (messageCodec idCodec))
        |> Codec.field "threads" .threads (seqDictCodec idCodec backendThreadCodec)
        |> Codec.field "games" .games (seqDictCodec idCodec backendGameDataCodec)
        |> Codec.field "dateDividerDrawings" .dateDividerDrawings (seqDictCodec dateCodec (drawingCodec idCodec))
        |> Codec.field "e2ee" .e2ee e2eeStatusCodec
        |> Codec.buildObject


discordGuildChannelCodec : Codec DiscordGuildChannel
discordGuildChannelCodec =
    Codec.object DiscordGuildChannel
        |> Codec.field "name" .name channelNameCodec
        |> Codec.field "description" .description channelDescriptionCodec
        |> Codec.field "isForum" .isForum Codec.bool
        |> Codec.field "messages" .messages (idArrayCodec (messageCodec discordIdCodec))
        |> Codec.field "status" .status channelStatusCodec
        |> Codec.field "threads" .threads (seqDictCodec idCodec discordBackendThreadCodec)
        |> Codec.field "dateDividerDrawings" .dateDividerDrawings (seqDictCodec dateCodec (drawingCodec discordIdCodec))
        |> Codec.field "permissionOverwrites" .permissionOverwrites (Codec.list overwriteCodec)
        |> Codec.buildObject


discordDmChannelCodec : Codec DiscordDmChannel
discordDmChannelCodec =
    Codec.object DiscordDmChannel
        |> Codec.field "messages" .messages (idArrayCodec (messageCodec discordIdCodec))
        |> Codec.field
            "members"
            .members
            (nonemptyDictCodec
                discordIdCodec
                (Codec.object (\messagesSent -> { messagesSent = messagesSent })
                    |> Codec.field "messagesSent" .messagesSent Codec.int
                    |> Codec.buildObject
                )
            )
        |> Codec.field "dateDividerDrawings" .dateDividerDrawings (seqDictCodec dateCodec (drawingCodec discordIdCodec))
        |> Codec.buildObject


backendThreadCodec : Codec BackendThread
backendThreadCodec =
    Codec.object
        (\messages lastTypedAt dateDividerDrawings ->
            { messages = messages, lastTypedAt = lastTypedAt, dateDividerDrawings = dateDividerDrawings }
        )
        |> Codec.field "messages" .messages (idArrayCodec (messageCodec idCodec))
        |> Codec.field "lastTypedAt" .lastTypedAt (seqDictCodec idCodec lastTypedAtCodec)
        |> Codec.field "dateDividerDrawings" .dateDividerDrawings (seqDictCodec dateCodec (drawingCodec idCodec))
        |> Codec.buildObject


discordBackendThreadCodec : Codec DiscordBackendThread
discordBackendThreadCodec =
    Codec.object
        (\messages lastTypedAt linkedMessageIds dateDividerDrawings ->
            { messages = messages
            , lastTypedAt = lastTypedAt
            , linkedMessageIds = linkedMessageIds
            , dateDividerDrawings = dateDividerDrawings
            }
        )
        |> Codec.field "messages" .messages (idArrayCodec (messageCodec discordIdCodec))
        |> Codec.field "lastTypedAt" .lastTypedAt (seqDictCodec discordIdCodec lastTypedAtCodec)
        |> Codec.field "linkedMessageIds" .linkedMessageIds (oneToOneCodec discordIdCodec idCodec)
        |> Codec.field "dateDividerDrawings" .dateDividerDrawings (seqDictCodec dateCodec (drawingCodec discordIdCodec))
        |> Codec.buildObject


lastTypedAtCodec : Codec (LastTypedAt messageId)
lastTypedAtCodec =
    Codec.object (\time messageIndex -> { time = time, messageIndex = messageIndex })
        |> Codec.field "time" .time CodecExtra.time
        |> Codec.field "messageIndex" .messageIndex (Codec.nullable idCodec)
        |> Codec.buildObject


channelNameCodec : Codec ChannelName
channelNameCodec =
    Codec.map ChannelName.ChannelName (\(ChannelName.ChannelName a) -> a) nonemptyStringCodec


nonemptyStringCodec : Codec NonemptyString
nonemptyStringCodec =
    Codec.andThen
        (\text ->
            case String.Nonempty.fromString text of
                Just nonempty ->
                    Codec.succeed nonempty

                Nothing ->
                    Codec.fail "Text can't be empty"
        )
        String.Nonempty.toString
        Codec.string


channelDescriptionCodec : Codec ChannelDescription
channelDescriptionCodec =
    Codec.map ChannelDescription.fromStringLossy ChannelDescription.toString Codec.string


idCodec : Codec (Id a)
idCodec =
    Codec.map Id.fromInt Id.toInt Codec.int


discordIdCodec : Codec (Discord.Id idType)
discordIdCodec =
    Codec.andThen
        (\text ->
            case Discord.idFromString text of
                Just id ->
                    Codec.succeed id

                Nothing ->
                    Codec.fail ("Invalid Discord id: " ++ text)
        )
        Discord.idToString
        Codec.string


idArrayCodec : Codec v -> Codec (IdArray k v)
idArrayCodec v =
    Codec.map IdArray.fromArray IdArray.toArray (Codec.array v)


dateCodec : Codec Date
dateCodec =
    Codec.map Date.fromRataDie Date.toRataDie Codec.int


channelStatusCodec : Codec ChannelStatus
channelStatusCodec =
    Codec.custom
        (\channelActiveEncoder channelDeletedEncoder value ->
            case value of
                LocalState.ChannelActive ->
                    channelActiveEncoder

                LocalState.ChannelDeleted argA ->
                    channelDeletedEncoder argA
        )
        |> Codec.variant0 "ChannelActive" LocalState.ChannelActive
        |> Codec.variant1
            "ChannelDeleted"
            LocalState.ChannelDeleted
            (Codec.object (\deletedAt deletedBy -> { deletedAt = deletedAt, deletedBy = deletedBy })
                |> Codec.field "deletedAt" .deletedAt CodecExtra.time
                |> Codec.field "deletedBy" .deletedBy idCodec
                |> Codec.buildObject
            )
        |> Codec.buildCustom


messageCodec : Codec userId -> Codec (Message messageId userId)
messageCodec userId =
    Codec.custom
        (\userTextMessageEncoder encryptedUserTextMessageEncoder userJoinedMessageEncoder deletedMessageEncoder callStartedEncoder gameStartedEncoder value ->
            case value of
                Message.UserTextMessage argA ->
                    userTextMessageEncoder argA

                Message.EncryptedUserTextMessage argA ->
                    encryptedUserTextMessageEncoder argA

                Message.UserJoinedMessage argA argB argC argD ->
                    userJoinedMessageEncoder argA argB argC argD

                Message.DeletedMessage argA ->
                    deletedMessageEncoder argA

                Message.CallStarted argA ->
                    callStartedEncoder argA

                Message.GameStarted argA ->
                    gameStartedEncoder argA
        )
        |> Codec.variant1 "UserTextMessage" Message.UserTextMessage (userTextMessageDataCodec userId)
        |> Codec.variant1
            "EncryptedUserTextMessage"
            Message.EncryptedUserTextMessage
            (encryptedUserTextMessageDataCodec userId)
        |> Codec.variant4
            "UserJoinedMessage"
            Message.UserJoinedMessage
            CodecExtra.time
            userId
            (reactionsCodec userId)
            (drawingCodec userId)
        |> Codec.variant1 "DeletedMessage" Message.DeletedMessage CodecExtra.time
        |> Codec.variant1 "CallStarted" Message.CallStarted (callStartedDataCodec userId)
        |> Codec.variant1 "GameStarted" Message.GameStarted (gameStartedDataCodec userId)
        |> Codec.buildCustom


userTextMessageDataCodec : Codec userId -> Codec (Message.UserTextMessageData messageId userId)
userTextMessageDataCodec userId =
    Codec.object Message.UserTextMessageData
        |> Codec.field "createdAt" .createdAt CodecExtra.time
        |> Codec.field "createdBy" .createdBy userId
        |> Codec.field "content" .content (messageContentCodec userId)
        |> Codec.field "reactions" .reactions (reactionsCodec userId)
        |> Codec.field "editedAt" .editedAt (Codec.nullable CodecExtra.time)
        |> Codec.field "repliedTo" .repliedTo (Codec.nullable idCodec)
        |> Codec.field "drawings" .drawings (Codec.nullable (userTextMessageDrawingsCodec userId))
        |> Codec.buildObject


encryptedUserTextMessageDataCodec : Codec userId -> Codec (Message.EncryptedUserTextMessageData messageId userId)
encryptedUserTextMessageDataCodec userId =
    Codec.object Message.EncryptedUserTextMessageData
        |> Codec.field "createdAt" .createdAt CodecExtra.time
        |> Codec.field "createdBy" .createdBy userId
        |> Codec.field "content" .content encryptedDataCodec
        |> Codec.field "fileHashes" .fileHashes (seqSetCodec fileHashCodec)
        |> Codec.field "reactions" .reactions (reactionsCodec userId)
        |> Codec.field "editedAt" .editedAt (Codec.nullable CodecExtra.time)
        |> Codec.field "repliedTo" .repliedTo (Codec.nullable idCodec)
        |> Codec.field "drawings" .drawings (Codec.nullable (userTextMessageDrawingsCodec userId))
        |> Codec.buildObject


callStartedDataCodec : Codec userId -> Codec (Message.CallStartedData userId)
callStartedDataCodec userId =
    Codec.object Message.CallStartedData
        |> Codec.field "startedAt" .startedAt CodecExtra.time
        |> Codec.field "endedAt" .endedAt (Codec.nullable CodecExtra.time)
        |> Codec.field "startedBy" .startedBy userId
        |> Codec.field "reactions" .reactions (reactionsCodec userId)
        |> Codec.field "timestampDrawings" .timestampDrawings (drawingCodec userId)
        |> Codec.field "cardDrawings" .cardDrawings (drawingCodec userId)
        |> Codec.buildObject


gameStartedDataCodec : Codec userId -> Codec (Message.GameStartedData userId)
gameStartedDataCodec userId =
    Codec.object Message.GameStartedData
        |> Codec.field "startedAt" .startedAt CodecExtra.time
        |> Codec.field "startedBy" .startedBy userId
        |> Codec.field "reactions" .reactions (reactionsCodec userId)
        |> Codec.field "gameType" .gameType gameTypeCodec
        |> Codec.field "timestampDrawings" .timestampDrawings (drawingCodec userId)
        |> Codec.field "cardDrawings" .cardDrawings (drawingCodec userId)
        |> Codec.buildObject


gameTypeCodec : Codec GameType
gameTypeCodec =
    Codec.enum
        Codec.string
        [ ( "GameType_Go", Message.GameType_Go )
        , ( "GameType_WordSpellingGame", Message.GameType_WordSpellingGame )
        , ( "GameType_SheepGame", Message.GameType_SheepGame )
        ]


messageContentCodec : Codec userId -> Codec (Message.MessageContent userId)
messageContentCodec userId =
    Codec.object Message.MessageContent
        |> Codec.field "content" .content (nonemptyCodec (richTextCodec userId))
        |> Codec.field "embeds" .embeds (Codec.array embedCodec)
        |> Codec.field "attachedFiles" .attachedFiles (seqDictCodec idCodec fileDataCodec)
        |> Codec.buildObject


reactionsCodec : Codec userId -> Codec (SeqDict EmojiOrCustomEmoji (NonemptySet userId))
reactionsCodec userId =
    seqDictCodec emojiOrCustomEmojiCodec (nonemptySetCodec userId)


emojiOrCustomEmojiCodec : Codec EmojiOrCustomEmoji
emojiOrCustomEmojiCodec =
    Codec.custom
        (\emojiEncoder customEmojiEncoder value ->
            case value of
                Emoji.EmojiOrCustomEmoji_Emoji argA ->
                    emojiEncoder argA

                Emoji.EmojiOrCustomEmoji_CustomEmoji argA ->
                    customEmojiEncoder argA
        )
        |> Codec.variant1
            "EmojiOrCustomEmoji_Emoji"
            Emoji.EmojiOrCustomEmoji_Emoji
            (Codec.map Emoji.fromString Emoji.toString Codec.string)
        |> Codec.variant1 "EmojiOrCustomEmoji_CustomEmoji" Emoji.EmojiOrCustomEmoji_CustomEmoji idCodec
        |> Codec.buildCustom


embedCodec : Codec Embed
embedCodec =
    Codec.custom
        (\embedLoadingEncoder embedLoadedEncoder value ->
            case value of
                Embed.EmbedLoading ->
                    embedLoadingEncoder

                Embed.EmbedLoaded argA ->
                    embedLoadedEncoder argA
        )
        |> Codec.variant0 "EmbedLoading" Embed.EmbedLoading
        |> Codec.variant1 "EmbedLoaded" Embed.EmbedLoaded embedDataCodec
        |> Codec.buildCustom


embedDataCodec : Codec Embed.EmbedData
embedDataCodec =
    Codec.object Embed.EmbedData
        |> Codec.field "title" .title (Codec.nullable Codec.string)
        |> Codec.field "image" .image (Codec.nullable embedImageDataCodec)
        |> Codec.field "description" .description (Codec.nullable Codec.string)
        |> Codec.field "createdAt" .createdAt (Codec.nullable CodecExtra.time)
        |> Codec.buildObject


embedImageDataCodec : Codec Embed.EmbedImageData
embedImageDataCodec =
    Codec.object Embed.EmbedImageData
        |> Codec.field "url" .url Codec.string
        |> Codec.field "imageSize" .imageSize coordCodec
        |> Codec.field "format" .format (Codec.nullable embedImageFormatCodec)
        |> Codec.buildObject


embedImageFormatCodec : Codec Embed.EmbedImageFormat
embedImageFormatCodec =
    Codec.enum
        Codec.string
        [ ( "Png", Embed.Png )
        , ( "Jpeg", Embed.Jpeg )
        , ( "Gif", Embed.Gif )
        , ( "WebP", Embed.WebP )
        , ( "Pnm", Embed.Pnm )
        , ( "Tiff", Embed.Tiff )
        , ( "Tga", Embed.Tga )
        , ( "Dds", Embed.Dds )
        , ( "Bmp", Embed.Bmp )
        , ( "Ico", Embed.Ico )
        , ( "Hdr", Embed.Hdr )
        , ( "OpenExr", Embed.OpenExr )
        , ( "Farbfeld", Embed.Farbfeld )
        , ( "Avif", Embed.Avif )
        , ( "Qoi", Embed.Qoi )
        ]


userTextMessageDrawingsCodec : Codec userId -> Codec (UserTextMessageDrawings userId)
userTextMessageDrawingsCodec userId =
    Codec.object Message.UserTextMessageDrawings
        |> Codec.field "timestampDrawings" .timestampDrawings (drawingCodec userId)
        |> Codec.field "userIconDrawings" .userIconDrawings (drawingCodec userId)
        |> Codec.field "imageAttachmentDrawings" .imageAttachmentDrawings (seqDictCodec idCodec (drawingCodec userId))
        |> Codec.field "embedDrawings" .embedDrawings (seqDictCodec Codec.int (drawingCodec userId))
        |> Codec.buildObject


drawingCodec : Codec userId -> Codec (Drawing userId)
drawingCodec userId =
    Codec.object (\finished inProgress undone -> { finished = finished, inProgress = inProgress, undone = undone })
        |> Codec.field
            "finished"
            .finished
            (Codec.list
                (Codec.object (\createdBy points -> { createdBy = createdBy, points = points })
                    |> Codec.field "createdBy" .createdBy userId
                    |> Codec.field "points" .points (nonemptyCodec pointCodec)
                    |> Codec.buildObject
                )
            )
        |> Codec.field "inProgress" .inProgress (seqDictCodec userId strokeCodec)
        |> Codec.field "undone" .undone (seqDictCodec userId (Codec.list strokeCodec))
        |> Codec.buildObject


strokeCodec : Codec Drawing.Stroke
strokeCodec =
    Codec.object (\points -> { points = points })
        |> Codec.field "points" .points (nonemptyCodec pointCodec)
        |> Codec.buildObject


pointCodec : Codec ( Float, Float )
pointCodec =
    Codec.tuple Codec.float Codec.float


coordCodec : Codec (Coord CssPixels)
coordCodec =
    Codec.tuple CodecExtra.quantityInt CodecExtra.quantityInt


encryptedDataCodec : Codec (Encryption.EncryptedData a)
encryptedDataCodec =
    Codec.andThen
        (\text ->
            case Base64.toBytes text of
                Just bytes ->
                    Codec.succeed (Encryption.encryptedData bytes)

                Nothing ->
                    Codec.fail "Not valid base64"
        )
        Encryption.toBase64
        Codec.string


bytesCodec : Codec Bytes.Bytes
bytesCodec =
    Codec.andThen
        (\text ->
            case Base64.toBytes text of
                Just bytes ->
                    Codec.succeed bytes

                Nothing ->
                    Codec.fail "Not valid base64"
        )
        (\bytes -> Base64.fromBytes bytes |> Maybe.withDefault "")
        Codec.string


fileHashCodec : Codec FileHash
fileHashCodec =
    Codec.map FileStatus.fileHash FileStatus.fileHashToString Codec.string


fileDataCodec : Codec FileData
fileDataCodec =
    Codec.object
        (\fileName2 fileSize metadata contentType fileHash isEncrypted ->
            { fileName = fileName2
            , fileSize = fileSize
            , metadata = metadata
            , contentType = contentType
            , fileHash = fileHash
            , isEncrypted = isEncrypted
            }
        )
        |> Codec.field "fileName" .fileName fileNameCodec
        |> Codec.field "fileSize" .fileSize Codec.int
        |> Codec.field "metadata" .metadata (Codec.nullable fileMetadataCodec)
        |> Codec.field "contentType" .contentType contentTypeCodec
        |> Codec.field "fileHash" .fileHash fileHashCodec
        |> Codec.field "isEncrypted" .isEncrypted isEncryptedCodec
        |> Codec.buildObject


fileNameCodec : Codec FileName
fileNameCodec =
    Codec.map FileName.FileName (\(FileName.FileName a) -> a) nonemptyStringCodec


contentTypeCodec : Codec FileStatus.ContentType
contentTypeCodec =
    Codec.map FileStatus.contentTypeFromInt FileStatus.contentTypeToInt Codec.int


isEncryptedCodec : Codec IsEncrypted
isEncryptedCodec =
    Codec.custom
        (\isNotEncryptedEncoder isEncryptedEncoder value ->
            case value of
                FileStatus.IsNotEncrypted ->
                    isNotEncryptedEncoder

                FileStatus.IsEncrypted argA argB ->
                    isEncryptedEncoder argA argB
        )
        |> Codec.variant0 "IsNotEncrypted" FileStatus.IsNotEncrypted
        |> Codec.variant2
            "IsEncrypted"
            FileStatus.IsEncrypted
            (Codec.map FileStatus.aesPrivateKey FileStatus.aesPrivateKeyToBytes bytesCodec)
            (Codec.enum
                Codec.string
                [ ( "NoEncryptedThumbnail", FileStatus.NoEncryptedThumbnail )
                , ( "HasEncryptedThumbnail", FileStatus.HasEncryptedThumbnail )
                ]
            )
        |> Codec.buildCustom


fileMetadataCodec : Codec FileMetadata
fileMetadataCodec =
    Codec.custom
        (\imageEncoder videoEncoder value ->
            case value of
                FileStatus.FileMetadata_Image argA ->
                    imageEncoder argA

                FileStatus.FileMetadata_Video argA ->
                    videoEncoder argA
        )
        |> Codec.variant1 "FileMetadata_Image" FileStatus.FileMetadata_Image imageMetadataCodec
        |> Codec.variant1 "FileMetadata_Video" FileStatus.FileMetadata_Video videoMetadataCodec
        |> Codec.buildCustom


imageMetadataCodec : Codec FileStatus.ImageMetadata
imageMetadataCodec =
    Codec.object
        (\imageSize orientation gpsLocation cameraOwner exposureTime fNumber focalLength isoSpeedRating make model software userComment ->
            { imageSize = imageSize
            , orientation = orientation
            , gpsLocation = gpsLocation
            , cameraOwner = cameraOwner
            , exposureTime = exposureTime
            , fNumber = fNumber
            , focalLength = focalLength
            , isoSpeedRating = isoSpeedRating
            , make = make
            , model = model
            , software = software
            , userComment = userComment
            }
        )
        |> Codec.field "imageSize" .imageSize coordCodec
        |> Codec.field "orientation" .orientation (Codec.nullable orientationCodec)
        |> Codec.field "gpsLocation" .gpsLocation (Codec.nullable locationCodec)
        |> Codec.field "cameraOwner" .cameraOwner (Codec.nullable Codec.string)
        |> Codec.field "exposureTime" .exposureTime (Codec.nullable exposureTimeCodec)
        |> Codec.field "fNumber" .fNumber (Codec.nullable Codec.float)
        |> Codec.field "focalLength" .focalLength (Codec.nullable Codec.float)
        |> Codec.field "isoSpeedRating" .isoSpeedRating (Codec.nullable Codec.int)
        |> Codec.field "make" .make (Codec.nullable Codec.string)
        |> Codec.field "model" .model (Codec.nullable Codec.string)
        |> Codec.field "software" .software (Codec.nullable Codec.string)
        |> Codec.field "userComment" .userComment (Codec.nullable Codec.string)
        |> Codec.buildObject


videoMetadataCodec : Codec FileStatus.VideoMetadata
videoMetadataCodec =
    Codec.object
        (\videoSize createdAt orientation codec title gpsLocation duration ->
            { videoSize = videoSize
            , createdAt = createdAt
            , orientation = orientation
            , codec = codec
            , title = title
            , gpsLocation = gpsLocation
            , duration = duration
            }
        )
        |> Codec.field "videoSize" .videoSize coordCodec
        |> Codec.field "createdAt" .createdAt (Codec.nullable CodecExtra.time)
        |> Codec.field "orientation" .orientation orientationCodec
        |> Codec.field "codec" .codec (Codec.nullable Codec.string)
        |> Codec.field "title" .title (Codec.nullable Codec.string)
        |> Codec.field "gpsLocation" .gpsLocation (Codec.nullable locationCodec)
        |> Codec.field "duration" .duration (Codec.nullable durationCodec)
        |> Codec.buildObject


locationCodec : Codec FileStatus.Location
locationCodec =
    Codec.object (\lat lon -> { lat = lat, lon = lon })
        |> Codec.field "lat" .lat Codec.float
        |> Codec.field "lon" .lon Codec.float
        |> Codec.buildObject


exposureTimeCodec : Codec FileStatus.ExposureTime
exposureTimeCodec =
    Codec.object (\numerator denominator -> { numerator = numerator, denominator = denominator })
        |> Codec.field "numerator" .numerator Codec.int
        |> Codec.field "denominator" .denominator Codec.int
        |> Codec.buildObject


orientationCodec : Codec Orientation
orientationCodec =
    Codec.enum
        Codec.string
        [ ( "NoChange", FileStatus.NoChange )
        , ( "Rotation90", FileStatus.Rotation90 )
        , ( "Rotation180", FileStatus.Rotation180 )
        , ( "Rotation270", FileStatus.Rotation270 )
        , ( "Mirrored", FileStatus.Mirrored )
        , ( "MirroredRotation90", FileStatus.MirroredRotation90 )
        , ( "MirroredRotation180", FileStatus.MirroredRotation180 )
        , ( "MirroredRotation270", FileStatus.MirroredRotation270 )
        ]


durationCodec : Codec Duration
durationCodec =
    Codec.map Duration.seconds Duration.inSeconds Codec.float


richTextCodec : Codec userId -> Codec (RichText userId)
richTextCodec userId =
    Codec.custom
        (\userMentionEncoder normalTextEncoder boldEncoder italicEncoder underlineEncoder strikethroughEncoder spoilerEncoder blockQuoteEncoder headingEncoder hyperlinkEncoder markdownLinkEncoder inlineCodeEncoder codeBlockEncoder attachedFileEncoder escapedCharEncoder stickerEncoder customEmojiEncoder bulletPointEncoder timestampEncoder value ->
            case value of
                RichText.UserMention argA ->
                    userMentionEncoder argA

                RichText.NormalText argA argB ->
                    normalTextEncoder argA argB

                RichText.Bold argA ->
                    boldEncoder argA

                RichText.Italic argA ->
                    italicEncoder argA

                RichText.Underline argA ->
                    underlineEncoder argA

                RichText.Strikethrough argA ->
                    strikethroughEncoder argA

                RichText.Spoiler argA ->
                    spoilerEncoder argA

                RichText.BlockQuote argA argB ->
                    blockQuoteEncoder argA argB

                RichText.Heading argA argB argC ->
                    headingEncoder argA argB argC

                RichText.Hyperlink argA ->
                    hyperlinkEncoder argA

                RichText.MarkdownLink argA argB ->
                    markdownLinkEncoder argA argB

                RichText.InlineCode argA argB ->
                    inlineCodeEncoder argA argB

                RichText.CodeBlock argA argB ->
                    codeBlockEncoder argA argB

                RichText.AttachedFile argA ->
                    attachedFileEncoder argA

                RichText.EscapedChar argA ->
                    escapedCharEncoder argA

                RichText.Sticker argA ->
                    stickerEncoder argA

                RichText.CustomEmoji argA ->
                    customEmojiEncoder argA

                RichText.BulletPoint argA argB ->
                    bulletPointEncoder argA argB

                RichText.Timestamp argA ->
                    timestampEncoder argA
        )
        |> Codec.variant1 "UserMention" RichText.UserMention userId
        |> Codec.variant2 "NormalText" RichText.NormalText Codec.char Codec.string
        |> Codec.variant1 "Bold" RichText.Bold (nonemptyCodec (lazyRichText userId))
        |> Codec.variant1 "Italic" RichText.Italic (nonemptyCodec (lazyRichText userId))
        |> Codec.variant1 "Underline" RichText.Underline (nonemptyCodec (lazyRichText userId))
        |> Codec.variant1 "Strikethrough" RichText.Strikethrough (nonemptyCodec (lazyRichText userId))
        |> Codec.variant1 "Spoiler" RichText.Spoiler (nonemptyCodec (lazyRichText userId))
        |> Codec.variant2
            "BlockQuote"
            RichText.BlockQuote
            hasLeadingLineBreakCodec
            (Codec.list (lazyRichText userId))
        |> Codec.variant3
            "Heading"
            RichText.Heading
            headingLevelCodec
            hasLeadingLineBreakCodec
            (nonemptyCodec (lazyRichText userId))
        |> Codec.variant1 "Hyperlink" RichText.Hyperlink CodecExtra.url
        |> Codec.variant2 "MarkdownLink" RichText.MarkdownLink nonemptyStringCodec CodecExtra.url
        |> Codec.variant2 "InlineCode" RichText.InlineCode Codec.char Codec.string
        |> Codec.variant2 "CodeBlock" RichText.CodeBlock languageCodec Codec.string
        |> Codec.variant1 "AttachedFile" RichText.AttachedFile idCodec
        |> Codec.variant1 "EscapedChar" RichText.EscapedChar escapedCharCodec
        |> Codec.variant1 "Sticker" RichText.Sticker idCodec
        |> Codec.variant1 "CustomEmoji" RichText.CustomEmoji idCodec
        |> Codec.variant2
            "BulletPoint"
            RichText.BulletPoint
            hasLeadingLineBreakCodec
            (nonemptyCodec (Codec.list (lazyRichText userId)))
        |> Codec.variant1 "Timestamp" RichText.Timestamp timeInMinutesCodec
        |> Codec.buildCustom


lazyRichText : Codec userId -> Codec (RichText userId)
lazyRichText userId =
    Codec.lazy (\() -> richTextCodec userId)


hasLeadingLineBreakCodec : Codec RichText.HasLeadingLineBreak
hasLeadingLineBreakCodec =
    Codec.enum
        Codec.string
        [ ( "HasLeadingLineBreak", RichText.HasLeadingLineBreak )
        , ( "NoLeadingLineBreak", RichText.NoLeadingLineBreak )
        ]


headingLevelCodec : Codec RichText.HeadingLevel
headingLevelCodec =
    Codec.enum
        Codec.string
        [ ( "H1", RichText.H1 )
        , ( "H2", RichText.H2 )
        , ( "H3", RichText.H3 )
        , ( "Small", RichText.Small )
        ]


languageCodec : Codec RichText.Language
languageCodec =
    Codec.custom
        (\languageEncoder noLanguageEncoder value ->
            case value of
                RichText.Language argA ->
                    languageEncoder argA

                RichText.NoLanguage ->
                    noLanguageEncoder
        )
        |> Codec.variant1 "Language" RichText.Language nonemptyStringCodec
        |> Codec.variant0 "NoLanguage" RichText.NoLanguage
        |> Codec.buildCustom


escapedCharCodec : Codec RichText.EscapedChar
escapedCharCodec =
    Codec.enum
        Codec.string
        [ ( "EscapedSquareBracket", RichText.EscapedSquareBracket )
        , ( "EscapedBackslash", RichText.EscapedBackslash )
        , ( "EscapedBacktick", RichText.EscapedBacktick )
        , ( "EscapedAtSymbol", RichText.EscapedAtSymbol )
        , ( "EscapedBold", RichText.EscapedBold )
        , ( "EscapedItalic", RichText.EscapedItalic )
        , ( "EscapedStrikethrough", RichText.EscapedStrikethrough )
        , ( "EscapedSpoilered", RichText.EscapedSpoilered )
        ]


timeInMinutesCodec : Codec TimeInMinutes
timeInMinutesCodec =
    Codec.map TimeInMinutes.fromMinutes TimeInMinutes.toMinutes Codec.int


e2eeStatusCodec : Codec E2eeStatus
e2eeStatusCodec =
    Codec.custom
        (\e2eeDisabledEncoder e2eeRequestedByEncoder e2eeDeclinedByEncoder e2eeEnabledEncoder value ->
            case value of
                DmChannel.E2eeDisabled argA ->
                    e2eeDisabledEncoder argA

                DmChannel.E2eeRequestedBy argA ->
                    e2eeRequestedByEncoder argA

                DmChannel.E2eeDeclinedBy argA ->
                    e2eeDeclinedByEncoder argA

                DmChannel.E2eeEnabled argA ->
                    e2eeEnabledEncoder argA
        )
        |> Codec.variant1 "E2eeDisabled" DmChannel.E2eeDisabled (Codec.nullable (Codec.tuple idCodec CodecExtra.time))
        |> Codec.variant1 "E2eeRequestedBy" DmChannel.E2eeRequestedBy (Codec.tuple idCodec sessionIdHashCodec)
        |> Codec.variant1 "E2eeDeclinedBy" DmChannel.E2eeDeclinedBy idCodec
        |> Codec.variant1 "E2eeEnabled" DmChannel.E2eeEnabled e2eeEnabledDataCodec
        |> Codec.buildCustom


sessionIdHashCodec : Codec SessionIdHash
sessionIdHashCodec =
    Codec.map SessionIdHash.fromString SessionIdHash.toString Codec.string


e2eeEnabledDataCodec : Codec DmChannel.E2eeEnabledData
e2eeEnabledDataCodec =
    Codec.object (\enabledAt requestedBy -> { enabledAt = enabledAt, requestedBy = requestedBy })
        |> Codec.field "enabledAt" .enabledAt CodecExtra.time
        |> Codec.field "requestedBy" .requestedBy (Codec.tuple idCodec sessionIdHashCodec)
        |> Codec.buildObject


overwriteCodec : Codec Discord.Overwrite
overwriteCodec =
    Codec.object (\id allow deny -> { id = id, allow = allow, deny = deny })
        |> Codec.field "id" .id roleOrUserIdCodec
        |> Codec.field "allow" .allow permissionsCodec
        |> Codec.field "deny" .deny permissionsCodec
        |> Codec.buildObject


roleOrUserIdCodec : Codec Discord.RoleOrUserId
roleOrUserIdCodec =
    Codec.custom
        (\roleIdEncoder userIdEncoder value ->
            case value of
                Discord.RoleOrUserId_RoleId argA ->
                    roleIdEncoder argA

                Discord.RoleOrUserId_UserId argA ->
                    userIdEncoder argA
        )
        |> Codec.variant1 "RoleOrUserId_RoleId" Discord.RoleOrUserId_RoleId discordIdCodec
        |> Codec.variant1 "RoleOrUserId_UserId" Discord.RoleOrUserId_UserId discordIdCodec
        |> Codec.buildCustom


permissionsCodec : Codec Discord.Permissions
permissionsCodec =
    Codec.object Discord.Permissions
        |> Codec.field "createInstantInvite" .createInstantInvite Codec.bool
        |> Codec.field "kickMembers" .kickMembers Codec.bool
        |> Codec.field "banMembers" .banMembers Codec.bool
        |> Codec.field "administrator" .administrator Codec.bool
        |> Codec.field "manageChannels" .manageChannels Codec.bool
        |> Codec.field "manageGuild" .manageGuild Codec.bool
        |> Codec.field "addReaction" .addReaction Codec.bool
        |> Codec.field "viewAuditLog" .viewAuditLog Codec.bool
        |> Codec.field "prioritySpeaker" .prioritySpeaker Codec.bool
        |> Codec.field "stream" .stream Codec.bool
        |> Codec.field "viewChannel" .viewChannel Codec.bool
        |> Codec.field "sendMessages" .sendMessages Codec.bool
        |> Codec.field "sentTextToSpeechMessages" .sentTextToSpeechMessages Codec.bool
        |> Codec.field "manageMessages" .manageMessages Codec.bool
        |> Codec.field "embedLinks" .embedLinks Codec.bool
        |> Codec.field "attachFiles" .attachFiles Codec.bool
        |> Codec.field "readMessageHistory" .readMessageHistory Codec.bool
        |> Codec.field "mentionEveryone" .mentionEveryone Codec.bool
        |> Codec.field "useExternalEmojis" .useExternalEmojis Codec.bool
        |> Codec.field "viewGuildInsights" .viewGuildInsights Codec.bool
        |> Codec.field "connect" .connect Codec.bool
        |> Codec.field "speak" .speak Codec.bool
        |> Codec.field "muteMembers" .muteMembers Codec.bool
        |> Codec.field "deafenMembers" .deafenMembers Codec.bool
        |> Codec.field "moveMembers" .moveMembers Codec.bool
        |> Codec.field "useVoiceActivityDetection" .useVoiceActivityDetection Codec.bool
        |> Codec.field "changeNickname" .changeNickname Codec.bool
        |> Codec.field "manageNicknames" .manageNicknames Codec.bool
        |> Codec.field "manageRoles" .manageRoles Codec.bool
        |> Codec.field "manageWebhooks" .manageWebhooks Codec.bool
        |> Codec.field "manageGuildExpressions" .manageGuildExpressions Codec.bool
        |> Codec.field "useApplicationCommands" .useApplicationCommands Codec.bool
        |> Codec.field "requestToSpeak" .requestToSpeak Codec.bool
        |> Codec.field "manageEvents" .manageEvents Codec.bool
        |> Codec.field "manageThreads" .manageThreads Codec.bool
        |> Codec.field "createPublicThreads" .createPublicThreads Codec.bool
        |> Codec.field "createPrivateThreads" .createPrivateThreads Codec.bool
        |> Codec.field "useExternalStickers" .useExternalStickers Codec.bool
        |> Codec.field "sendMessagesInThreads" .sendMessagesInThreads Codec.bool
        |> Codec.field "useEmbeddedActivities" .useEmbeddedActivities Codec.bool
        |> Codec.field "moderateMembers" .moderateMembers Codec.bool
        |> Codec.field "viewCreatorMontetizationAnalytics" .viewCreatorMontetizationAnalytics Codec.bool
        |> Codec.field "useSoundboard" .useSoundboard Codec.bool
        |> Codec.field "createGuildExpressions" .createGuildExpressions Codec.bool
        |> Codec.field "createEvents" .createEvents Codec.bool
        |> Codec.field "useExternalSounds" .useExternalSounds Codec.bool
        |> Codec.field "sendVoiceMessages" .sendVoiceMessages Codec.bool
        |> Codec.field "sendPolls" .sendPolls Codec.bool
        |> Codec.field "useExternalApps" .useExternalApps Codec.bool
        |> Codec.buildObject



-- Games. Only the setup and the list of actions are written down. The board each game is
-- showing is worked out by replaying those actions, the same way the backend does, so the
-- export can't disagree with the game it came from.


backendGameDataCodec : Codec Game.BackendGameData
backendGameDataCodec =
    Codec.custom
        (\goEncoder wordSpellingEncoder sheepEncoder value ->
            case value of
                Game.GameData_Go argA argB ->
                    goEncoder argA argB

                Game.GameData_WordSpellingGame argA argB _ ->
                    wordSpellingEncoder argA argB

                Game.GameData_SheepGame argA argB _ ->
                    sheepEncoder argA argB
        )
        |> Codec.variant2 "GameData_Go" Game.GameData_Go goSetupCodec (Codec.array goActionCodec)
        |> Codec.variant2
            "GameData_WordSpellingGame"
            (\setup actions ->
                Game.GameData_WordSpellingGame
                    setup
                    actions
                    (Array.foldl
                        (\action shared -> WordSpellingGame.updateAction setup action shared |> Tuple.first)
                        (WordSpellingGame.initShared setup)
                        actions
                    )
            )
            wordSpellingSetupCodec
            (Codec.array wordSpellingActionCodec)
        |> Codec.variant2
            "GameData_SheepGame"
            (\setup actions ->
                Game.GameData_SheepGame
                    setup
                    actions
                    (Array.foldl (SheepGame.updateAction setup) SheepGame.initShared actions)
            )
            sheepSetupCodec
            (Codec.array sheepActionCodec)
        |> Codec.buildCustom


goSetupCodec : Codec Go.ValidatedSetup
goSetupCodec =
    Codec.object
        (\width height handicap komiHalfPoints timeControl createdBy gameCreatorPlayingAs ->
            { width = width
            , height = height
            , handicap = handicap
            , komiHalfPoints = komiHalfPoints
            , timeControl = timeControl
            , createdBy = createdBy
            , gameCreatorPlayingAs = gameCreatorPlayingAs
            }
        )
        |> Codec.field "width" .width boardSizeCodec
        |> Codec.field "height" .height boardSizeCodec
        |> Codec.field "handicap" .handicap Codec.int
        |> Codec.field "komiHalfPoints" .komiHalfPoints komiHalfPointsCodec
        |> Codec.field "timeControl" .timeControl (Codec.nullable timeControlCodec)
        |> Codec.field "createdBy" .createdBy idCodec
        |> Codec.field "gameCreatorPlayingAs" .gameCreatorPlayingAs stoneCodec
        |> Codec.buildObject


boardSizeCodec : Codec Go.BoardSize
boardSizeCodec =
    Codec.map Go.boardSizeFromInt Go.boardSizeToInt Codec.int


komiHalfPointsCodec : Codec Go.KomiHalfPoints
komiHalfPointsCodec =
    Codec.map Go.KomiHalfPoints (\(Go.KomiHalfPoints a) -> a) Codec.int


timeControlCodec : Codec Go.TimeControl
timeControlCodec =
    Codec.object (\mainTime increment -> { mainTime = mainTime, increment = increment })
        |> Codec.field "mainTime" .mainTime durationCodec
        |> Codec.field "increment" .increment durationCodec
        |> Codec.buildObject


stoneCodec : Codec Go.Stone
stoneCodec =
    Codec.enum Codec.string [ ( "Black", Go.Black ), ( "White", Go.White ) ]


goActionCodec : Codec Go.ActionWithTime
goActionCodec =
    Codec.object (\time change -> { time = time, change = change })
        |> Codec.field "time" .time CodecExtra.time
        |> Codec.field "change" .change goChangeCodec
        |> Codec.buildObject


goChangeCodec : Codec Go.Action
goChangeCodec =
    Codec.custom
        (\placeStoneEncoder passTurnEncoder markTerritoryEncoder finishedMarkingEncoder acceptTerritoryEncoder rejectTerritoryEncoder joinedEncoder value ->
            case value of
                Go.PlaceStone argA argB ->
                    placeStoneEncoder argA argB

                Go.PassTurn ->
                    passTurnEncoder

                Go.MarkTerritory argA argB ->
                    markTerritoryEncoder argA argB

                Go.FinishedMarking ->
                    finishedMarkingEncoder

                Go.AcceptTerritory ->
                    acceptTerritoryEncoder

                Go.RejectTerritory ->
                    rejectTerritoryEncoder

                Go.Joined argA ->
                    joinedEncoder argA
        )
        |> Codec.variant2 "PlaceStone" Go.PlaceStone Codec.int Codec.int
        |> Codec.variant0 "PassTurn" Go.PassTurn
        |> Codec.variant2 "MarkTerritory" Go.MarkTerritory Codec.int Codec.int
        |> Codec.variant0 "FinishedMarking" Go.FinishedMarking
        |> Codec.variant0 "AcceptTerritory" Go.AcceptTerritory
        |> Codec.variant0 "RejectTerritory" Go.RejectTerritory
        |> Codec.variant1 "Joined" Go.Joined idCodec
        |> Codec.buildCustom


wordSpellingSetupCodec : Codec WordSpellingGame.ValidatedSetup
wordSpellingSetupCodec =
    Codec.object
        (\timeControls traySize fullTrayBonus createdBy seed letters language placeWordAttempts ->
            { timeControls = timeControls
            , traySize = traySize
            , fullTrayBonus = fullTrayBonus
            , createdBy = createdBy
            , seed = seed
            , letters = letters
            , language = language
            , placeWordAttempts = placeWordAttempts
            }
        )
        |> Codec.field "timeControls" .timeControls timeControlCodec
        |> Codec.field "traySize" .traySize oneOrGreaterCodec
        |> Codec.field "fullTrayBonus" .fullTrayBonus Codec.int
        |> Codec.field "createdBy" .createdBy idCodec
        |> Codec.field "seed" .seed Codec.int
        |> Codec.field
            "letters"
            .letters
            (nonemptyDictCodec
                letterOrWildcardCodec
                (Codec.object (\count value -> { count = count, value = value })
                    |> Codec.field "count" .count oneOrGreaterCodec
                    |> Codec.field "value" .value Codec.int
                    |> Codec.buildObject
                )
            )
        |> Codec.field
            "language"
            .language
            (Codec.enum
                Codec.string
                [ ( "English", WordSpellingGame.English ), ( "Swedish", WordSpellingGame.Swedish ) ]
            )
        |> Codec.field "placeWordAttempts" .placeWordAttempts oneOrGreaterCodec
        |> Codec.buildObject


oneOrGreaterCodec : Codec OneOrGreater
oneOrGreaterCodec =
    Codec.andThen
        (\int ->
            case OneOrGreater.fromInt int of
                Just oneOrGreater ->
                    Codec.succeed oneOrGreater

                Nothing ->
                    Codec.fail "Has to be 1 or greater"
        )
        OneOrGreater.toInt
        Codec.int


letterOrWildcardCodec : Codec WordSpellingGame.LetterOrWildcard
letterOrWildcardCodec =
    Codec.custom
        (\letterEncoder wildcardEncoder value ->
            case value of
                WordSpellingGame.Letter (WordSpellingGame.LetterChar argA) ->
                    letterEncoder argA

                WordSpellingGame.Wildcard ->
                    wildcardEncoder
        )
        |> Codec.variant1
            "Letter"
            (\char -> WordSpellingGame.Letter (WordSpellingGame.LetterChar char))
            Codec.char
        |> Codec.variant0 "Wildcard" WordSpellingGame.Wildcard
        |> Codec.buildCustom


wordSpellingActionCodec : Codec WordSpellingGame.ActionWithTime
wordSpellingActionCodec =
    Codec.object (\userId time change -> { userId = userId, time = time, change = change })
        |> Codec.field "userId" .userId idCodec
        |> Codec.field "time" .time CodecExtra.time
        |> Codec.field "change" .change wordSpellingChangeCodec
        |> Codec.buildObject


wordSpellingChangeCodec : Codec WordSpellingGame.Action
wordSpellingChangeCodec =
    Codec.custom
        (\placeWordEncoder replaceTrayOrPassEncoder joinGameEncoder premoveEncoder cancelPremoveEncoder value ->
            case value of
                WordSpellingGame.PlaceWord argA argB ->
                    placeWordEncoder argA argB

                WordSpellingGame.ReplaceTrayOrPass ->
                    replaceTrayOrPassEncoder

                WordSpellingGame.JoinGame ->
                    joinGameEncoder

                WordSpellingGame.Premove argA argB ->
                    premoveEncoder argA argB

                WordSpellingGame.CancelPremove ->
                    cancelPremoveEncoder
        )
        |> Codec.variant2 "PlaceWord" WordSpellingGame.PlaceWord placedWordCodec isValidCodec
        |> Codec.variant0 "ReplaceTrayOrPass" WordSpellingGame.ReplaceTrayOrPass
        |> Codec.variant0 "JoinGame" WordSpellingGame.JoinGame
        |> Codec.variant2 "Premove" WordSpellingGame.Premove placedWordCodec isValidCodec
        |> Codec.variant0 "CancelPremove" WordSpellingGame.CancelPremove
        |> Codec.buildCustom


placedWordCodec : Codec WordSpellingGame.PlacedWord
placedWordCodec =
    Codec.object (\start isVertical letters -> { start = start, isVertical = isVertical, letters = letters })
        |> Codec.field "start" .start (Codec.tuple Codec.int Codec.int)
        |> Codec.field "isVertical" .isVertical Codec.bool
        |> Codec.field "letters" .letters (nonemptyCodec letterOrWildcardCodec)
        |> Codec.buildObject


isValidCodec : Codec (UserSession.ToBeFilledInByBackend WordSpellingGame.IsValid)
isValidCodec =
    Codec.custom
        (\emptyPlaceholderEncoder isValidEncoder isNotValidEncoder value ->
            case value of
                UserSession.EmptyPlaceholder ->
                    emptyPlaceholderEncoder

                UserSession.FilledInByBackend (WordSpellingGame.IsValid argA) ->
                    isValidEncoder argA

                UserSession.FilledInByBackend WordSpellingGame.IsNotValid ->
                    isNotValidEncoder
        )
        |> Codec.variant0 "EmptyPlaceholder" UserSession.EmptyPlaceholder
        |> Codec.variant1
            "IsValid"
            (\words -> UserSession.FilledInByBackend (WordSpellingGame.IsValid words))
            (Codec.set Codec.string)
        |> Codec.variant0 "IsNotValid" (UserSession.FilledInByBackend WordSpellingGame.IsNotValid)
        |> Codec.buildCustom


sheepSetupCodec : Codec SheepGame.ValidatedSetup
sheepSetupCodec =
    Codec.object (\questions createdBy -> { questions = questions, createdBy = createdBy })
        |> Codec.field "questions" .questions (nonemptyCodec sheepInputCodec)
        |> Codec.field "createdBy" .createdBy idCodec
        |> Codec.buildObject


sheepInputCodec : Codec SheepGame.ValidatedInput
sheepInputCodec =
    Codec.object (\text attachedFiles reactions -> { text = text, attachedFiles = attachedFiles, reactions = reactions })
        |> Codec.field "text" .text (nonemptyCodec (richTextCodec idCodec))
        |> Codec.field "attachedFiles" .attachedFiles (seqDictCodec idCodec fileDataCodec)
        |> Codec.field "reactions" .reactions (reactionsCodec idCodec)
        |> Codec.buildObject


sheepActionCodec : Codec SheepGame.ActionWithTime
sheepActionCodec =
    Codec.object (\userId time change -> { userId = userId, time = time, change = change })
        |> Codec.field "userId" .userId idCodec
        |> Codec.field "time" .time CodecExtra.time
        |> Codec.field "change" .change sheepChangeCodec
        |> Codec.buildObject


sheepChangeCodec : Codec SheepGame.Action
sheepChangeCodec =
    Codec.custom
        (\submittedAnswerEncoder lockedAnswersEncoder unlockedAnswersEncoder changedGroupEncoder changedNotesEncoder finishedGroupingEncoder changedQuestionsRevealedEncoder addedReactionEncoder removedReactionEncoder value ->
            case value of
                SheepGame.SubmittedAnswer argA argB ->
                    submittedAnswerEncoder argA argB

                SheepGame.LockedAnswers ->
                    lockedAnswersEncoder

                SheepGame.UnlockedAnswers ->
                    unlockedAnswersEncoder

                SheepGame.ChangedGroup argA argB argC ->
                    changedGroupEncoder argA argB argC

                SheepGame.ChangedNotes argA argB ->
                    changedNotesEncoder argA argB

                SheepGame.FinishedGrouping ->
                    finishedGroupingEncoder

                SheepGame.ChangedQuestionsRevealed argA ->
                    changedQuestionsRevealedEncoder argA

                SheepGame.AddedReaction argA argB ->
                    addedReactionEncoder argA argB

                SheepGame.RemovedReaction argA argB ->
                    removedReactionEncoder argA argB
        )
        |> Codec.variant2 "SubmittedAnswer" SheepGame.SubmittedAnswer idCodec (Codec.nullable sheepInputCodec)
        |> Codec.variant0 "LockedAnswers" SheepGame.LockedAnswers
        |> Codec.variant0 "UnlockedAnswers" SheepGame.UnlockedAnswers
        |> Codec.variant3 "ChangedGroup" SheepGame.ChangedGroup idCodec idCodec Codec.string
        |> Codec.variant2 "ChangedNotes" SheepGame.ChangedNotes idCodec (Codec.nullable sheepInputCodec)
        |> Codec.variant0 "FinishedGrouping" SheepGame.FinishedGrouping
        |> Codec.variant1 "ChangedQuestionsRevealed" SheepGame.ChangedQuestionsRevealed idCodec
        |> Codec.variant2 "AddedReaction" SheepGame.AddedReaction reactionTargetCodec emojiOrCustomEmojiCodec
        |> Codec.variant2 "RemovedReaction" SheepGame.RemovedReaction reactionTargetCodec emojiOrCustomEmojiCodec
        |> Codec.buildCustom


reactionTargetCodec : Codec SheepGame.ReactionTarget
reactionTargetCodec =
    Codec.custom
        (\answerEncoder notesEncoder value ->
            case value of
                SheepGame.AnswerReaction argA argB ->
                    answerEncoder argA argB

                SheepGame.NotesReaction argA ->
                    notesEncoder argA
        )
        |> Codec.variant2 "AnswerReaction" SheepGame.AnswerReaction idCodec idCodec
        |> Codec.variant1 "NotesReaction" SheepGame.NotesReaction idCodec
        |> Codec.buildCustom



-- Containers


nonemptyCodec : Codec a -> Codec (Nonempty a)
nonemptyCodec a =
    Codec.andThen
        (\list ->
            case List.Nonempty.fromList list of
                Just nonempty ->
                    Codec.succeed nonempty

                Nothing ->
                    Codec.fail "List can't be empty"
        )
        List.Nonempty.toList
        (Codec.list a)


nonemptySetCodec : Codec a -> Codec (NonemptySet a)
nonemptySetCodec a =
    Codec.andThen
        (\list ->
            case NonemptySet.fromList list of
                Just nonempty ->
                    Codec.succeed nonempty

                Nothing ->
                    Codec.fail "Set can't be empty"
        )
        NonemptySet.toList
        (Codec.list a)


seqSetCodec : Codec a -> Codec (SeqSet a)
seqSetCodec a =
    Codec.map SeqSet.fromList SeqSet.toList (Codec.list a)


nonemptyDictCodec : Codec id -> Codec a -> Codec (NonemptyDict id a)
nonemptyDictCodec id a =
    Codec.andThen
        (\dict ->
            case NonemptyDict.fromSeqDict dict of
                Just nonempty ->
                    Codec.succeed nonempty

                Nothing ->
                    Codec.fail "Dict can't be empty"
        )
        NonemptyDict.toSeqDict
        (seqDictCodec id a)


seqDictCodec : Codec a -> Codec b -> Codec (SeqDict a b)
seqDictCodec a b =
    Codec.object Tuple.pair
        |> Codec.field "k" Tuple.first a
        |> Codec.field "v" Tuple.second b
        |> Codec.buildObject
        |> Codec.list
        |> Codec.map SeqDict.fromList SeqDict.toList


oneToOneCodec : Codec a -> Codec b -> Codec (OneToOne a b)
oneToOneCodec a b =
    Codec.object Tuple.pair
        |> Codec.field "first" Tuple.first a
        |> Codec.field "second" Tuple.second b
        |> Codec.buildObject
        |> Codec.list
        |> Codec.map OneToOne.fromList OneToOne.toList
