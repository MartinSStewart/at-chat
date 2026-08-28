module Evergreen.V364.Message exposing (..)

import Array
import Evergreen.V364.Drawing
import Evergreen.V364.Embed
import Evergreen.V364.Emoji
import Evergreen.V364.FileStatus
import Evergreen.V364.Id
import Evergreen.V364.NonemptySet
import Evergreen.V364.RichText
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
    , content : List.Nonempty.Nonempty (Evergreen.V364.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V364.Emoji.EmojiOrCustomEmoji (Evergreen.V364.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V364.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) Evergreen.V364.FileStatus.FileData
    , embeds : Array.Array Evergreen.V364.Embed.Embed
    , timestampDrawings : Evergreen.V364.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V364.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.FileStatus.FileId) (Evergreen.V364.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V364.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V364.Emoji.EmojiOrCustomEmoji (Evergreen.V364.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V364.Drawing.Drawing userId
    , cardDrawings : Evergreen.V364.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V364.Emoji.EmojiOrCustomEmoji (Evergreen.V364.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V364.Drawing.Drawing userId
    , cardDrawings : Evergreen.V364.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V364.Emoji.EmojiOrCustomEmoji (Evergreen.V364.NonemptySet.NonemptySet userId)) (Evergreen.V364.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
