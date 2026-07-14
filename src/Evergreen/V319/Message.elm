module Evergreen.V319.Message exposing (..)

import Array
import Evergreen.V319.Drawing
import Evergreen.V319.Embed
import Evergreen.V319.Emoji
import Evergreen.V319.FileStatus
import Evergreen.V319.Id
import Evergreen.V319.NonemptySet
import Evergreen.V319.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V319.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V319.Emoji.EmojiOrCustomEmoji (Evergreen.V319.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V319.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) Evergreen.V319.FileStatus.FileData
    , embeds : Array.Array Evergreen.V319.Embed.Embed
    , timestampDrawings : Evergreen.V319.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V319.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V319.Id.Id Evergreen.V319.FileStatus.FileId) (Evergreen.V319.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V319.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V319.Emoji.EmojiOrCustomEmoji (Evergreen.V319.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V319.Drawing.Drawing userId
    , cardDrawings : Evergreen.V319.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V319.Emoji.EmojiOrCustomEmoji (Evergreen.V319.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V319.Drawing.Drawing userId
    , cardDrawings : Evergreen.V319.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V319.Emoji.EmojiOrCustomEmoji (Evergreen.V319.NonemptySet.NonemptySet userId)) (Evergreen.V319.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
