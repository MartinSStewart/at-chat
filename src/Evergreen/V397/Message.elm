module Evergreen.V397.Message exposing (..)

import Array
import Evergreen.V397.Drawing
import Evergreen.V397.Embed
import Evergreen.V397.Emoji
import Evergreen.V397.Encryption
import Evergreen.V397.FileStatus
import Evergreen.V397.Id
import Evergreen.V397.NonemptySet
import Evergreen.V397.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V397.Id.Id Evergreen.V397.Id.UserId) (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V397.Id.Id Evergreen.V397.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V397.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V397.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) Evergreen.V397.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V397.Id.Id messageId)
    | RepliedToGame (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V397.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V397.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V397.Id.Id Evergreen.V397.FileStatus.FileId) (Evergreen.V397.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V397.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V397.Emoji.EmojiOrCustomEmoji (Evergreen.V397.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V397.Encryption.EncryptedData (MessageContent userId (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V397.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V397.Emoji.EmojiOrCustomEmoji (Evergreen.V397.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V397.Emoji.EmojiOrCustomEmoji (Evergreen.V397.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V397.Drawing.Drawing userId
    , cardDrawings : Evergreen.V397.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V397.Emoji.EmojiOrCustomEmoji (Evergreen.V397.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V397.Drawing.Drawing userId
    , cardDrawings : Evergreen.V397.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V397.Emoji.EmojiOrCustomEmoji (Evergreen.V397.NonemptySet.NonemptySet userId)) (Evergreen.V397.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V397.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V397.Id.Id Evergreen.V397.Id.ChannelMessageId) (Maybe (Evergreen.V397.Id.Id Evergreen.V397.Id.ThreadMessageId))
