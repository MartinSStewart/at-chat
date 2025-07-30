module Message exposing (Message(..), UserTextMessageData)

import Emoji exposing (Emoji)
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty)
import NonemptySet exposing (NonemptySet)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import Time


type Message
    = UserTextMessage UserTextMessageData
    | UserJoinedMessage Time.Posix (Id UserId) (SeqDict Emoji (NonemptySet (Id UserId)))
    | DeletedMessage


type alias UserTextMessageData =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , content : Nonempty RichText
    , reactions : SeqDict Emoji (NonemptySet (Id UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe Int
    }
