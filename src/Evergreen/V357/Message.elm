module Evergreen.V357.Message exposing (..)

import Array
import Evergreen.V357.Drawing
import Evergreen.V357.Embed
import Evergreen.V357.Emoji
import Evergreen.V357.FileStatus
import Evergreen.V357.Id
import Evergreen.V357.NonemptySet
import Evergreen.V357.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame
    | GameType_SheepGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V357.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V357.Emoji.EmojiOrCustomEmoji (Evergreen.V357.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V357.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) Evergreen.V357.FileStatus.FileData
    , embeds : Array.Array Evergreen.V357.Embed.Embed
    , timestampDrawings : Evergreen.V357.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V357.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.FileStatus.FileId) (Evergreen.V357.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V357.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V357.Emoji.EmojiOrCustomEmoji (Evergreen.V357.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V357.Drawing.Drawing userId
    , cardDrawings : Evergreen.V357.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V357.Emoji.EmojiOrCustomEmoji (Evergreen.V357.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V357.Drawing.Drawing userId
    , cardDrawings : Evergreen.V357.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V357.Emoji.EmojiOrCustomEmoji (Evergreen.V357.NonemptySet.NonemptySet userId)) (Evergreen.V357.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
