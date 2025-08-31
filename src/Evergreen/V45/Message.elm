module Evergreen.V45.Message exposing (..)

import Evergreen.V45.Emoji
import Evergreen.V45.FileStatus
import Evergreen.V45.Id
import Evergreen.V45.NonemptySet
import Evergreen.V45.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V45.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V45.Emoji.Emoji (Evergreen.V45.NonemptySet.NonemptySet (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V45.Id.Id Evergreen.V45.Id.ChannelMessageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V45.Id.Id Evergreen.V45.FileStatus.FileId) Evergreen.V45.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId) (SeqDict.SeqDict Evergreen.V45.Emoji.Emoji (Evergreen.V45.NonemptySet.NonemptySet (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)))
    | DeletedMessage Time.Posix
