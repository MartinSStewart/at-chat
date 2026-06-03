module Evergreen.V269.TextEditor exposing (..)

import Array
import Evergreen.V269.Id
import Evergreen.V269.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V269.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Int
    , history : Array.Array ( Evergreen.V269.Id.Id Evergreen.V269.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) Evergreen.V269.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)
    | Server_Redo (Evergreen.V269.Id.Id Evergreen.V269.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
