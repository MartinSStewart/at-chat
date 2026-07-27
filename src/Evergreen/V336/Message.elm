module Evergreen.V336.Message exposing (..)

import Array
import Evergreen.V336.Drawing
import Evergreen.V336.Embed
import Evergreen.V336.Emoji
import Evergreen.V336.FileStatus
import Evergreen.V336.Id
import Evergreen.V336.NonemptySet
import Evergreen.V336.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V336.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V336.Emoji.EmojiOrCustomEmoji (Evergreen.V336.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V336.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) Evergreen.V336.FileStatus.FileData
    , embeds : Array.Array Evergreen.V336.Embed.Embed
    , timestampDrawings : Evergreen.V336.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V336.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.FileStatus.FileId) (Evergreen.V336.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V336.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V336.Emoji.EmojiOrCustomEmoji (Evergreen.V336.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V336.Drawing.Drawing userId
    , cardDrawings : Evergreen.V336.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V336.Emoji.EmojiOrCustomEmoji (Evergreen.V336.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V336.Drawing.Drawing userId
    , cardDrawings : Evergreen.V336.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V336.Emoji.EmojiOrCustomEmoji (Evergreen.V336.NonemptySet.NonemptySet userId)) (Evergreen.V336.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
