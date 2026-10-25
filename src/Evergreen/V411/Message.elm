module Evergreen.V411.Message exposing (..)

import Array
import Evergreen.V411.Drawing
import Evergreen.V411.Embed
import Evergreen.V411.Emoji
import Evergreen.V411.Encryption
import Evergreen.V411.FileStatus
import Evergreen.V411.Id
import Evergreen.V411.NonemptySet
import Evergreen.V411.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V411.Id.Id Evergreen.V411.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V411.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V411.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId) Evergreen.V411.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V411.Id.Id messageId)
    | RepliedToGame (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V411.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V411.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId) (Evergreen.V411.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V411.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V411.Emoji.EmojiOrCustomEmoji (Evergreen.V411.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V411.Encryption.EncryptedData (MessageContent userId (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V411.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V411.Emoji.EmojiOrCustomEmoji (Evergreen.V411.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V411.Emoji.EmojiOrCustomEmoji (Evergreen.V411.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V411.Drawing.Drawing userId
    , cardDrawings : Evergreen.V411.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V411.Emoji.EmojiOrCustomEmoji (Evergreen.V411.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V411.Drawing.Drawing userId
    , cardDrawings : Evergreen.V411.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V411.Emoji.EmojiOrCustomEmoji (Evergreen.V411.NonemptySet.NonemptySet userId)) (Evergreen.V411.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V411.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelMessageId) (Maybe (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId))
