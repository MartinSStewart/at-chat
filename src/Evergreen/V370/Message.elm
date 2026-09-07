module Evergreen.V370.Message exposing (..)

import Array
import Evergreen.V370.Drawing
import Evergreen.V370.Embed
import Evergreen.V370.Emoji
import Evergreen.V370.Encryption
import Evergreen.V370.FileStatus
import Evergreen.V370.Id
import Evergreen.V370.NonemptySet
import Evergreen.V370.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId =
    { content : List.Nonempty.Nonempty (Evergreen.V370.RichText.RichText userId)
    , embeds : Array.Array Evergreen.V370.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) Evergreen.V370.FileStatus.FileData
    }


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V370.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V370.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V370.Id.Id Evergreen.V370.FileStatus.FileId) (Evergreen.V370.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V370.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId
    , reactions : SeqDict.SeqDict Evergreen.V370.Emoji.EmojiOrCustomEmoji (Evergreen.V370.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V370.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V370.Encryption.EncryptedData (MessageContent userId)
    , fileHashes : SeqSet.SeqSet Evergreen.V370.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V370.Emoji.EmojiOrCustomEmoji (Evergreen.V370.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V370.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V370.Emoji.EmojiOrCustomEmoji (Evergreen.V370.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V370.Drawing.Drawing userId
    , cardDrawings : Evergreen.V370.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V370.Emoji.EmojiOrCustomEmoji (Evergreen.V370.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V370.Drawing.Drawing userId
    , cardDrawings : Evergreen.V370.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V370.Emoji.EmojiOrCustomEmoji (Evergreen.V370.NonemptySet.NonemptySet userId)) (Evergreen.V370.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
