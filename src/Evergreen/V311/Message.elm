module Evergreen.V311.Message exposing (..)

import Array
import Evergreen.V311.Drawing
import Evergreen.V311.Embed
import Evergreen.V311.Emoji
import Evergreen.V311.FileStatus
import Evergreen.V311.Id
import Evergreen.V311.NonemptySet
import Evergreen.V311.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V311.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V311.Emoji.EmojiOrCustomEmoji (Evergreen.V311.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V311.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) Evergreen.V311.FileStatus.FileData
    , embeds : Array.Array Evergreen.V311.Embed.Embed
    , timestampDrawings : Evergreen.V311.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V311.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.FileStatus.FileId) (Evergreen.V311.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V311.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V311.Emoji.EmojiOrCustomEmoji (Evergreen.V311.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V311.Drawing.Drawing userId
    , cardDrawings : Evergreen.V311.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V311.Emoji.EmojiOrCustomEmoji (Evergreen.V311.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V311.Drawing.Drawing userId
    , cardDrawings : Evergreen.V311.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V311.Emoji.EmojiOrCustomEmoji (Evergreen.V311.NonemptySet.NonemptySet userId)) (Evergreen.V311.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
