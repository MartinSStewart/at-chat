module Evergreen.V312.Message exposing (..)

import Array
import Evergreen.V312.Drawing
import Evergreen.V312.Embed
import Evergreen.V312.Emoji
import Evergreen.V312.FileStatus
import Evergreen.V312.Id
import Evergreen.V312.NonemptySet
import Evergreen.V312.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V312.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V312.Emoji.EmojiOrCustomEmoji (Evergreen.V312.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V312.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) Evergreen.V312.FileStatus.FileData
    , embeds : Array.Array Evergreen.V312.Embed.Embed
    , timestampDrawings : Evergreen.V312.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V312.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.FileStatus.FileId) (Evergreen.V312.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V312.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V312.Emoji.EmojiOrCustomEmoji (Evergreen.V312.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V312.Drawing.Drawing userId
    , cardDrawings : Evergreen.V312.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V312.Emoji.EmojiOrCustomEmoji (Evergreen.V312.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V312.Drawing.Drawing userId
    , cardDrawings : Evergreen.V312.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V312.Emoji.EmojiOrCustomEmoji (Evergreen.V312.NonemptySet.NonemptySet userId)) (Evergreen.V312.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
