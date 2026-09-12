module Evergreen.V379.Message exposing (..)

import Array
import Evergreen.V379.Drawing
import Evergreen.V379.Embed
import Evergreen.V379.Emoji
import Evergreen.V379.Encryption
import Evergreen.V379.FileStatus
import Evergreen.V379.Id
import Evergreen.V379.NonemptySet
import Evergreen.V379.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId =
    { content : List.Nonempty.Nonempty (Evergreen.V379.RichText.RichText userId)
    , embeds : Array.Array Evergreen.V379.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) Evergreen.V379.FileStatus.FileData
    }


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V379.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V379.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId) (Evergreen.V379.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V379.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId
    , reactions : SeqDict.SeqDict Evergreen.V379.Emoji.EmojiOrCustomEmoji (Evergreen.V379.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V379.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V379.Encryption.EncryptedData (MessageContent userId)
    , fileHashes : SeqSet.SeqSet Evergreen.V379.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V379.Emoji.EmojiOrCustomEmoji (Evergreen.V379.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V379.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V379.Emoji.EmojiOrCustomEmoji (Evergreen.V379.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V379.Drawing.Drawing userId
    , cardDrawings : Evergreen.V379.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V379.Emoji.EmojiOrCustomEmoji (Evergreen.V379.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V379.Drawing.Drawing userId
    , cardDrawings : Evergreen.V379.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V379.Emoji.EmojiOrCustomEmoji (Evergreen.V379.NonemptySet.NonemptySet userId)) (Evergreen.V379.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
