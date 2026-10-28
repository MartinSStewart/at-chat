module Evergreen.V419.Message exposing (..)

import Array
import Evergreen.V419.Drawing
import Evergreen.V419.Embed
import Evergreen.V419.Emoji
import Evergreen.V419.Encryption
import Evergreen.V419.FileStatus
import Evergreen.V419.Id
import Evergreen.V419.NonemptySet
import Evergreen.V419.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V419.Id.Id Evergreen.V419.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V419.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V419.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) Evergreen.V419.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V419.Id.Id messageId)
    | RepliedToGame (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V419.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V419.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId) (Evergreen.V419.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V419.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V419.Emoji.EmojiOrCustomEmoji (Evergreen.V419.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V419.Encryption.EncryptedData (MessageContent userId (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V419.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V419.Emoji.EmojiOrCustomEmoji (Evergreen.V419.NonemptySet.NonemptySet userId)
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
    { fileHash : Evergreen.V419.FileStatus.FileHash
    , size : Int
    , fileCount : Int
    }


type alias CallRecording userId =
    { startedAt : Time.Posix
    , participants : Evergreen.V419.NonemptySet.NonemptySet userId
    , files : List (CallRecordingFile userId)
    , finishedUploading : SeqSet.SeqSet userId
    , zip : Maybe CallRecordingZip
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , joinedBy : SeqSet.SeqSet userId
    , reactions : SeqDict.SeqDict Evergreen.V419.Emoji.EmojiOrCustomEmoji (Evergreen.V419.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V419.Drawing.Drawing userId
    , cardDrawings : Evergreen.V419.Drawing.Drawing userId
    , recordings : Maybe (CallRecording userId)
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V419.Emoji.EmojiOrCustomEmoji (Evergreen.V419.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V419.Drawing.Drawing userId
    , cardDrawings : Evergreen.V419.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V419.Emoji.EmojiOrCustomEmoji (Evergreen.V419.NonemptySet.NonemptySet userId)) (Evergreen.V419.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V419.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelMessageId) (Maybe (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId))
