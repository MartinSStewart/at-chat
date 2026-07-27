module Evergreen.V335.Message exposing (..)

import Array
import Evergreen.V335.Drawing
import Evergreen.V335.Embed
import Evergreen.V335.Emoji
import Evergreen.V335.FileStatus
import Evergreen.V335.Id
import Evergreen.V335.NonemptySet
import Evergreen.V335.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V335.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V335.Emoji.EmojiOrCustomEmoji (Evergreen.V335.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V335.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) Evergreen.V335.FileStatus.FileData
    , embeds : Array.Array Evergreen.V335.Embed.Embed
    , timestampDrawings : Evergreen.V335.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V335.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V335.Id.Id Evergreen.V335.FileStatus.FileId) (Evergreen.V335.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V335.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V335.Emoji.EmojiOrCustomEmoji (Evergreen.V335.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V335.Drawing.Drawing userId
    , cardDrawings : Evergreen.V335.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V335.Emoji.EmojiOrCustomEmoji (Evergreen.V335.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V335.Drawing.Drawing userId
    , cardDrawings : Evergreen.V335.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V335.Emoji.EmojiOrCustomEmoji (Evergreen.V335.NonemptySet.NonemptySet userId)) (Evergreen.V335.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
