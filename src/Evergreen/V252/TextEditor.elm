module Evergreen.V252.TextEditor exposing (..)

import Array
import Evergreen.V252.Id
import Evergreen.V252.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V252.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Int
    , history : Array.Array ( Evergreen.V252.Id.Id Evergreen.V252.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) Evergreen.V252.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)
    | Server_Redo (Evergreen.V252.Id.Id Evergreen.V252.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
