module Evergreen.V52.Message exposing (..)

import Evergreen.V52.Emoji
import Evergreen.V52.FileStatus
import Evergreen.V52.Id
import Evergreen.V52.NonemptySet
import Evergreen.V52.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V52.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V52.Emoji.Emoji (Evergreen.V52.NonemptySet.NonemptySet (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V52.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V52.Id.Id Evergreen.V52.FileStatus.FileId) Evergreen.V52.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) (SeqDict.SeqDict Evergreen.V52.Emoji.Emoji (Evergreen.V52.NonemptySet.NonemptySet (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
