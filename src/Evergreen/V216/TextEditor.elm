module Evergreen.V216.TextEditor exposing (..)

import Array
import Evergreen.V216.Id
import Evergreen.V216.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V216.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Int
    , history : Array.Array ( Evergreen.V216.Id.Id Evergreen.V216.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) Evergreen.V216.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)
    | Server_Redo (Evergreen.V216.Id.Id Evergreen.V216.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
