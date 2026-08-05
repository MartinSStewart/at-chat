module Evergreen.V345.Message exposing (..)

import Array
import Evergreen.V345.Drawing
import Evergreen.V345.Embed
import Evergreen.V345.Emoji
import Evergreen.V345.FileStatus
import Evergreen.V345.Id
import Evergreen.V345.NonemptySet
import Evergreen.V345.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V345.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V345.Emoji.EmojiOrCustomEmoji (Evergreen.V345.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V345.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) Evergreen.V345.FileStatus.FileData
    , embeds : Array.Array Evergreen.V345.Embed.Embed
    , timestampDrawings : Evergreen.V345.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V345.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.FileStatus.FileId) (Evergreen.V345.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V345.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V345.Emoji.EmojiOrCustomEmoji (Evergreen.V345.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V345.Drawing.Drawing userId
    , cardDrawings : Evergreen.V345.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V345.Emoji.EmojiOrCustomEmoji (Evergreen.V345.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V345.Drawing.Drawing userId
    , cardDrawings : Evergreen.V345.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V345.Emoji.EmojiOrCustomEmoji (Evergreen.V345.NonemptySet.NonemptySet userId)) (Evergreen.V345.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
