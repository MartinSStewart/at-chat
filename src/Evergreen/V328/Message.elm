module Evergreen.V328.Message exposing (..)

import Array
import Evergreen.V328.Drawing
import Evergreen.V328.Embed
import Evergreen.V328.Emoji
import Evergreen.V328.FileStatus
import Evergreen.V328.Id
import Evergreen.V328.NonemptySet
import Evergreen.V328.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V328.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V328.Emoji.EmojiOrCustomEmoji (Evergreen.V328.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V328.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.FileStatus.FileId) Evergreen.V328.FileStatus.FileData
    , embeds : Array.Array Evergreen.V328.Embed.Embed
    , timestampDrawings : Evergreen.V328.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V328.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.FileStatus.FileId) (Evergreen.V328.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V328.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V328.Emoji.EmojiOrCustomEmoji (Evergreen.V328.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V328.Drawing.Drawing userId
    , cardDrawings : Evergreen.V328.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V328.Emoji.EmojiOrCustomEmoji (Evergreen.V328.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V328.Drawing.Drawing userId
    , cardDrawings : Evergreen.V328.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V328.Emoji.EmojiOrCustomEmoji (Evergreen.V328.NonemptySet.NonemptySet userId)) (Evergreen.V328.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
