module Evergreen.V412.Message exposing (..)

import Array
import Evergreen.V412.Drawing
import Evergreen.V412.Embed
import Evergreen.V412.Emoji
import Evergreen.V412.Encryption
import Evergreen.V412.FileStatus
import Evergreen.V412.Id
import Evergreen.V412.NonemptySet
import Evergreen.V412.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V412.Id.Id Evergreen.V412.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V412.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V412.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) Evergreen.V412.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V412.Id.Id messageId)
    | RepliedToGame (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V412.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V412.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId) (Evergreen.V412.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V412.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V412.Emoji.EmojiOrCustomEmoji (Evergreen.V412.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V412.Encryption.EncryptedData (MessageContent userId (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V412.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V412.Emoji.EmojiOrCustomEmoji (Evergreen.V412.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V412.Emoji.EmojiOrCustomEmoji (Evergreen.V412.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V412.Drawing.Drawing userId
    , cardDrawings : Evergreen.V412.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V412.Emoji.EmojiOrCustomEmoji (Evergreen.V412.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V412.Drawing.Drawing userId
    , cardDrawings : Evergreen.V412.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V412.Emoji.EmojiOrCustomEmoji (Evergreen.V412.NonemptySet.NonemptySet userId)) (Evergreen.V412.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V412.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelMessageId) (Maybe (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId))
