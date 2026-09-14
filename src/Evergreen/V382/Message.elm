module Evergreen.V382.Message exposing (..)

import Array
import Evergreen.V382.Drawing
import Evergreen.V382.Embed
import Evergreen.V382.Emoji
import Evergreen.V382.Encryption
import Evergreen.V382.FileStatus
import Evergreen.V382.Id
import Evergreen.V382.NonemptySet
import Evergreen.V382.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId =
    { content : List.Nonempty.Nonempty (Evergreen.V382.RichText.RichText userId)
    , embeds : Array.Array Evergreen.V382.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) Evergreen.V382.FileStatus.FileData
    }


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V382.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V382.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId) (Evergreen.V382.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V382.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId
    , reactions : SeqDict.SeqDict Evergreen.V382.Emoji.EmojiOrCustomEmoji (Evergreen.V382.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V382.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V382.Encryption.EncryptedData (MessageContent userId)
    , fileHashes : SeqSet.SeqSet Evergreen.V382.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V382.Emoji.EmojiOrCustomEmoji (Evergreen.V382.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V382.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V382.Emoji.EmojiOrCustomEmoji (Evergreen.V382.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V382.Drawing.Drawing userId
    , cardDrawings : Evergreen.V382.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V382.Emoji.EmojiOrCustomEmoji (Evergreen.V382.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V382.Drawing.Drawing userId
    , cardDrawings : Evergreen.V382.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V382.Emoji.EmojiOrCustomEmoji (Evergreen.V382.NonemptySet.NonemptySet userId)) (Evergreen.V382.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
