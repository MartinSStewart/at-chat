module Evergreen.V38.Message exposing (..)

import Evergreen.V38.Emoji
import Evergreen.V38.FileStatus
import Evergreen.V38.Id
import Evergreen.V38.NonemptySet
import Evergreen.V38.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V38.Id.Id Evergreen.V38.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V38.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V38.Emoji.Emoji (Evergreen.V38.NonemptySet.NonemptySet (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V38.Id.Id Evergreen.V38.Id.ChannelMessageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V38.Id.Id Evergreen.V38.FileStatus.FileId) Evergreen.V38.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId) (SeqDict.SeqDict Evergreen.V38.Emoji.Emoji (Evergreen.V38.NonemptySet.NonemptySet (Evergreen.V38.Id.Id Evergreen.V38.Id.UserId)))
    | DeletedMessage Time.Posix
