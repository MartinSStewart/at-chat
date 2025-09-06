module Evergreen.V49.Message exposing (..)

import Evergreen.V49.Emoji
import Evergreen.V49.FileStatus
import Evergreen.V49.Id
import Evergreen.V49.NonemptySet
import Evergreen.V49.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V49.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V49.Emoji.Emoji (Evergreen.V49.NonemptySet.NonemptySet (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V49.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V49.Id.Id Evergreen.V49.FileStatus.FileId) Evergreen.V49.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (SeqDict.SeqDict Evergreen.V49.Emoji.Emoji (Evergreen.V49.NonemptySet.NonemptySet (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
