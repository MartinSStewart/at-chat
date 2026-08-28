module Evergreen.V363.TextEditor exposing (..)

import Array
import Evergreen.V363.Id
import Evergreen.V363.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V363.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Int
    , history : Array.Array ( Evergreen.V363.Id.Id Evergreen.V363.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) Evergreen.V363.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)
    | Server_Redo (Evergreen.V363.Id.Id Evergreen.V363.Id.UserId)


type alias Model =
    {}
