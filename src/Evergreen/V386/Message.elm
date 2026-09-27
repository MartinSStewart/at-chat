module Evergreen.V386.Message exposing (..)

import Array
import Evergreen.V386.Drawing
import Evergreen.V386.Embed
import Evergreen.V386.Emoji
import Evergreen.V386.Encryption
import Evergreen.V386.FileStatus
import Evergreen.V386.Id
import Evergreen.V386.NonemptySet
import Evergreen.V386.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type RepliedToGame
    = RepliedTo_WordSpellingGameMove Int
    | RepliedTo_SheepGameAnswer (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)
    | RepliedTo_SheepGameNotes (Evergreen.V386.Id.Id Evergreen.V386.Id.QuestionId)


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId channelId =
    { content : List.Nonempty.Nonempty (Evergreen.V386.RichText.RichText userId channelId)
    , embeds : Array.Array Evergreen.V386.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) Evergreen.V386.FileStatus.FileData
    }


type RepliedTo messageId
    = NoReply
    | RepliedToMessage (Evergreen.V386.Id.Id messageId)
    | RepliedToGame (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) RepliedToGame


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V386.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V386.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId) (Evergreen.V386.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V386.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId channelId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId channelId
    , reactions : SeqDict.SeqDict Evergreen.V386.Emoji.EmojiOrCustomEmoji (Evergreen.V386.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V386.Encryption.EncryptedData (MessageContent userId (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelId))
    , fileHashes : SeqSet.SeqSet Evergreen.V386.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V386.Emoji.EmojiOrCustomEmoji (Evergreen.V386.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : RepliedTo messageId
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V386.Emoji.EmojiOrCustomEmoji (Evergreen.V386.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V386.Drawing.Drawing userId
    , cardDrawings : Evergreen.V386.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V386.Emoji.EmojiOrCustomEmoji (Evergreen.V386.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V386.Drawing.Drawing userId
    , cardDrawings : Evergreen.V386.Drawing.Drawing userId
    }


type Message messageId userId channelId
    = UserTextMessage (UserTextMessageData messageId userId channelId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V386.Emoji.EmojiOrCustomEmoji (Evergreen.V386.NonemptySet.NonemptySet userId)) (Evergreen.V386.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type ThreadRouteWithRepliedTo
    = NoThreadWithRepliedTo (RepliedTo Evergreen.V386.Id.ChannelMessageId)
    | ViewThreadWithRepliedTo (Evergreen.V386.Id.Id Evergreen.V386.Id.ChannelMessageId) (Maybe (Evergreen.V386.Id.Id Evergreen.V386.Id.ThreadMessageId))
