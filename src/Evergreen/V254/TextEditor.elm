module Evergreen.V254.TextEditor exposing (..)

import Array
import Evergreen.V254.Id
import Evergreen.V254.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V254.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) Int
    , history : Array.Array ( Evergreen.V254.Id.Id Evergreen.V254.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) Evergreen.V254.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)
    | Server_Redo (Evergreen.V254.Id.Id Evergreen.V254.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
