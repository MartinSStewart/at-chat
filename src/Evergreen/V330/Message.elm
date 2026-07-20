module Evergreen.V330.Message exposing (..)

import Array
import Evergreen.V330.Drawing
import Evergreen.V330.Embed
import Evergreen.V330.Emoji
import Evergreen.V330.FileStatus
import Evergreen.V330.Id
import Evergreen.V330.NonemptySet
import Evergreen.V330.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V330.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V330.Emoji.EmojiOrCustomEmoji (Evergreen.V330.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V330.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) Evergreen.V330.FileStatus.FileData
    , embeds : Array.Array Evergreen.V330.Embed.Embed
    , timestampDrawings : Evergreen.V330.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V330.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.FileStatus.FileId) (Evergreen.V330.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V330.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V330.Emoji.EmojiOrCustomEmoji (Evergreen.V330.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V330.Drawing.Drawing userId
    , cardDrawings : Evergreen.V330.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V330.Emoji.EmojiOrCustomEmoji (Evergreen.V330.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V330.Drawing.Drawing userId
    , cardDrawings : Evergreen.V330.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V330.Emoji.EmojiOrCustomEmoji (Evergreen.V330.NonemptySet.NonemptySet userId)) (Evergreen.V330.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
