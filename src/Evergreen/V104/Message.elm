module Evergreen.V104.Message exposing (..)

import Evergreen.V104.Emoji
import Evergreen.V104.FileStatus
import Evergreen.V104.Id
import Evergreen.V104.NonemptySet
import Evergreen.V104.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V104.Id.Id Evergreen.V104.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V104.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V104.Emoji.Emoji (Evergreen.V104.NonemptySet.NonemptySet (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V104.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V104.Id.Id Evergreen.V104.FileStatus.FileId) Evergreen.V104.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) (SeqDict.SeqDict Evergreen.V104.Emoji.Emoji (Evergreen.V104.NonemptySet.NonemptySet (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
