module Evergreen.V289.Message exposing (..)

import Array
import Evergreen.V289.Drawing
import Evergreen.V289.Embed
import Evergreen.V289.Emoji
import Evergreen.V289.FileStatus
import Evergreen.V289.Id
import Evergreen.V289.NonemptySet
import Evergreen.V289.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V289.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V289.Emoji.EmojiOrCustomEmoji (Evergreen.V289.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V289.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) Evergreen.V289.FileStatus.FileData
    , embeds : Array.Array Evergreen.V289.Embed.Embed
    , timestampDrawings : Evergreen.V289.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V289.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V289.Id.Id Evergreen.V289.FileStatus.FileId) (Evergreen.V289.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V289.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V289.Emoji.EmojiOrCustomEmoji (Evergreen.V289.NonemptySet.NonemptySet userId)) (Evergreen.V289.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V289.Emoji.EmojiOrCustomEmoji (Evergreen.V289.NonemptySet.NonemptySet userId)) (Evergreen.V289.Drawing.Drawing userId)
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V289.Emoji.EmojiOrCustomEmoji (Evergreen.V289.NonemptySet.NonemptySet userId)) (Evergreen.V289.Drawing.Drawing userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
