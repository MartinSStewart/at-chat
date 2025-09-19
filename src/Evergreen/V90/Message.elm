module Evergreen.V90.Message exposing (..)

import Evergreen.V90.Emoji
import Evergreen.V90.FileStatus
import Evergreen.V90.Id
import Evergreen.V90.NonemptySet
import Evergreen.V90.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V90.Id.Id Evergreen.V90.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V90.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V90.Emoji.Emoji (Evergreen.V90.NonemptySet.NonemptySet (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V90.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V90.Id.Id Evergreen.V90.FileStatus.FileId) Evergreen.V90.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) (SeqDict.SeqDict Evergreen.V90.Emoji.Emoji (Evergreen.V90.NonemptySet.NonemptySet (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
