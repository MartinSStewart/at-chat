module Evergreen.V367.Message exposing (..)

import Array
import Evergreen.V367.Drawing
import Evergreen.V367.Embed
import Evergreen.V367.Emoji
import Evergreen.V367.FileStatus
import Evergreen.V367.Id
import Evergreen.V367.NonemptySet
import Evergreen.V367.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V367.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V367.Emoji.EmojiOrCustomEmoji (Evergreen.V367.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V367.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) Evergreen.V367.FileStatus.FileData
    , embeds : Array.Array Evergreen.V367.Embed.Embed
    , timestampDrawings : Evergreen.V367.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V367.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.FileStatus.FileId) (Evergreen.V367.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V367.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V367.Emoji.EmojiOrCustomEmoji (Evergreen.V367.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V367.Drawing.Drawing userId
    , cardDrawings : Evergreen.V367.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V367.Emoji.EmojiOrCustomEmoji (Evergreen.V367.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V367.Drawing.Drawing userId
    , cardDrawings : Evergreen.V367.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V367.Emoji.EmojiOrCustomEmoji (Evergreen.V367.NonemptySet.NonemptySet userId)) (Evergreen.V367.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
