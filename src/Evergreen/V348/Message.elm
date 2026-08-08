module Evergreen.V348.Message exposing (..)

import Array
import Evergreen.V348.Drawing
import Evergreen.V348.Embed
import Evergreen.V348.Emoji
import Evergreen.V348.FileStatus
import Evergreen.V348.Id
import Evergreen.V348.NonemptySet
import Evergreen.V348.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V348.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V348.Emoji.EmojiOrCustomEmoji (Evergreen.V348.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V348.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) Evergreen.V348.FileStatus.FileData
    , embeds : Array.Array Evergreen.V348.Embed.Embed
    , timestampDrawings : Evergreen.V348.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V348.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.FileStatus.FileId) (Evergreen.V348.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V348.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V348.Emoji.EmojiOrCustomEmoji (Evergreen.V348.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V348.Drawing.Drawing userId
    , cardDrawings : Evergreen.V348.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V348.Emoji.EmojiOrCustomEmoji (Evergreen.V348.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V348.Drawing.Drawing userId
    , cardDrawings : Evergreen.V348.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V348.Emoji.EmojiOrCustomEmoji (Evergreen.V348.NonemptySet.NonemptySet userId)) (Evergreen.V348.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
