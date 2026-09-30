module Evergreen.V395.TextEditor exposing (..)

import Array
import Evergreen.V395.Id
import Evergreen.V395.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V395.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Int
    , history : Array.Array ( Evergreen.V395.Id.Id Evergreen.V395.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) Evergreen.V395.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)
    | Server_Redo (Evergreen.V395.Id.Id Evergreen.V395.Id.UserId)


type alias Model =
    {}
