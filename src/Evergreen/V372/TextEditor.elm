module Evergreen.V372.TextEditor exposing (..)

import Array
import Evergreen.V372.Id
import Evergreen.V372.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V372.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Int
    , history : Array.Array ( Evergreen.V372.Id.Id Evergreen.V372.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) Evergreen.V372.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)
    | Server_Redo (Evergreen.V372.Id.Id Evergreen.V372.Id.UserId)


type alias Model =
    {}
