module Evergreen.V346.Message exposing (..)

import Array
import Evergreen.V346.Drawing
import Evergreen.V346.Embed
import Evergreen.V346.Emoji
import Evergreen.V346.FileStatus
import Evergreen.V346.Id
import Evergreen.V346.NonemptySet
import Evergreen.V346.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V346.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V346.Emoji.EmojiOrCustomEmoji (Evergreen.V346.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V346.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) Evergreen.V346.FileStatus.FileData
    , embeds : Array.Array Evergreen.V346.Embed.Embed
    , timestampDrawings : Evergreen.V346.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V346.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.FileStatus.FileId) (Evergreen.V346.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V346.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V346.Emoji.EmojiOrCustomEmoji (Evergreen.V346.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V346.Drawing.Drawing userId
    , cardDrawings : Evergreen.V346.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V346.Emoji.EmojiOrCustomEmoji (Evergreen.V346.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V346.Drawing.Drawing userId
    , cardDrawings : Evergreen.V346.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V346.Emoji.EmojiOrCustomEmoji (Evergreen.V346.NonemptySet.NonemptySet userId)) (Evergreen.V346.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
