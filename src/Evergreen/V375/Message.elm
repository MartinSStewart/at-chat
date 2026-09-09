module Evergreen.V375.Message exposing (..)

import Array
import Evergreen.V375.Drawing
import Evergreen.V375.Embed
import Evergreen.V375.Emoji
import Evergreen.V375.Encryption
import Evergreen.V375.FileStatus
import Evergreen.V375.Id
import Evergreen.V375.NonemptySet
import Evergreen.V375.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId =
    { content : List.Nonempty.Nonempty (Evergreen.V375.RichText.RichText userId)
    , embeds : Array.Array Evergreen.V375.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) Evergreen.V375.FileStatus.FileData
    }


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V375.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V375.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.FileStatus.FileId) (Evergreen.V375.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V375.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId
    , reactions : SeqDict.SeqDict Evergreen.V375.Emoji.EmojiOrCustomEmoji (Evergreen.V375.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V375.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V375.Encryption.EncryptedData (MessageContent userId)
    , fileHashes : SeqSet.SeqSet Evergreen.V375.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V375.Emoji.EmojiOrCustomEmoji (Evergreen.V375.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V375.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V375.Emoji.EmojiOrCustomEmoji (Evergreen.V375.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V375.Drawing.Drawing userId
    , cardDrawings : Evergreen.V375.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V375.Emoji.EmojiOrCustomEmoji (Evergreen.V375.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V375.Drawing.Drawing userId
    , cardDrawings : Evergreen.V375.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V375.Emoji.EmojiOrCustomEmoji (Evergreen.V375.NonemptySet.NonemptySet userId)) (Evergreen.V375.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
