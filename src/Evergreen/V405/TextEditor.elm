module Evergreen.V405.TextEditor exposing (..)

import Array
import Evergreen.V405.Id
import Evergreen.V405.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V405.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Int
    , history : Array.Array ( Evergreen.V405.Id.Id Evergreen.V405.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) Evergreen.V405.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)
    | Server_Redo (Evergreen.V405.Id.Id Evergreen.V405.Id.UserId)


type alias Model =
    {}
