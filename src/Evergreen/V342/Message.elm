module Evergreen.V342.Message exposing (..)

import Array
import Evergreen.V342.Drawing
import Evergreen.V342.Embed
import Evergreen.V342.Emoji
import Evergreen.V342.FileStatus
import Evergreen.V342.Id
import Evergreen.V342.NonemptySet
import Evergreen.V342.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V342.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V342.Emoji.EmojiOrCustomEmoji (Evergreen.V342.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V342.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) Evergreen.V342.FileStatus.FileData
    , embeds : Array.Array Evergreen.V342.Embed.Embed
    , timestampDrawings : Evergreen.V342.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V342.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V342.Id.Id Evergreen.V342.FileStatus.FileId) (Evergreen.V342.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V342.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V342.Emoji.EmojiOrCustomEmoji (Evergreen.V342.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V342.Drawing.Drawing userId
    , cardDrawings : Evergreen.V342.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V342.Emoji.EmojiOrCustomEmoji (Evergreen.V342.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V342.Drawing.Drawing userId
    , cardDrawings : Evergreen.V342.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V342.Emoji.EmojiOrCustomEmoji (Evergreen.V342.NonemptySet.NonemptySet userId)) (Evergreen.V342.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
