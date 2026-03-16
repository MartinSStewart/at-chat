module Evergreen.V154.Message exposing (..)

import Array
import Evergreen.V154.Emoji
import Evergreen.V154.FileStatus
import Evergreen.V154.Id
import Evergreen.V154.NonemptySet
import Evergreen.V154.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V154.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V154.Emoji.Emoji (Evergreen.V154.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V154.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V154.Id.Id Evergreen.V154.FileStatus.FileId) Evergreen.V154.FileStatus.FileData
    , embeds : Array.Array Evergreen.V154.RichText.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V154.Emoji.Emoji (Evergreen.V154.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
