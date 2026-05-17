module Evergreen.V232.TextEditor exposing (..)

import Array
import Evergreen.V232.Id
import Evergreen.V232.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V232.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Int
    , history : Array.Array ( Evergreen.V232.Id.Id Evergreen.V232.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) Evergreen.V232.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)
    | Server_Redo (Evergreen.V232.Id.Id Evergreen.V232.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
