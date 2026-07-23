module Evergreen.V333.TextEditor exposing (..)

import Array
import Evergreen.V333.Id
import Evergreen.V333.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V333.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Int
    , history : Array.Array ( Evergreen.V333.Id.Id Evergreen.V333.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) Evergreen.V333.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)
    | Server_Redo (Evergreen.V333.Id.Id Evergreen.V333.Id.UserId)


type alias Model =
    {}
