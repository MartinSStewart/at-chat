module Evergreen.V387.TextEditor exposing (..)

import Array
import Evergreen.V387.Id
import Evergreen.V387.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V387.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Int
    , history : Array.Array ( Evergreen.V387.Id.Id Evergreen.V387.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) Evergreen.V387.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)
    | Server_Redo (Evergreen.V387.Id.Id Evergreen.V387.Id.UserId)


type alias Model =
    {}
