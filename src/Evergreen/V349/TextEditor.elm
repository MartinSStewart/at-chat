module Evergreen.V349.TextEditor exposing (..)

import Array
import Evergreen.V349.Id
import Evergreen.V349.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V349.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Int
    , history : Array.Array ( Evergreen.V349.Id.Id Evergreen.V349.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) Evergreen.V349.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)
    | Server_Redo (Evergreen.V349.Id.Id Evergreen.V349.Id.UserId)


type alias Model =
    {}
