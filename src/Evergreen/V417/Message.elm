module Evergreen.V417.Message exposing (..)

import Array
import Evergreen.V417.Drawing
import Evergreen.V417.Embed
import Evergreen.V417.Emoji
import Evergreen.V417.Encryption
import Evergreen.V417.FileStatus
import Evergreen.V417.Id
import Evergreen.V417.NonemptySet
import Evergreen.V417.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V417.Id.Id Evergreen.V417.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V417.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V417.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) Evergreen.V417.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V417.Id.Id messageId)
    | RepliedToGame (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V417.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V417.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.FileStatus.FileId) (Evergreen.V417.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V417.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V417.Emoji.EmojiOrCustomEmoji (Evergreen.V417.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V417.Encryption.EncryptedData (MessageContent userId (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V417.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V417.Emoji.EmojiOrCustomEmoji (Evergreen.V417.NonemptySet.NonemptySet userId)
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
    { fileHash : Evergreen.V417.FileStatus.FileHash
    , size : Int
    , fileCount : Int
    }


type alias CallRecording userId =
    { startedAt : Time.Posix
    , participants : Evergreen.V417.NonemptySet.NonemptySet userId
    , files : List (CallRecordingFile userId)
    , finishedUploading : SeqSet.SeqSet userId
    , zip : Maybe CallRecordingZip
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , joinedBy : SeqSet.SeqSet userId
    , reactions : SeqDict.SeqDict Evergreen.V417.Emoji.EmojiOrCustomEmoji (Evergreen.V417.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V417.Drawing.Drawing userId
    , cardDrawings : Evergreen.V417.Drawing.Drawing userId
    , recordings : Maybe (CallRecording userId)
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V417.Emoji.EmojiOrCustomEmoji (Evergreen.V417.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V417.Drawing.Drawing userId
    , cardDrawings : Evergreen.V417.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V417.Emoji.EmojiOrCustomEmoji (Evergreen.V417.NonemptySet.NonemptySet userId)) (Evergreen.V417.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V417.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V417.Id.Id Evergreen.V417.Id.ChannelMessageId) (Maybe (Evergreen.V417.Id.Id Evergreen.V417.Id.ThreadMessageId))
