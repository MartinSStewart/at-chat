module Evergreen.V394.TextEditor exposing (..)

import Array
import Evergreen.V394.Id
import Evergreen.V394.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V394.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Int
    , history : Array.Array ( Evergreen.V394.Id.Id Evergreen.V394.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) Evergreen.V394.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)
    | Server_Redo (Evergreen.V394.Id.Id Evergreen.V394.Id.UserId)


type alias Model =
    {}
