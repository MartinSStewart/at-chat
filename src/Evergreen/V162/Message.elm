module Evergreen.V162.Message exposing (..)

import Array
import Evergreen.V162.Emoji
import Evergreen.V162.FileStatus
import Evergreen.V162.Id
import Evergreen.V162.NonemptySet
import Evergreen.V162.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V162.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V162.Emoji.Emoji (Evergreen.V162.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V162.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V162.Id.Id Evergreen.V162.FileStatus.FileId) Evergreen.V162.FileStatus.FileData
    , embeds : Array.Array Evergreen.V162.RichText.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V162.Emoji.Emoji (Evergreen.V162.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
