module Evergreen.V327.Message exposing (..)

import Array
import Evergreen.V327.Drawing
import Evergreen.V327.Embed
import Evergreen.V327.Emoji
import Evergreen.V327.FileStatus
import Evergreen.V327.Id
import Evergreen.V327.NonemptySet
import Evergreen.V327.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V327.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V327.Emoji.EmojiOrCustomEmoji (Evergreen.V327.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V327.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) Evergreen.V327.FileStatus.FileData
    , embeds : Array.Array Evergreen.V327.Embed.Embed
    , timestampDrawings : Evergreen.V327.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V327.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.FileStatus.FileId) (Evergreen.V327.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V327.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V327.Emoji.EmojiOrCustomEmoji (Evergreen.V327.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V327.Drawing.Drawing userId
    , cardDrawings : Evergreen.V327.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V327.Emoji.EmojiOrCustomEmoji (Evergreen.V327.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V327.Drawing.Drawing userId
    , cardDrawings : Evergreen.V327.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V327.Emoji.EmojiOrCustomEmoji (Evergreen.V327.NonemptySet.NonemptySet userId)) (Evergreen.V327.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
