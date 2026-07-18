module Evergreen.V328.TextEditor exposing (..)

import Array
import Evergreen.V328.Id
import Evergreen.V328.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V328.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) Int
    , history : Array.Array ( Evergreen.V328.Id.Id Evergreen.V328.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) Evergreen.V328.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)
    | Server_Redo (Evergreen.V328.Id.Id Evergreen.V328.Id.UserId)


type alias Model =
    {}
