module Evergreen.V255.TextEditor exposing (..)

import Array
import Evergreen.V255.Id
import Evergreen.V255.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V255.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Int
    , history : Array.Array ( Evergreen.V255.Id.Id Evergreen.V255.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) Evergreen.V255.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)
    | Server_Redo (Evergreen.V255.Id.Id Evergreen.V255.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
