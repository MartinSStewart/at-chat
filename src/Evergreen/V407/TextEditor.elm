module Evergreen.V407.TextEditor exposing (..)

import Array
import Evergreen.V407.Id
import Evergreen.V407.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V407.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Int
    , history : Array.Array ( Evergreen.V407.Id.Id Evergreen.V407.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) Evergreen.V407.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)
    | Server_Redo (Evergreen.V407.Id.Id Evergreen.V407.Id.UserId)


type alias Model =
    {}
