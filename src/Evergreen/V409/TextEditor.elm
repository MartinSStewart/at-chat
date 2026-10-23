module Evergreen.V409.TextEditor exposing (..)

import Array
import Evergreen.V409.Id
import Evergreen.V409.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V409.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Int
    , history : Array.Array ( Evergreen.V409.Id.Id Evergreen.V409.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) Evergreen.V409.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)
    | Server_Redo (Evergreen.V409.Id.Id Evergreen.V409.Id.UserId)


type alias Model =
    {}
