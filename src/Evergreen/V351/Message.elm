module Evergreen.V351.Message exposing (..)

import Array
import Evergreen.V351.Drawing
import Evergreen.V351.Embed
import Evergreen.V351.Emoji
import Evergreen.V351.FileStatus
import Evergreen.V351.Id
import Evergreen.V351.NonemptySet
import Evergreen.V351.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V351.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V351.Emoji.EmojiOrCustomEmoji (Evergreen.V351.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V351.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) Evergreen.V351.FileStatus.FileData
    , embeds : Array.Array Evergreen.V351.Embed.Embed
    , timestampDrawings : Evergreen.V351.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V351.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId) (Evergreen.V351.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V351.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V351.Emoji.EmojiOrCustomEmoji (Evergreen.V351.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V351.Drawing.Drawing userId
    , cardDrawings : Evergreen.V351.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V351.Emoji.EmojiOrCustomEmoji (Evergreen.V351.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V351.Drawing.Drawing userId
    , cardDrawings : Evergreen.V351.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V351.Emoji.EmojiOrCustomEmoji (Evergreen.V351.NonemptySet.NonemptySet userId)) (Evergreen.V351.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
