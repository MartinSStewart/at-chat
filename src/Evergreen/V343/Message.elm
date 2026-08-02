module Evergreen.V343.Message exposing (..)

import Array
import Evergreen.V343.Drawing
import Evergreen.V343.Embed
import Evergreen.V343.Emoji
import Evergreen.V343.FileStatus
import Evergreen.V343.Id
import Evergreen.V343.NonemptySet
import Evergreen.V343.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V343.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V343.Emoji.EmojiOrCustomEmoji (Evergreen.V343.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V343.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) Evergreen.V343.FileStatus.FileData
    , embeds : Array.Array Evergreen.V343.Embed.Embed
    , timestampDrawings : Evergreen.V343.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V343.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V343.Id.Id Evergreen.V343.FileStatus.FileId) (Evergreen.V343.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V343.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V343.Emoji.EmojiOrCustomEmoji (Evergreen.V343.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V343.Drawing.Drawing userId
    , cardDrawings : Evergreen.V343.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V343.Emoji.EmojiOrCustomEmoji (Evergreen.V343.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V343.Drawing.Drawing userId
    , cardDrawings : Evergreen.V343.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V343.Emoji.EmojiOrCustomEmoji (Evergreen.V343.NonemptySet.NonemptySet userId)) (Evergreen.V343.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
