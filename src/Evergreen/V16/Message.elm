module Evergreen.V16.Message exposing (..)

import Evergreen.V16.Emoji
import Evergreen.V16.Id
import Evergreen.V16.NonemptySet
import Evergreen.V16.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V16.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V16.Emoji.Emoji (Evergreen.V16.NonemptySet.NonemptySet (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) (SeqDict.SeqDict Evergreen.V16.Emoji.Emoji (Evergreen.V16.NonemptySet.NonemptySet (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)))
    | DeletedMessage
