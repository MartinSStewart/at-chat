module Evergreen.V277.TextEditor exposing (..)

import Array
import Evergreen.V277.Id
import Evergreen.V277.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V277.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Int
    , history : Array.Array ( Evergreen.V277.Id.Id Evergreen.V277.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) Evergreen.V277.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)
    | Server_Redo (Evergreen.V277.Id.Id Evergreen.V277.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
