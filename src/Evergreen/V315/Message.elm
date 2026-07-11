module Evergreen.V315.Message exposing (..)

import Array
import Evergreen.V315.Drawing
import Evergreen.V315.Embed
import Evergreen.V315.Emoji
import Evergreen.V315.FileStatus
import Evergreen.V315.Id
import Evergreen.V315.NonemptySet
import Evergreen.V315.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V315.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V315.Emoji.EmojiOrCustomEmoji (Evergreen.V315.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V315.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) Evergreen.V315.FileStatus.FileData
    , embeds : Array.Array Evergreen.V315.Embed.Embed
    , timestampDrawings : Evergreen.V315.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V315.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.FileStatus.FileId) (Evergreen.V315.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V315.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V315.Emoji.EmojiOrCustomEmoji (Evergreen.V315.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V315.Drawing.Drawing userId
    , cardDrawings : Evergreen.V315.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V315.Emoji.EmojiOrCustomEmoji (Evergreen.V315.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V315.Drawing.Drawing userId
    , cardDrawings : Evergreen.V315.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V315.Emoji.EmojiOrCustomEmoji (Evergreen.V315.NonemptySet.NonemptySet userId)) (Evergreen.V315.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
