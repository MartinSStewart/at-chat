module Evergreen.V42.Message exposing (..)

import Evergreen.V42.Emoji
import Evergreen.V42.FileStatus
import Evergreen.V42.Id
import Evergreen.V42.NonemptySet
import Evergreen.V42.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V42.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V42.Emoji.Emoji (Evergreen.V42.NonemptySet.NonemptySet (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V42.Id.Id Evergreen.V42.Id.ChannelMessageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V42.Id.Id Evergreen.V42.FileStatus.FileId) Evergreen.V42.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId) (SeqDict.SeqDict Evergreen.V42.Emoji.Emoji (Evergreen.V42.NonemptySet.NonemptySet (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)))
    | DeletedMessage Time.Posix
