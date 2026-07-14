module Evergreen.V323.Message exposing (..)

import Array
import Evergreen.V323.Drawing
import Evergreen.V323.Embed
import Evergreen.V323.Emoji
import Evergreen.V323.FileStatus
import Evergreen.V323.Id
import Evergreen.V323.NonemptySet
import Evergreen.V323.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V323.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V323.Emoji.EmojiOrCustomEmoji (Evergreen.V323.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V323.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) Evergreen.V323.FileStatus.FileData
    , embeds : Array.Array Evergreen.V323.Embed.Embed
    , timestampDrawings : Evergreen.V323.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V323.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V323.Id.Id Evergreen.V323.FileStatus.FileId) (Evergreen.V323.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V323.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V323.Emoji.EmojiOrCustomEmoji (Evergreen.V323.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V323.Drawing.Drawing userId
    , cardDrawings : Evergreen.V323.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V323.Emoji.EmojiOrCustomEmoji (Evergreen.V323.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V323.Drawing.Drawing userId
    , cardDrawings : Evergreen.V323.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V323.Emoji.EmojiOrCustomEmoji (Evergreen.V323.NonemptySet.NonemptySet userId)) (Evergreen.V323.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
