module Evergreen.V285.Message exposing (..)

import Array
import Evergreen.V285.Drawing
import Evergreen.V285.Embed
import Evergreen.V285.Emoji
import Evergreen.V285.FileStatus
import Evergreen.V285.Id
import Evergreen.V285.NonemptySet
import Evergreen.V285.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V285.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V285.Emoji.EmojiOrCustomEmoji (Evergreen.V285.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V285.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) Evergreen.V285.FileStatus.FileData
    , embeds : Array.Array Evergreen.V285.Embed.Embed
    , timestampDrawings : Evergreen.V285.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V285.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId) (Evergreen.V285.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V285.Emoji.EmojiOrCustomEmoji (Evergreen.V285.NonemptySet.NonemptySet userId)) (Evergreen.V285.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V285.Emoji.EmojiOrCustomEmoji (Evergreen.V285.NonemptySet.NonemptySet userId)) (Evergreen.V285.Drawing.Drawing userId)
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V285.Emoji.EmojiOrCustomEmoji (Evergreen.V285.NonemptySet.NonemptySet userId)) (Evergreen.V285.Drawing.Drawing userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
