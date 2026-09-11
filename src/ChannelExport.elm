module ChannelExport exposing
    ( channelExportCodec
    , dmFileName
    , fileName
    )

import Array exposing (Array)
import Bytes
import ChannelDescription exposing (ChannelDescription)
import ChannelName exposing (ChannelName)
import Codec exposing (Codec)
import CodecExtra
import Coord
import CustomEmoji
import Date exposing (Date)
import Discord
import DiscordUserData exposing (DiscordUserData)
import DmChannel exposing (E2eeStatus)
import Drawing exposing (Drawing)
import Duration
import Effect.Time as Time
import Embed exposing (Embed(..))
import Emoji exposing (EmojiOrCustomEmoji(..))
import Encryption as Encrypted
import FileName
import FileStatus exposing (FileData, FileHash, FileId, FileMetadata(..), IsEncrypted(..), Orientation(..))
import Game
import GuildName
import Id exposing (ChannelMessageId, Id, UserId)
import IdArray exposing (IdArray)
import Iso8601
import Json.Encode
import List.Nonempty exposing (Nonempty)
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild)
import MembersAndOwner
import Message exposing (GameType(..), Message(..), UserTextMessageDrawings)
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import PersonName
import Ports
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import SeqSet
import SessionIdHash
import String.Nonempty
import Thread exposing (BackendThread, DiscordBackendThread)
import UInt64
import User exposing (BackendUser)


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
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    , permissionOverwrites : List Discord.Overwrite
    }


type alias DiscordDmChannel =
    { messages : IdArray ChannelMessageId (Message ChannelMessageId (Discord.Id Discord.UserId))
    , members : NonemptyDict (Discord.Id Discord.UserId) { messagesSent : Int }
    , dateDividerDrawings : SeqDict Date (Drawing (Discord.Id Discord.UserId))
    }


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


channelNameCodec : Codec ChannelName
channelNameCodec =
    Codec.custom
        (\channelNameEncoder value ->
            case value of
                ChannelName.ChannelName argA ->
                    channelNameEncoder argA
        )
        |> Codec.variant1 "ChannelName" ChannelName nonemptyStringCodec
        |> Codec.buildCustom


nonemptyStringCodec : Codec String.Nonempty.NonemptyString
nonemptyStringCodec =
    Codec.custom
        (\nonemptyStringEncoder value ->
            case value of
                String.Nonempty.NonemptyString argA argB ->
                    nonemptyStringEncoder argA argB
        )
        |> Codec.variant2 "NonemptyString" String.Nonempty.NonemptyString Codec.char Codec.string
        |> Codec.buildCustom


channelDescriptionCodec : Codec ChannelDescription
channelDescriptionCodec =
    Codec.custom
        (\channelDescriptionEncoder value ->
            case value of
                ChannelDescription.ChannelDescription argA ->
                    channelDescriptionEncoder argA
        )
        |> Codec.variant1 "ChannelDescription" ChannelDescription Codec.string
        |> Codec.buildCustom


idArrayCodec : Codec k -> Codec v -> Codec (IdArray k v)
idArrayCodec k v =
    Codec.custom
        (\idArrayEncoder value ->
            case value of
                IdArray.IdArray argA ->
                    idArrayEncoder argA
        )
        |> Codec.variant1 "IdArray" IdArray Codec.array
        |> Codec.buildCustom


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


dmChannelCodec : Codec DmChannel
dmChannelCodec =
    Codec.object DmChannel
        |> Codec.field "messages" .messages (idArrayCodec (messageCodec idCodec))
        |> Codec.field "threads" .threads (seqDictCodec idCodec backendThreadCodec)
        |> Codec.field "games" .games (seqDictCodec idCodec backendGameDataCodec)
        |> Codec.field "dateDividerDrawings" .dateDividerDrawings (seqDictCodec dateCodec (drawingCodec idCodec))
        |> Codec.field "e2ee" .e2ee e2eeStatusCodec
        |> Codec.buildObject


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
            Ports.expirationTimeCodec
            userId
            (seqDictCodec emojiOrCustomEmojiCodec (nonemptySetCodec userId))
            (drawingCodec userId)
        |> Codec.variant1 "DeletedMessage" Message.DeletedMessage Ports.expirationTimeCodec
        |> Codec.variant1 "CallStarted" Message.CallStarted (callStartedDataCodec userId)
        |> Codec.variant1 "GameStarted" Message.GameStarted (gameStartedDataCodec userId)
        |> Codec.buildCustom


