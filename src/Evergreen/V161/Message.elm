module Evergreen.V161.Message exposing (..)

import Array
import Evergreen.V161.Emoji
import Evergreen.V161.FileStatus
import Evergreen.V161.Id
import Evergreen.V161.NonemptySet
import Evergreen.V161.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V161.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V161.Emoji.Emoji (Evergreen.V161.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V161.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V161.Id.Id Evergreen.V161.FileStatus.FileId) Evergreen.V161.FileStatus.FileData
    , embeds : Array.Array Evergreen.V161.RichText.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V161.Emoji.Emoji (Evergreen.V161.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
