module Evergreen.V403.Message exposing (..)

import Array
import Evergreen.V403.Drawing
import Evergreen.V403.Embed
import Evergreen.V403.Emoji
import Evergreen.V403.Encryption
import Evergreen.V403.FileStatus
import Evergreen.V403.Id
import Evergreen.V403.NonemptySet
import Evergreen.V403.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V403.Id.Id Evergreen.V403.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V403.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V403.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) Evergreen.V403.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V403.Id.Id messageId)
    | RepliedToGame (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V403.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V403.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId) (Evergreen.V403.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V403.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V403.Emoji.EmojiOrCustomEmoji (Evergreen.V403.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V403.Encryption.EncryptedData (MessageContent userId (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V403.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V403.Emoji.EmojiOrCustomEmoji (Evergreen.V403.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V403.Emoji.EmojiOrCustomEmoji (Evergreen.V403.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V403.Drawing.Drawing userId
    , cardDrawings : Evergreen.V403.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V403.Emoji.EmojiOrCustomEmoji (Evergreen.V403.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V403.Drawing.Drawing userId
    , cardDrawings : Evergreen.V403.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V403.Emoji.EmojiOrCustomEmoji (Evergreen.V403.NonemptySet.NonemptySet userId)) (Evergreen.V403.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V403.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V403.Id.Id Evergreen.V403.Id.ChannelMessageId) (Maybe (Evergreen.V403.Id.Id Evergreen.V403.Id.ThreadMessageId))
