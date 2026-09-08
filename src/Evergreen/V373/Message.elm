module Evergreen.V373.Message exposing (..)

import Array
import Evergreen.V373.Drawing
import Evergreen.V373.Embed
import Evergreen.V373.Emoji
import Evergreen.V373.Encryption
import Evergreen.V373.FileStatus
import Evergreen.V373.Id
import Evergreen.V373.NonemptySet
import Evergreen.V373.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId =
    { content : List.Nonempty.Nonempty (Evergreen.V373.RichText.RichText userId)
    , embeds : Array.Array Evergreen.V373.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) Evergreen.V373.FileStatus.FileData
    }


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V373.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V373.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V373.Id.Id Evergreen.V373.FileStatus.FileId) (Evergreen.V373.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V373.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId
    , reactions : SeqDict.SeqDict Evergreen.V373.Emoji.EmojiOrCustomEmoji (Evergreen.V373.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V373.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V373.Encryption.EncryptedData (MessageContent userId)
    , fileHashes : SeqSet.SeqSet Evergreen.V373.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V373.Emoji.EmojiOrCustomEmoji (Evergreen.V373.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V373.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V373.Emoji.EmojiOrCustomEmoji (Evergreen.V373.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V373.Drawing.Drawing userId
    , cardDrawings : Evergreen.V373.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V373.Emoji.EmojiOrCustomEmoji (Evergreen.V373.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V373.Drawing.Drawing userId
    , cardDrawings : Evergreen.V373.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V373.Emoji.EmojiOrCustomEmoji (Evergreen.V373.NonemptySet.NonemptySet userId)) (Evergreen.V373.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
