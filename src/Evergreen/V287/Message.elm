module Evergreen.V287.Message exposing (..)

import Array
import Evergreen.V287.Drawing
import Evergreen.V287.Embed
import Evergreen.V287.Emoji
import Evergreen.V287.FileStatus
import Evergreen.V287.Id
import Evergreen.V287.NonemptySet
import Evergreen.V287.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V287.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V287.Emoji.EmojiOrCustomEmoji (Evergreen.V287.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V287.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) Evergreen.V287.FileStatus.FileData
    , embeds : Array.Array Evergreen.V287.Embed.Embed
    , timestampDrawings : Evergreen.V287.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V287.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId) (Evergreen.V287.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V287.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V287.Emoji.EmojiOrCustomEmoji (Evergreen.V287.NonemptySet.NonemptySet userId)) (Evergreen.V287.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V287.Emoji.EmojiOrCustomEmoji (Evergreen.V287.NonemptySet.NonemptySet userId)) (Evergreen.V287.Drawing.Drawing userId)
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V287.Emoji.EmojiOrCustomEmoji (Evergreen.V287.NonemptySet.NonemptySet userId)) (Evergreen.V287.Drawing.Drawing userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
