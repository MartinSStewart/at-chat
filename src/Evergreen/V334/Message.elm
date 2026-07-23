module Evergreen.V334.Message exposing (..)

import Array
import Evergreen.V334.Drawing
import Evergreen.V334.Embed
import Evergreen.V334.Emoji
import Evergreen.V334.FileStatus
import Evergreen.V334.Id
import Evergreen.V334.NonemptySet
import Evergreen.V334.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V334.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V334.Emoji.EmojiOrCustomEmoji (Evergreen.V334.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V334.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.FileStatus.FileId) Evergreen.V334.FileStatus.FileData
    , embeds : Array.Array Evergreen.V334.Embed.Embed
    , timestampDrawings : Evergreen.V334.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V334.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.FileStatus.FileId) (Evergreen.V334.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V334.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V334.Emoji.EmojiOrCustomEmoji (Evergreen.V334.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V334.Drawing.Drawing userId
    , cardDrawings : Evergreen.V334.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V334.Emoji.EmojiOrCustomEmoji (Evergreen.V334.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V334.Drawing.Drawing userId
    , cardDrawings : Evergreen.V334.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V334.Emoji.EmojiOrCustomEmoji (Evergreen.V334.NonemptySet.NonemptySet userId)) (Evergreen.V334.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
