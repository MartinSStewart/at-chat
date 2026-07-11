module Evergreen.V313.Message exposing (..)

import Array
import Evergreen.V313.Drawing
import Evergreen.V313.Embed
import Evergreen.V313.Emoji
import Evergreen.V313.FileStatus
import Evergreen.V313.Id
import Evergreen.V313.NonemptySet
import Evergreen.V313.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V313.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V313.Emoji.EmojiOrCustomEmoji (Evergreen.V313.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V313.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) Evergreen.V313.FileStatus.FileData
    , embeds : Array.Array Evergreen.V313.Embed.Embed
    , timestampDrawings : Evergreen.V313.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V313.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.FileStatus.FileId) (Evergreen.V313.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V313.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V313.Emoji.EmojiOrCustomEmoji (Evergreen.V313.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V313.Drawing.Drawing userId
    , cardDrawings : Evergreen.V313.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V313.Emoji.EmojiOrCustomEmoji (Evergreen.V313.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V313.Drawing.Drawing userId
    , cardDrawings : Evergreen.V313.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V313.Emoji.EmojiOrCustomEmoji (Evergreen.V313.NonemptySet.NonemptySet userId)) (Evergreen.V313.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
