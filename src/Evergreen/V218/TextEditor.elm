module Evergreen.V218.TextEditor exposing (..)

import Array
import Evergreen.V218.Id
import Evergreen.V218.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V218.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Int
    , history : Array.Array ( Evergreen.V218.Id.Id Evergreen.V218.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) Evergreen.V218.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)
    | Server_Redo (Evergreen.V218.Id.Id Evergreen.V218.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
