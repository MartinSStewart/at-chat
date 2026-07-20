module Evergreen.V332.Message exposing (..)

import Array
import Evergreen.V332.Drawing
import Evergreen.V332.Embed
import Evergreen.V332.Emoji
import Evergreen.V332.FileStatus
import Evergreen.V332.Id
import Evergreen.V332.NonemptySet
import Evergreen.V332.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V332.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V332.Emoji.EmojiOrCustomEmoji (Evergreen.V332.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V332.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) Evergreen.V332.FileStatus.FileData
    , embeds : Array.Array Evergreen.V332.Embed.Embed
    , timestampDrawings : Evergreen.V332.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V332.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.FileStatus.FileId) (Evergreen.V332.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V332.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V332.Emoji.EmojiOrCustomEmoji (Evergreen.V332.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V332.Drawing.Drawing userId
    , cardDrawings : Evergreen.V332.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V332.Emoji.EmojiOrCustomEmoji (Evergreen.V332.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V332.Drawing.Drawing userId
    , cardDrawings : Evergreen.V332.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V332.Emoji.EmojiOrCustomEmoji (Evergreen.V332.NonemptySet.NonemptySet userId)) (Evergreen.V332.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
