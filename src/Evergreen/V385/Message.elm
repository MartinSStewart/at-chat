module Evergreen.V385.Message exposing (..)

import Array
import Evergreen.V385.Drawing
import Evergreen.V385.Embed
import Evergreen.V385.Emoji
import Evergreen.V385.Encryption
import Evergreen.V385.FileStatus
import Evergreen.V385.Id
import Evergreen.V385.NonemptySet
import Evergreen.V385.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V385.Id.Id Evergreen.V385.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId =
    { content : List.Nonempty.Nonempty (Evergreen.V385.RichText.RichText userId)
    , embeds : Array.Array Evergreen.V385.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) Evergreen.V385.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V385.Id.Id messageId)
    | RepliedToGame (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V385.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V385.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId) (Evergreen.V385.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V385.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId
    , reactions : SeqDict.SeqDict Evergreen.V385.Emoji.EmojiOrCustomEmoji (Evergreen.V385.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V385.Encryption.EncryptedData (MessageContent userId)
    , fileHashes : SeqSet.SeqSet Evergreen.V385.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V385.Emoji.EmojiOrCustomEmoji (Evergreen.V385.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V385.Emoji.EmojiOrCustomEmoji (Evergreen.V385.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V385.Drawing.Drawing userId
    , cardDrawings : Evergreen.V385.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V385.Emoji.EmojiOrCustomEmoji (Evergreen.V385.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V385.Drawing.Drawing userId
    , cardDrawings : Evergreen.V385.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V385.Emoji.EmojiOrCustomEmoji (Evergreen.V385.NonemptySet.NonemptySet userId)) (Evergreen.V385.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V385.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Maybe (Evergreen.V385.Id.Id Evergreen.V385.Id.ThreadMessageId))
