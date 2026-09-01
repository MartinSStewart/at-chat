module Evergreen.V365.Message exposing (..)

import Array
import Evergreen.V365.Drawing
import Evergreen.V365.Embed
import Evergreen.V365.Emoji
import Evergreen.V365.FileStatus
import Evergreen.V365.Id
import Evergreen.V365.NonemptySet
import Evergreen.V365.RichText
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
    , content : List.Nonempty.Nonempty (Evergreen.V365.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V365.Emoji.EmojiOrCustomEmoji (Evergreen.V365.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V365.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) Evergreen.V365.FileStatus.FileData
    , embeds : Array.Array Evergreen.V365.Embed.Embed
    , timestampDrawings : Evergreen.V365.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V365.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.FileStatus.FileId) (Evergreen.V365.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V365.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V365.Emoji.EmojiOrCustomEmoji (Evergreen.V365.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V365.Drawing.Drawing userId
    , cardDrawings : Evergreen.V365.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V365.Emoji.EmojiOrCustomEmoji (Evergreen.V365.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V365.Drawing.Drawing userId
    , cardDrawings : Evergreen.V365.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V365.Emoji.EmojiOrCustomEmoji (Evergreen.V365.NonemptySet.NonemptySet userId)) (Evergreen.V365.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
