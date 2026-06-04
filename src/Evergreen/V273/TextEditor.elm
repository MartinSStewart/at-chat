module Evergreen.V273.TextEditor exposing (..)

import Array
import Evergreen.V273.Id
import Evergreen.V273.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V273.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Int
    , history : Array.Array ( Evergreen.V273.Id.Id Evergreen.V273.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) Evergreen.V273.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)
    | Server_Redo (Evergreen.V273.Id.Id Evergreen.V273.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
