module Evergreen.V409.Message exposing (..)

import Array
import Evergreen.V409.Drawing
import Evergreen.V409.Embed
import Evergreen.V409.Emoji
import Evergreen.V409.Encryption
import Evergreen.V409.FileStatus
import Evergreen.V409.Id
import Evergreen.V409.NonemptySet
import Evergreen.V409.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V409.Id.Id Evergreen.V409.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V409.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V409.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) Evergreen.V409.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V409.Id.Id messageId)
    | RepliedToGame (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V409.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V409.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId) (Evergreen.V409.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V409.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V409.Emoji.EmojiOrCustomEmoji (Evergreen.V409.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V409.Encryption.EncryptedData (MessageContent userId (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V409.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V409.Emoji.EmojiOrCustomEmoji (Evergreen.V409.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V409.Emoji.EmojiOrCustomEmoji (Evergreen.V409.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V409.Drawing.Drawing userId
    , cardDrawings : Evergreen.V409.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V409.Emoji.EmojiOrCustomEmoji (Evergreen.V409.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V409.Drawing.Drawing userId
    , cardDrawings : Evergreen.V409.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V409.Emoji.EmojiOrCustomEmoji (Evergreen.V409.NonemptySet.NonemptySet userId)) (Evergreen.V409.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V409.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V409.Id.Id Evergreen.V409.Id.ChannelMessageId) (Maybe (Evergreen.V409.Id.Id Evergreen.V409.Id.ThreadMessageId))
