module Evergreen.V341.Message exposing (..)

import Array
import Evergreen.V341.Drawing
import Evergreen.V341.Embed
import Evergreen.V341.Emoji
import Evergreen.V341.FileStatus
import Evergreen.V341.Id
import Evergreen.V341.NonemptySet
import Evergreen.V341.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V341.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V341.Emoji.EmojiOrCustomEmoji (Evergreen.V341.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V341.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) Evergreen.V341.FileStatus.FileData
    , embeds : Array.Array Evergreen.V341.Embed.Embed
    , timestampDrawings : Evergreen.V341.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V341.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.FileStatus.FileId) (Evergreen.V341.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V341.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V341.Emoji.EmojiOrCustomEmoji (Evergreen.V341.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V341.Drawing.Drawing userId
    , cardDrawings : Evergreen.V341.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V341.Emoji.EmojiOrCustomEmoji (Evergreen.V341.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V341.Drawing.Drawing userId
    , cardDrawings : Evergreen.V341.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V341.Emoji.EmojiOrCustomEmoji (Evergreen.V341.NonemptySet.NonemptySet userId)) (Evergreen.V341.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
