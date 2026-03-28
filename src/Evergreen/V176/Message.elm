module Evergreen.V176.Message exposing (..)

import Array
import Evergreen.V176.Embed
import Evergreen.V176.Emoji
import Evergreen.V176.FileStatus
import Evergreen.V176.Id
import Evergreen.V176.NonemptySet
import Evergreen.V176.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V176.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V176.Emoji.Emoji (Evergreen.V176.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V176.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V176.Id.Id Evergreen.V176.FileStatus.FileId) Evergreen.V176.FileStatus.FileData
    , embeds : Array.Array Evergreen.V176.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V176.Emoji.Emoji (Evergreen.V176.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
