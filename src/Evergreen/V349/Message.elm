module Evergreen.V349.Message exposing (..)

import Array
import Evergreen.V349.Drawing
import Evergreen.V349.Embed
import Evergreen.V349.Emoji
import Evergreen.V349.FileStatus
import Evergreen.V349.Id
import Evergreen.V349.NonemptySet
import Evergreen.V349.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V349.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V349.Emoji.EmojiOrCustomEmoji (Evergreen.V349.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V349.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) Evergreen.V349.FileStatus.FileData
    , embeds : Array.Array Evergreen.V349.Embed.Embed
    , timestampDrawings : Evergreen.V349.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V349.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.FileStatus.FileId) (Evergreen.V349.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V349.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V349.Emoji.EmojiOrCustomEmoji (Evergreen.V349.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V349.Drawing.Drawing userId
    , cardDrawings : Evergreen.V349.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V349.Emoji.EmojiOrCustomEmoji (Evergreen.V349.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V349.Drawing.Drawing userId
    , cardDrawings : Evergreen.V349.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V349.Emoji.EmojiOrCustomEmoji (Evergreen.V349.NonemptySet.NonemptySet userId)) (Evergreen.V349.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
