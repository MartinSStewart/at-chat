module Evergreen.V177.Message exposing (..)

import Array
import Evergreen.V177.Embed
import Evergreen.V177.Emoji
import Evergreen.V177.FileStatus
import Evergreen.V177.Id
import Evergreen.V177.NonemptySet
import Evergreen.V177.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V177.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V177.Emoji.Emoji (Evergreen.V177.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V177.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V177.Id.Id Evergreen.V177.FileStatus.FileId) Evergreen.V177.FileStatus.FileData
    , embeds : Array.Array Evergreen.V177.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V177.Emoji.Emoji (Evergreen.V177.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
