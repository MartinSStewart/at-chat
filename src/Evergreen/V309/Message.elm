module Evergreen.V309.Message exposing (..)

import Array
import Evergreen.V309.Drawing
import Evergreen.V309.Embed
import Evergreen.V309.Emoji
import Evergreen.V309.FileStatus
import Evergreen.V309.Id
import Evergreen.V309.NonemptySet
import Evergreen.V309.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V309.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V309.Emoji.EmojiOrCustomEmoji (Evergreen.V309.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V309.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) Evergreen.V309.FileStatus.FileData
    , embeds : Array.Array Evergreen.V309.Embed.Embed
    , timestampDrawings : Evergreen.V309.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V309.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V309.Id.Id Evergreen.V309.FileStatus.FileId) (Evergreen.V309.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V309.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V309.Emoji.EmojiOrCustomEmoji (Evergreen.V309.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V309.Drawing.Drawing userId
    , cardDrawings : Evergreen.V309.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V309.Emoji.EmojiOrCustomEmoji (Evergreen.V309.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V309.Drawing.Drawing userId
    , cardDrawings : Evergreen.V309.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V309.Emoji.EmojiOrCustomEmoji (Evergreen.V309.NonemptySet.NonemptySet userId)) (Evergreen.V309.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
