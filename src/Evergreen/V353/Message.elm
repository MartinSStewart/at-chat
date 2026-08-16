module Evergreen.V353.Message exposing (..)

import Array
import Evergreen.V353.Drawing
import Evergreen.V353.Embed
import Evergreen.V353.Emoji
import Evergreen.V353.FileStatus
import Evergreen.V353.Id
import Evergreen.V353.NonemptySet
import Evergreen.V353.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V353.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V353.Emoji.EmojiOrCustomEmoji (Evergreen.V353.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V353.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) Evergreen.V353.FileStatus.FileData
    , embeds : Array.Array Evergreen.V353.Embed.Embed
    , timestampDrawings : Evergreen.V353.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V353.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V353.Id.Id Evergreen.V353.FileStatus.FileId) (Evergreen.V353.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V353.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V353.Emoji.EmojiOrCustomEmoji (Evergreen.V353.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V353.Drawing.Drawing userId
    , cardDrawings : Evergreen.V353.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V353.Emoji.EmojiOrCustomEmoji (Evergreen.V353.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V353.Drawing.Drawing userId
    , cardDrawings : Evergreen.V353.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V353.Emoji.EmojiOrCustomEmoji (Evergreen.V353.NonemptySet.NonemptySet userId)) (Evergreen.V353.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
