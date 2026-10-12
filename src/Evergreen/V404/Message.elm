module Evergreen.V404.Message exposing (..)

import Array
import Evergreen.V404.Drawing
import Evergreen.V404.Embed
import Evergreen.V404.Emoji
import Evergreen.V404.Encryption
import Evergreen.V404.FileStatus
import Evergreen.V404.Id
import Evergreen.V404.NonemptySet
import Evergreen.V404.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V404.Id.Id Evergreen.V404.Id.UserId) (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V404.Id.Id Evergreen.V404.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V404.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V404.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId) Evergreen.V404.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V404.Id.Id messageId)
    | RepliedToGame (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V404.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V404.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId) (Evergreen.V404.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V404.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V404.Emoji.EmojiOrCustomEmoji (Evergreen.V404.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V404.Encryption.EncryptedData (MessageContent userId (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V404.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V404.Emoji.EmojiOrCustomEmoji (Evergreen.V404.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V404.Emoji.EmojiOrCustomEmoji (Evergreen.V404.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V404.Drawing.Drawing userId
    , cardDrawings : Evergreen.V404.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V404.Emoji.EmojiOrCustomEmoji (Evergreen.V404.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V404.Drawing.Drawing userId
    , cardDrawings : Evergreen.V404.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V404.Emoji.EmojiOrCustomEmoji (Evergreen.V404.NonemptySet.NonemptySet userId)) (Evergreen.V404.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V404.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V404.Id.Id Evergreen.V404.Id.ChannelMessageId) (Maybe (Evergreen.V404.Id.Id Evergreen.V404.Id.ThreadMessageId))
