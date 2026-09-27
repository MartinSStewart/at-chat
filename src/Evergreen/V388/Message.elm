module Evergreen.V388.Message exposing (..)

import Array
import Evergreen.V388.Drawing
import Evergreen.V388.Embed
import Evergreen.V388.Emoji
import Evergreen.V388.Encryption
import Evergreen.V388.FileStatus
import Evergreen.V388.Id
import Evergreen.V388.NonemptySet
import Evergreen.V388.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V388.Id.Id Evergreen.V388.Id.UserId) (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V388.Id.Id Evergreen.V388.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V388.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V388.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) Evergreen.V388.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V388.Id.Id messageId)
    | RepliedToGame (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V388.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V388.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V388.Id.Id Evergreen.V388.FileStatus.FileId) (Evergreen.V388.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V388.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V388.Emoji.EmojiOrCustomEmoji (Evergreen.V388.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V388.Encryption.EncryptedData (MessageContent userId (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V388.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V388.Emoji.EmojiOrCustomEmoji (Evergreen.V388.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V388.Emoji.EmojiOrCustomEmoji (Evergreen.V388.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V388.Drawing.Drawing userId
    , cardDrawings : Evergreen.V388.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V388.Emoji.EmojiOrCustomEmoji (Evergreen.V388.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V388.Drawing.Drawing userId
    , cardDrawings : Evergreen.V388.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V388.Emoji.EmojiOrCustomEmoji (Evergreen.V388.NonemptySet.NonemptySet userId)) (Evergreen.V388.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V388.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V388.Id.Id Evergreen.V388.Id.ChannelMessageId) (Maybe (Evergreen.V388.Id.Id Evergreen.V388.Id.ThreadMessageId))
