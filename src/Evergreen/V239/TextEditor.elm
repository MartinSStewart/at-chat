module Evergreen.V239.TextEditor exposing (..)

import Array
import Evergreen.V239.Id
import Evergreen.V239.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V239.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Int
    , history : Array.Array ( Evergreen.V239.Id.Id Evergreen.V239.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) Evergreen.V239.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)
    | Server_Redo (Evergreen.V239.Id.Id Evergreen.V239.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
