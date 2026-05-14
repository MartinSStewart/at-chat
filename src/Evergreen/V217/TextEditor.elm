module Evergreen.V217.TextEditor exposing (..)

import Array
import Evergreen.V217.Id
import Evergreen.V217.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V217.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Int
    , history : Array.Array ( Evergreen.V217.Id.Id Evergreen.V217.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) Evergreen.V217.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)
    | Server_Redo (Evergreen.V217.Id.Id Evergreen.V217.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
