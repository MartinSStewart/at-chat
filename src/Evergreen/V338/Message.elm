module Evergreen.V338.Message exposing (..)

import Array
import Evergreen.V338.Drawing
import Evergreen.V338.Embed
import Evergreen.V338.Emoji
import Evergreen.V338.FileStatus
import Evergreen.V338.Id
import Evergreen.V338.NonemptySet
import Evergreen.V338.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V338.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V338.Emoji.EmojiOrCustomEmoji (Evergreen.V338.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V338.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) Evergreen.V338.FileStatus.FileData
    , embeds : Array.Array Evergreen.V338.Embed.Embed
    , timestampDrawings : Evergreen.V338.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V338.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.FileStatus.FileId) (Evergreen.V338.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V338.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V338.Emoji.EmojiOrCustomEmoji (Evergreen.V338.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V338.Drawing.Drawing userId
    , cardDrawings : Evergreen.V338.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V338.Emoji.EmojiOrCustomEmoji (Evergreen.V338.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V338.Drawing.Drawing userId
    , cardDrawings : Evergreen.V338.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V338.Emoji.EmojiOrCustomEmoji (Evergreen.V338.NonemptySet.NonemptySet userId)) (Evergreen.V338.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
