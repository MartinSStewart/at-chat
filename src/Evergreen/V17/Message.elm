module Evergreen.V17.Message exposing (..)

import Evergreen.V17.Emoji
import Evergreen.V17.Id
import Evergreen.V17.NonemptySet
import Evergreen.V17.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V17.Id.Id Evergreen.V17.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V17.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V17.Emoji.Emoji (Evergreen.V17.NonemptySet.NonemptySet (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    }


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId) (SeqDict.SeqDict Evergreen.V17.Emoji.Emoji (Evergreen.V17.NonemptySet.NonemptySet (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)))
    | DeletedMessage
