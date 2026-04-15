module Evergreen.V201.TextEditor exposing (..)

import Array
import Evergreen.V201.Id
import Evergreen.V201.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V201.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Int
    , history : Array.Array ( Evergreen.V201.Id.Id Evergreen.V201.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) Evergreen.V201.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)
    | Server_Redo (Evergreen.V201.Id.Id Evergreen.V201.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
