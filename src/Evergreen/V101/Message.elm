module Evergreen.V101.Message exposing (..)

import Evergreen.V101.Emoji
import Evergreen.V101.FileStatus
import Evergreen.V101.Id
import Evergreen.V101.NonemptySet
import Evergreen.V101.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V101.Id.Id Evergreen.V101.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V101.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V101.Emoji.Emoji (Evergreen.V101.NonemptySet.NonemptySet (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V101.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V101.Id.Id Evergreen.V101.FileStatus.FileId) Evergreen.V101.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) (SeqDict.SeqDict Evergreen.V101.Emoji.Emoji (Evergreen.V101.NonemptySet.NonemptySet (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
