module Evergreen.V326.Message exposing (..)

import Array
import Evergreen.V326.Drawing
import Evergreen.V326.Embed
import Evergreen.V326.Emoji
import Evergreen.V326.FileStatus
import Evergreen.V326.Id
import Evergreen.V326.NonemptySet
import Evergreen.V326.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V326.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V326.Emoji.EmojiOrCustomEmoji (Evergreen.V326.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V326.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) Evergreen.V326.FileStatus.FileData
    , embeds : Array.Array Evergreen.V326.Embed.Embed
    , timestampDrawings : Evergreen.V326.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V326.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V326.Id.Id Evergreen.V326.FileStatus.FileId) (Evergreen.V326.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V326.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V326.Emoji.EmojiOrCustomEmoji (Evergreen.V326.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V326.Drawing.Drawing userId
    , cardDrawings : Evergreen.V326.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V326.Emoji.EmojiOrCustomEmoji (Evergreen.V326.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V326.Drawing.Drawing userId
    , cardDrawings : Evergreen.V326.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V326.Emoji.EmojiOrCustomEmoji (Evergreen.V326.NonemptySet.NonemptySet userId)) (Evergreen.V326.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
