module Evergreen.V346.TextEditor exposing (..)

import Array
import Evergreen.V346.Id
import Evergreen.V346.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V346.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Int
    , history : Array.Array ( Evergreen.V346.Id.Id Evergreen.V346.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) Evergreen.V346.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)
    | Server_Redo (Evergreen.V346.Id.Id Evergreen.V346.Id.UserId)


type alias Model =
    {}
