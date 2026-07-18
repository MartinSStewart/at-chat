module Evergreen.V327.TextEditor exposing (..)

import Array
import Evergreen.V327.Id
import Evergreen.V327.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V327.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Int
    , history : Array.Array ( Evergreen.V327.Id.Id Evergreen.V327.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) Evergreen.V327.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)
    | Server_Redo (Evergreen.V327.Id.Id Evergreen.V327.Id.UserId)


type alias Model =
    {}
