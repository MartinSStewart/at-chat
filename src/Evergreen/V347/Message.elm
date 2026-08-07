module Evergreen.V347.Message exposing (..)

import Array
import Evergreen.V347.Drawing
import Evergreen.V347.Embed
import Evergreen.V347.Emoji
import Evergreen.V347.FileStatus
import Evergreen.V347.Id
import Evergreen.V347.NonemptySet
import Evergreen.V347.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V347.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V347.Emoji.EmojiOrCustomEmoji (Evergreen.V347.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V347.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.FileStatus.FileId) Evergreen.V347.FileStatus.FileData
    , embeds : Array.Array Evergreen.V347.Embed.Embed
    , timestampDrawings : Evergreen.V347.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V347.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.FileStatus.FileId) (Evergreen.V347.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V347.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V347.Emoji.EmojiOrCustomEmoji (Evergreen.V347.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V347.Drawing.Drawing userId
    , cardDrawings : Evergreen.V347.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V347.Emoji.EmojiOrCustomEmoji (Evergreen.V347.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V347.Drawing.Drawing userId
    , cardDrawings : Evergreen.V347.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V347.Emoji.EmojiOrCustomEmoji (Evergreen.V347.NonemptySet.NonemptySet userId)) (Evergreen.V347.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
