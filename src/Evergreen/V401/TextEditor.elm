module Evergreen.V401.TextEditor exposing (..)

import Array
import Evergreen.V401.Id
import Evergreen.V401.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V401.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Int
    , history : Array.Array ( Evergreen.V401.Id.Id Evergreen.V401.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) Evergreen.V401.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)
    | Server_Redo (Evergreen.V401.Id.Id Evergreen.V401.Id.UserId)


type alias Model =
    {}
