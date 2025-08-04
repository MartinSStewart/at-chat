module Evergreen.V15.Message exposing (..)

import Evergreen.V15.Emoji
import Evergreen.V15.Id
import Evergreen.V15.NonemptySet
import Evergreen.V15.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V15.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V15.Emoji.Emoji (Evergreen.V15.NonemptySet.NonemptySet (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId) (SeqDict.SeqDict Evergreen.V15.Emoji.Emoji (Evergreen.V15.NonemptySet.NonemptySet (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)))
    | DeletedMessage
