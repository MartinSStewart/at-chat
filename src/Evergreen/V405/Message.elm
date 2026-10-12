module Evergreen.V405.Message exposing (..)

import Array
import Evergreen.V405.Drawing
import Evergreen.V405.Embed
import Evergreen.V405.Emoji
import Evergreen.V405.Encryption
import Evergreen.V405.FileStatus
import Evergreen.V405.Id
import Evergreen.V405.NonemptySet
import Evergreen.V405.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V405.Id.Id Evergreen.V405.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V405.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V405.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) Evergreen.V405.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V405.Id.Id messageId)
    | RepliedToGame (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V405.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V405.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId) (Evergreen.V405.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V405.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V405.Emoji.EmojiOrCustomEmoji (Evergreen.V405.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V405.Encryption.EncryptedData (MessageContent userId (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V405.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V405.Emoji.EmojiOrCustomEmoji (Evergreen.V405.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V405.Emoji.EmojiOrCustomEmoji (Evergreen.V405.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V405.Drawing.Drawing userId
    , cardDrawings : Evergreen.V405.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V405.Emoji.EmojiOrCustomEmoji (Evergreen.V405.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V405.Drawing.Drawing userId
    , cardDrawings : Evergreen.V405.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V405.Emoji.EmojiOrCustomEmoji (Evergreen.V405.NonemptySet.NonemptySet userId)) (Evergreen.V405.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V405.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V405.Id.Id Evergreen.V405.Id.ChannelMessageId) (Maybe (Evergreen.V405.Id.Id Evergreen.V405.Id.ThreadMessageId))
