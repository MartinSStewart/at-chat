module Evergreen.V422.TextEditor exposing (..)

import Array
import Evergreen.V422.Id
import Evergreen.V422.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V422.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Int
    , history : Array.Array ( Evergreen.V422.Id.Id Evergreen.V422.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) Evergreen.V422.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)
    | Server_Redo (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId)


type alias Model =
    {}
