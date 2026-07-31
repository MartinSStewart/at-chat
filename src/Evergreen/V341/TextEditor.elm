module Evergreen.V341.TextEditor exposing (..)

import Array
import Evergreen.V341.Id
import Evergreen.V341.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V341.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Int
    , history : Array.Array ( Evergreen.V341.Id.Id Evergreen.V341.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) Evergreen.V341.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)
    | Server_Redo (Evergreen.V341.Id.Id Evergreen.V341.Id.UserId)


type alias Model =
    {}
