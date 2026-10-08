module Evergreen.V401.Message exposing (..)

import Array
import Evergreen.V401.Drawing
import Evergreen.V401.Embed
import Evergreen.V401.Emoji
import Evergreen.V401.Encryption
import Evergreen.V401.FileStatus
import Evergreen.V401.Id
import Evergreen.V401.NonemptySet
import Evergreen.V401.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V401.Id.Id Evergreen.V401.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V401.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V401.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) Evergreen.V401.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V401.Id.Id messageId)
    | RepliedToGame (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V401.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V401.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId) (Evergreen.V401.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V401.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V401.Emoji.EmojiOrCustomEmoji (Evergreen.V401.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V401.Encryption.EncryptedData (MessageContent userId (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V401.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V401.Emoji.EmojiOrCustomEmoji (Evergreen.V401.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V401.Emoji.EmojiOrCustomEmoji (Evergreen.V401.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V401.Drawing.Drawing userId
    , cardDrawings : Evergreen.V401.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V401.Emoji.EmojiOrCustomEmoji (Evergreen.V401.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V401.Drawing.Drawing userId
    , cardDrawings : Evergreen.V401.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V401.Emoji.EmojiOrCustomEmoji (Evergreen.V401.NonemptySet.NonemptySet userId)) (Evergreen.V401.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V401.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V401.Id.Id Evergreen.V401.Id.ChannelMessageId) (Maybe (Evergreen.V401.Id.Id Evergreen.V401.Id.ThreadMessageId))
