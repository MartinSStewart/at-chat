module Evergreen.V376.Message exposing (..)

import Array
import Evergreen.V376.Drawing
import Evergreen.V376.Embed
import Evergreen.V376.Emoji
import Evergreen.V376.Encryption
import Evergreen.V376.FileStatus
import Evergreen.V376.Id
import Evergreen.V376.NonemptySet
import Evergreen.V376.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId =
    { content : List.Nonempty.Nonempty (Evergreen.V376.RichText.RichText userId)
    , embeds : Array.Array Evergreen.V376.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) Evergreen.V376.FileStatus.FileData
    }


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V376.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V376.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V376.Id.Id Evergreen.V376.FileStatus.FileId) (Evergreen.V376.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V376.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId
    , reactions : SeqDict.SeqDict Evergreen.V376.Emoji.EmojiOrCustomEmoji (Evergreen.V376.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V376.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V376.Encryption.EncryptedData (MessageContent userId)
    , fileHashes : SeqSet.SeqSet Evergreen.V376.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V376.Emoji.EmojiOrCustomEmoji (Evergreen.V376.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V376.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V376.Emoji.EmojiOrCustomEmoji (Evergreen.V376.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V376.Drawing.Drawing userId
    , cardDrawings : Evergreen.V376.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V376.Emoji.EmojiOrCustomEmoji (Evergreen.V376.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V376.Drawing.Drawing userId
    , cardDrawings : Evergreen.V376.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V376.Emoji.EmojiOrCustomEmoji (Evergreen.V376.NonemptySet.NonemptySet userId)) (Evergreen.V376.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
