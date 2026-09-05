module Evergreen.V368.Message exposing (..)

import Array
import Evergreen.V368.Drawing
import Evergreen.V368.Embed
import Evergreen.V368.Emoji
import Evergreen.V368.Encryption
import Evergreen.V368.FileStatus
import Evergreen.V368.Id
import Evergreen.V368.NonemptySet
import Evergreen.V368.RichText
import List.Nonempty
import SeqDict
import SeqSet
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias MessageContent userId =
    { content : List.Nonempty.Nonempty (Evergreen.V368.RichText.RichText userId)
    , embeds : Array.Array Evergreen.V368.Embed.Embed
    , attachedFiles : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) Evergreen.V368.FileStatus.FileData
    }


type alias UserTextMessageDrawings userId =
    { timestampDrawings : Evergreen.V368.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V368.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.FileStatus.FileId) (Evergreen.V368.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V368.Drawing.Drawing userId)
    }


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : MessageContent userId
    , reactions : SeqDict.SeqDict Evergreen.V368.Emoji.EmojiOrCustomEmoji (Evergreen.V368.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V368.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias EncryptedUserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : Evergreen.V368.Encryption.EncryptedData (MessageContent userId)
    , fileHashes : SeqSet.SeqSet Evergreen.V368.FileStatus.FileHash
    , reactions : SeqDict.SeqDict Evergreen.V368.Emoji.EmojiOrCustomEmoji (Evergreen.V368.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V368.Id.Id messageId)
    , drawings : Maybe (UserTextMessageDrawings userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V368.Emoji.EmojiOrCustomEmoji (Evergreen.V368.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V368.Drawing.Drawing userId
    , cardDrawings : Evergreen.V368.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V368.Emoji.EmojiOrCustomEmoji (Evergreen.V368.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V368.Drawing.Drawing userId
    , cardDrawings : Evergreen.V368.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | EncryptedUserTextMessage (EncryptedUserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V368.Emoji.EmojiOrCustomEmoji (Evergreen.V368.NonemptySet.NonemptySet userId)) (Evergreen.V368.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
