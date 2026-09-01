module Evergreen.V366.Message exposing (..)

import Array
import Evergreen.V366.Drawing
import Evergreen.V366.Embed
import Evergreen.V366.Emoji
import Evergreen.V366.FileStatus
import Evergreen.V366.Id
import Evergreen.V366.NonemptySet
import Evergreen.V366.RichText
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
    , content : List.Nonempty.Nonempty (Evergreen.V366.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V366.Emoji.EmojiOrCustomEmoji (Evergreen.V366.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V366.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) Evergreen.V366.FileStatus.FileData
    , embeds : Array.Array Evergreen.V366.Embed.Embed
    , timestampDrawings : Evergreen.V366.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V366.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.FileStatus.FileId) (Evergreen.V366.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V366.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V366.Emoji.EmojiOrCustomEmoji (Evergreen.V366.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V366.Drawing.Drawing userId
    , cardDrawings : Evergreen.V366.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V366.Emoji.EmojiOrCustomEmoji (Evergreen.V366.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V366.Drawing.Drawing userId
    , cardDrawings : Evergreen.V366.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V366.Emoji.EmojiOrCustomEmoji (Evergreen.V366.NonemptySet.NonemptySet userId)) (Evergreen.V366.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
