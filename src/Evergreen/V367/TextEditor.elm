module Evergreen.V367.TextEditor exposing (..)

import Array
import Evergreen.V367.Id
import Evergreen.V367.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V367.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Int
    , history : Array.Array ( Evergreen.V367.Id.Id Evergreen.V367.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) Evergreen.V367.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId)
    | Server_Redo (Evergreen.V367.Id.Id Evergreen.V367.Id.UserId)


type alias Model =
    {}
