module Evergreen.V392.Message exposing (..)

import Array
import Evergreen.V392.Drawing
import Evergreen.V392.Embed
import Evergreen.V392.Emoji
import Evergreen.V392.Encryption
import Evergreen.V392.FileStatus
import Evergreen.V392.Id
import Evergreen.V392.NonemptySet
import Evergreen.V392.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V392.Id.Id Evergreen.V392.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V392.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V392.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) Evergreen.V392.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V392.Id.Id messageId)
    | RepliedToGame (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V392.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V392.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId) (Evergreen.V392.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V392.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V392.Emoji.EmojiOrCustomEmoji (Evergreen.V392.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V392.Encryption.EncryptedData (MessageContent userId (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V392.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V392.Emoji.EmojiOrCustomEmoji (Evergreen.V392.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V392.Emoji.EmojiOrCustomEmoji (Evergreen.V392.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V392.Drawing.Drawing userId
    , cardDrawings : Evergreen.V392.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V392.Emoji.EmojiOrCustomEmoji (Evergreen.V392.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V392.Drawing.Drawing userId
    , cardDrawings : Evergreen.V392.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V392.Emoji.EmojiOrCustomEmoji (Evergreen.V392.NonemptySet.NonemptySet userId)) (Evergreen.V392.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V392.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V392.Id.Id Evergreen.V392.Id.ChannelMessageId) (Maybe (Evergreen.V392.Id.Id Evergreen.V392.Id.ThreadMessageId))
