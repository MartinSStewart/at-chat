module Evergreen.V207.Message exposing (..)

import Array
import Evergreen.V207.Embed
import Evergreen.V207.Emoji
import Evergreen.V207.FileStatus
import Evergreen.V207.Id
import Evergreen.V207.NonemptySet
import Evergreen.V207.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V207.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V207.Emoji.Emoji (Evergreen.V207.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V207.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V207.Id.Id Evergreen.V207.FileStatus.FileId) Evergreen.V207.FileStatus.FileData
    , embeds : Array.Array Evergreen.V207.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V207.Emoji.Emoji (Evergreen.V207.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
