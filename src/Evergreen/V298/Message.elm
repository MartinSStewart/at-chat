module Evergreen.V298.Message exposing (..)

import Array
import Evergreen.V298.Drawing
import Evergreen.V298.Embed
import Evergreen.V298.Emoji
import Evergreen.V298.FileStatus
import Evergreen.V298.Id
import Evergreen.V298.NonemptySet
import Evergreen.V298.RichText
import List.Nonempty
import SeqDict
import Time


type Game
    = Game_Go
    | Game_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V298.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V298.Emoji.EmojiOrCustomEmoji (Evergreen.V298.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V298.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) Evergreen.V298.FileStatus.FileData
    , embeds : Array.Array Evergreen.V298.Embed.Embed
    , timestampDrawings : Evergreen.V298.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V298.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V298.Id.Id Evergreen.V298.FileStatus.FileId) (Evergreen.V298.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V298.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V298.Emoji.EmojiOrCustomEmoji (Evergreen.V298.NonemptySet.NonemptySet userId)) (Evergreen.V298.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V298.Emoji.EmojiOrCustomEmoji (Evergreen.V298.NonemptySet.NonemptySet userId)) (Evergreen.V298.Drawing.Drawing userId)
    | GameStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V298.Emoji.EmojiOrCustomEmoji (Evergreen.V298.NonemptySet.NonemptySet userId)) (Evergreen.V298.Drawing.Drawing userId) Game


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