userTextMessageDataCodec : Codec messageId -> Codec userId -> Codec (Message.UserTextMessageData messageId userId)
userTextMessageDataCodec messageId userId =
    Codec.object Message.UserTextMessageData
        |> Codec.field "createdAt" .createdAt Ports.expirationTimeCodec
        |> Codec.field "createdBy" .createdBy userId
        |> Codec.field "content" .content messageContentCodec
        |> Codec.field "reactions" .reactions (seqDictCodec emojiOrCustomEmojiCodec (nonemptySetCodec userId))
        |> Codec.field "editedAt" .editedAt (Codec.nullable Ports.expirationTimeCodec)
        |> Codec.field "repliedTo" .repliedTo (Codec.nullable idCodec)
        |> Codec.field "drawings" .drawings (Codec.nullable (userTextMessageDrawingsCodec userId))
        |> Codec.buildObject


messageContentCodec : Codec userId -> Codec (Message.MessageContent userId)
messageContentCodec userId =
    Codec.object Message.MessageContent
        |> Codec.field "content" .content (nonemptyCodec (richTextCodec userId))
        |> Codec.field "embeds" .embeds (Codec.array embedCodec)
        |> Codec.field "attachedFiles" .attachedFiles (seqDictCodec idCodec fileDataCodec)
        |> Codec.buildObject


nonemptyCodec : Codec a -> Codec (Nonempty a)
nonemptyCodec a =
    Codec.custom
        (\nonemptyEncoder value ->
            case value of
                List.Nonempty.Nonempty argA argB ->
                    nonemptyEncoder argA argB
        )
        |> Codec.variant2 "Nonempty" Nonempty a Codec.list
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
        |> Codec.field "imageSize" .imageSize (Codec.tuple CodecExtra.quantityInt CodecExtra.quantityInt)
        |> Codec.field "format" .format (Codec.nullable embedImageFormatCodec)
        |> Codec.buildObject


embedImageFormatCodec : Codec Embed.EmbedImageFormat
embedImageFormatCodec =
    Codec.custom
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
        |> Codec.variant0 "Png" Embed.Png
        |> Codec.variant0 "Jpeg" Embed.Jpeg
        |> Codec.variant0 "Gif" Embed.Gif
        |> Codec.variant0 "WebP" Embed.WebP
        |> Codec.variant0 "Pnm" Embed.Pnm
        |> Codec.variant0 "Tiff" Embed.Tiff
        |> Codec.variant0 "Tga" Embed.Tga
        |> Codec.variant0 "Dds" Embed.Dds
        |> Codec.variant0 "Bmp" Embed.Bmp
        |> Codec.variant0 "Ico" Embed.Ico
        |> Codec.variant0 "Hdr" Embed.Hdr
        |> Codec.variant0 "OpenExr" Embed.OpenExr
        |> Codec.variant0 "Farbfeld" Embed.Farbfeld
        |> Codec.variant0 "Avif" Embed.Avif
        |> Codec.variant0 "Qoi" Embed.Qoi
        |> Codec.buildCustom


userTextMessageDrawingsCodec : Codec userId -> Codec (UserTextMessageDrawings userId)
userTextMessageDrawingsCodec userId =
    Codec.object UserTextMessageDrawings
        |> Codec.field "timestampDrawings" .timestampDrawings (drawingCodec userId)
        |> Codec.field "userIconDrawings" .userIconDrawings (drawingCodec userId)
        |> Codec.field "imageAttachmentDrawings" .imageAttachmentDrawings (seqDictCodec idCodec (drawingCodec userId))
        |> Codec.field "embedDrawings" .embedDrawings (seqDictCodec Codec.int (drawingCodec userId))
        |> Codec.buildObject


