module Evergreen.V192.TextEditor exposing (..)

import Array
import Evergreen.V192.Id
import Evergreen.V192.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V192.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Int
    , history : Array.Array ( Evergreen.V192.Id.Id Evergreen.V192.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) Evergreen.V192.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)
    | Server_Redo (Evergreen.V192.Id.Id Evergreen.V192.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
