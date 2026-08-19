module Evergreen.V358.Message exposing (..)

import Array
import Evergreen.V358.Drawing
import Evergreen.V358.Embed
import Evergreen.V358.Emoji
import Evergreen.V358.FileStatus
import Evergreen.V358.Id
import Evergreen.V358.NonemptySet
import Evergreen.V358.RichText
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
    , content : List.Nonempty.Nonempty (Evergreen.V358.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V358.Emoji.EmojiOrCustomEmoji (Evergreen.V358.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V358.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) Evergreen.V358.FileStatus.FileData
    , embeds : Array.Array Evergreen.V358.Embed.Embed
    , timestampDrawings : Evergreen.V358.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V358.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V358.Id.Id Evergreen.V358.FileStatus.FileId) (Evergreen.V358.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V358.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V358.Emoji.EmojiOrCustomEmoji (Evergreen.V358.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V358.Drawing.Drawing userId
    , cardDrawings : Evergreen.V358.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V358.Emoji.EmojiOrCustomEmoji (Evergreen.V358.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V358.Drawing.Drawing userId
    , cardDrawings : Evergreen.V358.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V358.Emoji.EmojiOrCustomEmoji (Evergreen.V358.NonemptySet.NonemptySet userId)) (Evergreen.V358.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
