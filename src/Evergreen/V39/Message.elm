module Evergreen.V39.Message exposing (..)

import Evergreen.V39.Emoji
import Evergreen.V39.FileStatus
import Evergreen.V39.Id
import Evergreen.V39.NonemptySet
import Evergreen.V39.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V39.Id.Id Evergreen.V39.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V39.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V39.Emoji.Emoji (Evergreen.V39.NonemptySet.NonemptySet (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V39.Id.Id Evergreen.V39.Id.ChannelMessageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V39.Id.Id Evergreen.V39.FileStatus.FileId) Evergreen.V39.FileStatus.FileData
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId) (SeqDict.SeqDict Evergreen.V39.Emoji.Emoji (Evergreen.V39.NonemptySet.NonemptySet (Evergreen.V39.Id.Id Evergreen.V39.Id.UserId)))
    | DeletedMessage Time.Posix