drawingCodec : Codec userId -> Codec (Drawing userId)
drawingCodec userId =
    Codec.object Drawing
        |> Codec.field
            "finished"
            .finished
            (Codec.list
                (Codec.object (\createdBy points -> { createdBy = createdBy, points = points })
                    |> Codec.field "createdBy" .createdBy userId
                    |> Codec.field "points" .points (nonemptyCodec (Codec.tuple Codec.float Codec.float))
                    |> Codec.buildObject
                )
            )
        |> Codec.field "inProgress" .inProgress (seqDictCodec userId strokeCodec)
        |> Codec.field "undone" .undone (seqDictCodec userId (Codec.list strokeCodec))
        |> Codec.buildObject


encryptedUserTextMessageDataCodec : Codec messageId -> Codec userId -> Codec (Message.EncryptedUserTextMessageData messageId userId)
encryptedUserTextMessageDataCodec messageId userId =
    Codec.object Message.EncryptedUserTextMessageData
        |> Codec.field "createdAt" .createdAt Ports.expirationTimeCodec
        |> Codec.field "createdBy" .createdBy userId
        |> Codec.field "content" .content encryptedDataCodec
        |> Codec.field "fileHashes" .fileHashes (seqSetCodec fileHashCodec)
        |> Codec.field "reactions" .reactions (seqDictCodec emojiOrCustomEmojiCodec (nonemptySetCodec userId))
        |> Codec.field "editedAt" .editedAt (Codec.nullable Ports.expirationTimeCodec)
        |> Codec.field "repliedTo" .repliedTo (Codec.nullable idCodec)
        |> Codec.field "drawings" .drawings (Codec.nullable userTextMessageDrawingsCodec)
        |> Codec.buildObject


encryptedDataCodec : Codec a -> Codec (Encrypted.EncryptedData a)
encryptedDataCodec a =
    Codec.custom
        (\encryptedDataEncoder value ->
            case value of
                Encrypted.EncryptedData argA ->
                    encryptedDataEncoder argA
        )
        |> Codec.variant1 "EncryptedData" Encrypted.EncryptedData bytesCodec
        |> Codec.buildCustom


bytesCodec : Codec Bytes.Bytes
bytesCodec =
    Debug.todo
        "Could not automatically generate a definition for `Bytes.Bytes`, as we don't know how to implement this type."


seqSetCodec : Codec a -> Codec (SeqSet.SeqSet a)
seqSetCodec a =
    Debug.todo
        "Could not automatically generate a definition for `SeqSet.SeqSet`, as we don't know how to implement this type."


callStartedDataCodec : Codec userId -> Codec (Message.CallStartedData userId)
callStartedDataCodec userId =
    Codec.object Message.CallStartedData
        |> Codec.field "startedAt" .startedAt Ports.expirationTimeCodec
        |> Codec.field "endedAt" .endedAt (Codec.nullable Ports.expirationTimeCodec)
        |> Codec.field "startedBy" .startedBy userId
        |> Codec.field "reactions" .reactions (seqDictCodec emojiOrCustomEmojiCodec (nonemptySetCodec userId))
        |> Codec.field "timestampDrawings" .timestampDrawings drawingCodec
        |> Codec.field "cardDrawings" .cardDrawings drawingCodec
        |> Codec.buildObject


gameStartedDataCodec : Codec userId -> Codec (Message.GameStartedData userId)
gameStartedDataCodec userId =
    Codec.object Message.GameStartedData
        |> Codec.field "startedAt" .startedAt Ports.expirationTimeCodec
        |> Codec.field "startedBy" .startedBy userId
        |> Codec.field "reactions" .reactions (seqDictCodec emojiOrCustomEmojiCodec (nonemptySetCodec userId))
        |> Codec.field "gameType" .gameType gameTypeCodec
        |> Codec.field "timestampDrawings" .timestampDrawings drawingCodec
        |> Codec.field "cardDrawings" .cardDrawings drawingCodec
        |> Codec.buildObject


gameTypeCodec : Codec GameType
gameTypeCodec =
    Codec.custom
        (\gameType_GoEncoder gameType_WordSpellingGameEncoder gameType_SheepGameEncoder value ->
            case value of
                Message.GameType_Go ->
                    gameType_GoEncoder

                Message.GameType_WordSpellingGame ->
                    gameType_WordSpellingGameEncoder

                Message.GameType_SheepGame ->
                    gameType_SheepGameEncoder
        )
        |> Codec.variant0 "GameType_Go" Message.GameType_Go
        |> Codec.variant0 "GameType_WordSpellingGame" Message.GameType_WordSpellingGame
        |> Codec.variant0 "GameType_SheepGame" Message.GameType_SheepGame
        |> Codec.buildCustom


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


