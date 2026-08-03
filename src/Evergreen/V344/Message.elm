module Evergreen.V344.Message exposing (..)

import Array
import Evergreen.V344.Drawing
import Evergreen.V344.Embed
import Evergreen.V344.Emoji
import Evergreen.V344.FileStatus
import Evergreen.V344.Id
import Evergreen.V344.NonemptySet
import Evergreen.V344.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V344.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V344.Emoji.EmojiOrCustomEmoji (Evergreen.V344.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V344.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) Evergreen.V344.FileStatus.FileData
    , embeds : Array.Array Evergreen.V344.Embed.Embed
    , timestampDrawings : Evergreen.V344.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V344.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V344.Id.Id Evergreen.V344.FileStatus.FileId) (Evergreen.V344.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V344.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V344.Emoji.EmojiOrCustomEmoji (Evergreen.V344.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V344.Drawing.Drawing userId
    , cardDrawings : Evergreen.V344.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V344.Emoji.EmojiOrCustomEmoji (Evergreen.V344.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V344.Drawing.Drawing userId
    , cardDrawings : Evergreen.V344.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V344.Emoji.EmojiOrCustomEmoji (Evergreen.V344.NonemptySet.NonemptySet userId)) (Evergreen.V344.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
