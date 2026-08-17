module Evergreen.V354.Message exposing (..)

import Array
import Evergreen.V354.Drawing
import Evergreen.V354.Embed
import Evergreen.V354.Emoji
import Evergreen.V354.FileStatus
import Evergreen.V354.Id
import Evergreen.V354.NonemptySet
import Evergreen.V354.RichText
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
    , content : List.Nonempty.Nonempty (Evergreen.V354.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V354.Emoji.EmojiOrCustomEmoji (Evergreen.V354.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V354.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) Evergreen.V354.FileStatus.FileData
    , embeds : Array.Array Evergreen.V354.Embed.Embed
    , timestampDrawings : Evergreen.V354.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V354.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V354.Id.Id Evergreen.V354.FileStatus.FileId) (Evergreen.V354.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V354.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V354.Emoji.EmojiOrCustomEmoji (Evergreen.V354.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V354.Drawing.Drawing userId
    , cardDrawings : Evergreen.V354.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V354.Emoji.EmojiOrCustomEmoji (Evergreen.V354.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V354.Drawing.Drawing userId
    , cardDrawings : Evergreen.V354.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V354.Emoji.EmojiOrCustomEmoji (Evergreen.V354.NonemptySet.NonemptySet userId)) (Evergreen.V354.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)
