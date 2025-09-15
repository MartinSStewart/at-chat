module Evergreen.V61.Message exposing (..)

import Evergreen.V61.Emoji
import Evergreen.V61.FileStatus
import Evergreen.V61.Id
import Evergreen.V61.NonemptySet
import Evergreen.V61.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V61.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V61.Emoji.Emoji (Evergreen.V61.NonemptySet.NonemptySet (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V61.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V61.Id.Id Evergreen.V61.FileStatus.FileId) Evergreen.V61.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (SeqDict.SeqDict Evergreen.V61.Emoji.Emoji (Evergreen.V61.NonemptySet.NonemptySet (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
