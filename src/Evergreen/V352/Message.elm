module Evergreen.V352.Message exposing (..)

import Array
import Evergreen.V352.Drawing
import Evergreen.V352.Embed
import Evergreen.V352.Emoji
import Evergreen.V352.FileStatus
import Evergreen.V352.Id
import Evergreen.V352.NonemptySet
import Evergreen.V352.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V352.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V352.Emoji.EmojiOrCustomEmoji (Evergreen.V352.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V352.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) Evergreen.V352.FileStatus.FileData
    , embeds : Array.Array Evergreen.V352.Embed.Embed
    , timestampDrawings : Evergreen.V352.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V352.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V352.Id.Id Evergreen.V352.FileStatus.FileId) (Evergreen.V352.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V352.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V352.Emoji.EmojiOrCustomEmoji (Evergreen.V352.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V352.Drawing.Drawing userId
    , cardDrawings : Evergreen.V352.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V352.Emoji.EmojiOrCustomEmoji (Evergreen.V352.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V352.Drawing.Drawing userId
    , cardDrawings : Evergreen.V352.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V352.Emoji.EmojiOrCustomEmoji (Evergreen.V352.NonemptySet.NonemptySet userId)) (Evergreen.V352.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
