module Evergreen.V425.Message exposing (..)

import Array
import Evergreen.V425.Drawing
import Evergreen.V425.Embed
import Evergreen.V425.Emoji
import Evergreen.V425.Encryption
import Evergreen.V425.FileStatus
import Evergreen.V425.Id
import Evergreen.V425.NonemptySet
import Evergreen.V425.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V425.Id.Id Evergreen.V425.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V425.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V425.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.Attachment
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V425.Id.Id messageId)
    | RepliedToGame (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V425.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V425.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) (Evergreen.V425.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V425.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V425.Emoji.EmojiOrCustomEmoji (Evergreen.V425.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V425.Encryption.EncryptedData (MessageContent userId (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V425.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V425.Emoji.EmojiOrCustomEmoji (Evergreen.V425.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallRecordingFile userId =
    { recordedBy : userId
    , name : String
    , startedAt : Time.Posix
    , endedAt : Time.Posix
    , size : Int
    , uploaded : Int
    }


type alias CallRecordingZip =
    { fileHash : Evergreen.V425.FileStatus.FileHash
    , size : Int
    , fileCount : Int
    }


type alias CallRecording userId =
    { startedAt : Time.Posix
    , participants : Evergreen.V425.NonemptySet.NonemptySet userId
    , files : List (CallRecordingFile userId)
    , finishedUploading : SeqSet.SeqSet userId
    , zip : Maybe CallRecordingZip
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , joinedBy : SeqSet.SeqSet userId
    , reactions : SeqDict.SeqDict Evergreen.V425.Emoji.EmojiOrCustomEmoji (Evergreen.V425.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V425.Drawing.Drawing userId
    , cardDrawings : Evergreen.V425.Drawing.Drawing userId
    , recordings : Maybe (CallRecording userId)
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V425.Emoji.EmojiOrCustomEmoji (Evergreen.V425.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V425.Drawing.Drawing userId
    , cardDrawings : Evergreen.V425.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V425.Emoji.EmojiOrCustomEmoji (Evergreen.V425.NonemptySet.NonemptySet userId)) (Evergreen.V425.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V425.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelMessageId) (Maybe (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId))


type ChangeAttachments
    = ChangeAttachments (SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId) Evergreen.V425.FileStatus.Attachment)
    | DoNotChangeAttachments
