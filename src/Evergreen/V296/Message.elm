module Evergreen.V296.Message exposing (..)

import Array
import Evergreen.V296.Drawing
import Evergreen.V296.Embed
import Evergreen.V296.Emoji
import Evergreen.V296.FileStatus
import Evergreen.V296.Id
import Evergreen.V296.NonemptySet
import Evergreen.V296.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V296.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V296.Emoji.EmojiOrCustomEmoji (Evergreen.V296.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V296.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) Evergreen.V296.FileStatus.FileData
    , embeds : Array.Array Evergreen.V296.Embed.Embed
    , timestampDrawings : Evergreen.V296.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V296.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.FileStatus.FileId) (Evergreen.V296.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V296.Drawing.Drawing userId)
    }


type Game
    = Game_Go
    | Game_WordSpellingGame


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V296.Emoji.EmojiOrCustomEmoji (Evergreen.V296.NonemptySet.NonemptySet userId)) (Evergreen.V296.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V296.Emoji.EmojiOrCustomEmoji (Evergreen.V296.NonemptySet.NonemptySet userId)) (Evergreen.V296.Drawing.Drawing userId)
    | GameStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V296.Emoji.EmojiOrCustomEmoji (Evergreen.V296.NonemptySet.NonemptySet userId)) (Evergreen.V296.Drawing.Drawing userId) Game


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
