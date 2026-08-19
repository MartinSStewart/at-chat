module Evergreen.V359.Message exposing (..)

import Array
import Evergreen.V359.Drawing
import Evergreen.V359.Embed
import Evergreen.V359.Emoji
import Evergreen.V359.FileStatus
import Evergreen.V359.Id
import Evergreen.V359.NonemptySet
import Evergreen.V359.RichText
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
    , content : List.Nonempty.Nonempty (Evergreen.V359.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V359.Emoji.EmojiOrCustomEmoji (Evergreen.V359.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V359.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) Evergreen.V359.FileStatus.FileData
    , embeds : Array.Array Evergreen.V359.Embed.Embed
    , timestampDrawings : Evergreen.V359.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V359.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.FileStatus.FileId) (Evergreen.V359.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V359.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V359.Emoji.EmojiOrCustomEmoji (Evergreen.V359.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V359.Drawing.Drawing userId
    , cardDrawings : Evergreen.V359.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V359.Emoji.EmojiOrCustomEmoji (Evergreen.V359.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V359.Drawing.Drawing userId
    , cardDrawings : Evergreen.V359.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V359.Emoji.EmojiOrCustomEmoji (Evergreen.V359.NonemptySet.NonemptySet userId)) (Evergreen.V359.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
