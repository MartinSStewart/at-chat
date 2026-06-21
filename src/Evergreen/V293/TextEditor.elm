module Evergreen.V293.TextEditor exposing (..)

import Array
import Evergreen.V293.Id
import Evergreen.V293.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V293.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Int
    , history : Array.Array ( Evergreen.V293.Id.Id Evergreen.V293.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) Evergreen.V293.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)
    | Server_Redo (Evergreen.V293.Id.Id Evergreen.V293.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack
