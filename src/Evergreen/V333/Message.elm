module Evergreen.V333.Message exposing (..)

import Array
import Evergreen.V333.Drawing
import Evergreen.V333.Embed
import Evergreen.V333.Emoji
import Evergreen.V333.FileStatus
import Evergreen.V333.Id
import Evergreen.V333.NonemptySet
import Evergreen.V333.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V333.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V333.Emoji.EmojiOrCustomEmoji (Evergreen.V333.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V333.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) Evergreen.V333.FileStatus.FileData
    , embeds : Array.Array Evergreen.V333.Embed.Embed
    , timestampDrawings : Evergreen.V333.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V333.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.FileStatus.FileId) (Evergreen.V333.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V333.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V333.Emoji.EmojiOrCustomEmoji (Evergreen.V333.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V333.Drawing.Drawing userId
    , cardDrawings : Evergreen.V333.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V333.Emoji.EmojiOrCustomEmoji (Evergreen.V333.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V333.Drawing.Drawing userId
    , cardDrawings : Evergreen.V333.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V333.Emoji.EmojiOrCustomEmoji (Evergreen.V333.NonemptySet.NonemptySet userId)) (Evergreen.V333.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
