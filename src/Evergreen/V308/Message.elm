module Evergreen.V308.Message exposing (..)

import Array
import Evergreen.V308.Drawing
import Evergreen.V308.Embed
import Evergreen.V308.Emoji
import Evergreen.V308.FileStatus
import Evergreen.V308.Id
import Evergreen.V308.NonemptySet
import Evergreen.V308.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V308.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V308.Emoji.EmojiOrCustomEmoji (Evergreen.V308.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V308.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) Evergreen.V308.FileStatus.FileData
    , embeds : Array.Array Evergreen.V308.Embed.Embed
    , timestampDrawings : Evergreen.V308.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V308.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.FileStatus.FileId) (Evergreen.V308.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V308.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V308.Emoji.EmojiOrCustomEmoji (Evergreen.V308.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V308.Drawing.Drawing userId
    , cardDrawings : Evergreen.V308.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V308.Emoji.EmojiOrCustomEmoji (Evergreen.V308.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V308.Drawing.Drawing userId
    , cardDrawings : Evergreen.V308.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V308.Emoji.EmojiOrCustomEmoji (Evergreen.V308.NonemptySet.NonemptySet userId)) (Evergreen.V308.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
