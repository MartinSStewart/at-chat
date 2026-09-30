module Evergreen.V395.Message exposing (..)

import Array
import Evergreen.V395.Drawing
import Evergreen.V395.Embed
import Evergreen.V395.Emoji
import Evergreen.V395.Encryption
import Evergreen.V395.FileStatus
import Evergreen.V395.Id
import Evergreen.V395.NonemptySet
import Evergreen.V395.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V395.Id.Id Evergreen.V395.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V395.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V395.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) Evergreen.V395.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V395.Id.Id messageId)
    | RepliedToGame (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V395.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V395.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId) (Evergreen.V395.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V395.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V395.Emoji.EmojiOrCustomEmoji (Evergreen.V395.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V395.Encryption.EncryptedData (MessageContent userId (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V395.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V395.Emoji.EmojiOrCustomEmoji (Evergreen.V395.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V395.Emoji.EmojiOrCustomEmoji (Evergreen.V395.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V395.Drawing.Drawing userId
    , cardDrawings : Evergreen.V395.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V395.Emoji.EmojiOrCustomEmoji (Evergreen.V395.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V395.Drawing.Drawing userId
    , cardDrawings : Evergreen.V395.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V395.Emoji.EmojiOrCustomEmoji (Evergreen.V395.NonemptySet.NonemptySet userId)) (Evergreen.V395.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V395.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Maybe (Evergreen.V395.Id.Id Evergreen.V395.Id.ThreadMessageId))
