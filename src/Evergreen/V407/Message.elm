module Evergreen.V407.Message exposing (..)

import Array
import Evergreen.V407.Drawing
import Evergreen.V407.Embed
import Evergreen.V407.Emoji
import Evergreen.V407.Encryption
import Evergreen.V407.FileStatus
import Evergreen.V407.Id
import Evergreen.V407.NonemptySet
import Evergreen.V407.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V407.Id.Id Evergreen.V407.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V407.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V407.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) Evergreen.V407.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V407.Id.Id messageId)
    | RepliedToGame (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V407.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V407.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId) (Evergreen.V407.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V407.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V407.Emoji.EmojiOrCustomEmoji (Evergreen.V407.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V407.Encryption.EncryptedData (MessageContent userId (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V407.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V407.Emoji.EmojiOrCustomEmoji (Evergreen.V407.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V407.Emoji.EmojiOrCustomEmoji (Evergreen.V407.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V407.Drawing.Drawing userId
    , cardDrawings : Evergreen.V407.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V407.Emoji.EmojiOrCustomEmoji (Evergreen.V407.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V407.Drawing.Drawing userId
    , cardDrawings : Evergreen.V407.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V407.Emoji.EmojiOrCustomEmoji (Evergreen.V407.NonemptySet.NonemptySet userId)) (Evergreen.V407.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V407.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V407.Id.Id Evergreen.V407.Id.ChannelMessageId) (Maybe (Evergreen.V407.Id.Id Evergreen.V407.Id.ThreadMessageId))
