module Evergreen.V339.Message exposing (..)

import Array
import Evergreen.V339.Drawing
import Evergreen.V339.Embed
import Evergreen.V339.Emoji
import Evergreen.V339.FileStatus
import Evergreen.V339.Id
import Evergreen.V339.NonemptySet
import Evergreen.V339.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V339.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V339.Emoji.EmojiOrCustomEmoji (Evergreen.V339.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V339.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) Evergreen.V339.FileStatus.FileData
    , embeds : Array.Array Evergreen.V339.Embed.Embed
    , timestampDrawings : Evergreen.V339.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V339.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.FileStatus.FileId) (Evergreen.V339.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V339.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V339.Emoji.EmojiOrCustomEmoji (Evergreen.V339.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V339.Drawing.Drawing userId
    , cardDrawings : Evergreen.V339.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V339.Emoji.EmojiOrCustomEmoji (Evergreen.V339.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V339.Drawing.Drawing userId
    , cardDrawings : Evergreen.V339.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V339.Emoji.EmojiOrCustomEmoji (Evergreen.V339.NonemptySet.NonemptySet userId)) (Evergreen.V339.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