sessionIdHashCodec : Codec SessionIdHash.SessionIdHash
sessionIdHashCodec =
    Codec.custom
        (\sessionIdHashEncoder value ->
            case value of
                SessionIdHash.SessionIdHash argA ->
                    sessionIdHashEncoder argA
        )
        |> Codec.variant1 "SessionIdHash" SessionIdHash.SessionIdHash Codec.string
        |> Codec.buildCustom


e2eeEnabledDataCodec : Codec DmChannel.E2eeEnabledData
e2eeEnabledDataCodec =
    Codec.object DmChannel.E2eeEnabledData
        |> Codec.field "enabledAt" .enabledAt CodecExtra.time
        |> Codec.field "requestedBy" .requestedBy (Codec.tuple idCodec sessionIdHashCodec)
        |> Codec.buildObject


discordGuildChannelCodec : Codec DiscordGuildChannel
discordGuildChannelCodec =
    Codec.object DiscordGuildChannel
        |> Codec.field "name" .name channelNameCodec
        |> Codec.field "description" .description channelDescriptionCodec
        |> Codec.field "isForum" .isForum Codec.bool
        |> Codec.field "messages" .messages (idArrayCodec (messageCodec idCodec))
        |> Codec.field "status" .status channelStatusCodec
        |> Codec.field "threads" .threads (seqDictCodec idCodec backendThreadCodec)
        |> Codec.field "dateDividerDrawings" .dateDividerDrawings (seqDictCodec dateCodec (drawingCodec idCodec))
        |> Codec.field "permissionOverwrites" .permissionOverwrites (Codec.list overwriteCodec)
        |> Codec.buildObject


overwriteCodec : Codec Discord.Overwrite
overwriteCodec =
    Codec.object Discord.Overwrite
        |> Codec.field "id" .id roleOrUserIdCodec
        |> Codec.field "allow" .allow permissionsCodec
        |> Codec.field "deny" .deny permissionsCodec
        |> Codec.buildObject


roleOrUserIdCodec : Codec Discord.RoleOrUserId
roleOrUserIdCodec =
    Codec.custom
        (\roleOrUserId_RoleIdEncoder roleOrUserId_UserIdEncoder value ->
            case value of
                Discord.RoleOrUserId_RoleId argA ->
                    roleOrUserId_RoleIdEncoder argA

                Discord.RoleOrUserId_UserId argA ->
                    roleOrUserId_UserIdEncoder argA
        )
        |> Codec.variant1 "RoleOrUserId_RoleId" Discord.RoleOrUserId_RoleId idCodec
        |> Codec.variant1 "RoleOrUserId_UserId" Discord.RoleOrUserId_UserId idCodec
        |> Codec.buildCustom


idCodec : Codec (Discord.Id idType)
idCodec =
    Codec.custom
        (\idEncoder value ->
            case value of
                Discord.Id argA ->
                    idEncoder argA
        )
        |> Codec.variant1 "Id" Discord.Id uInt64Codec
        |> Codec.buildCustom


uInt64Codec : Codec UInt64.UInt64
uInt64Codec =
    Debug.todo
        "Could not automatically generate a definition for `UInt64.UInt64`, as we don't know how to implement this type."


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


discordDmChannelCodec : Codec DiscordDmChannel
discordDmChannelCodec =
    Codec.object DiscordDmChannel
        |> Codec.field "messages" .messages (idArrayCodec (messageCodec idCodec))
        |> Codec.field
            "members"
            .members
            (nonemptyDictCodec
                idCodec
                (Codec.object (\messagesSent -> { messagesSent = messagesSent })
                    |> Codec.field "messagesSent" .messagesSent Codec.int
                    |> Codec.buildObject
                )
            )
        |> Codec.field "dateDividerDrawings" .dateDividerDrawings (seqDictCodec dateCodec (drawingCodec idCodec))
        |> Codec.buildObject


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
