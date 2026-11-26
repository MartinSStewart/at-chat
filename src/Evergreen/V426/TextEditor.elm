module Evergreen.V426.TextEditor exposing (..)

import Array
import Evergreen.V426.Id
import Evergreen.V426.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V426.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Int
    , history : Array.Array ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) Evergreen.V426.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)
    | Server_Redo (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId)


type alias Model =
    {}
