module Evergreen.V56.Message exposing (..)

import Evergreen.V56.Emoji
import Evergreen.V56.FileStatus
import Evergreen.V56.Id
import Evergreen.V56.NonemptySet
import Evergreen.V56.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V56.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V56.Emoji.Emoji (Evergreen.V56.NonemptySet.NonemptySet (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V56.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V56.Id.Id Evergreen.V56.FileStatus.FileId) Evergreen.V56.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (SeqDict.SeqDict Evergreen.V56.Emoji.Emoji (Evergreen.V56.NonemptySet.NonemptySet (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
