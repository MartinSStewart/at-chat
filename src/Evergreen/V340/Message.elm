module Evergreen.V340.Message exposing (..)

import Array
import Evergreen.V340.Drawing
import Evergreen.V340.Embed
import Evergreen.V340.Emoji
import Evergreen.V340.FileStatus
import Evergreen.V340.Id
import Evergreen.V340.NonemptySet
import Evergreen.V340.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V340.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V340.Emoji.EmojiOrCustomEmoji (Evergreen.V340.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V340.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) Evergreen.V340.FileStatus.FileData
    , embeds : Array.Array Evergreen.V340.Embed.Embed
    , timestampDrawings : Evergreen.V340.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V340.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V340.Id.Id Evergreen.V340.FileStatus.FileId) (Evergreen.V340.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V340.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V340.Emoji.EmojiOrCustomEmoji (Evergreen.V340.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V340.Drawing.Drawing userId
    , cardDrawings : Evergreen.V340.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V340.Emoji.EmojiOrCustomEmoji (Evergreen.V340.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V340.Drawing.Drawing userId
    , cardDrawings : Evergreen.V340.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V340.Emoji.EmojiOrCustomEmoji (Evergreen.V340.NonemptySet.NonemptySet userId)) (Evergreen.V340.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
