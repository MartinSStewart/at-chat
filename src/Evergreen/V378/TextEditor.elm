module Evergreen.V378.TextEditor exposing (..)

import Array
import Evergreen.V378.Id
import Evergreen.V378.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V378.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Int
    , history : Array.Array ( Evergreen.V378.Id.Id Evergreen.V378.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) Evergreen.V378.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)
    | Server_Redo (Evergreen.V378.Id.Id Evergreen.V378.Id.UserId)


type alias Model =
    {}
