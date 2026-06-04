module Evergreen.V271.TextEditor exposing (..)

import Array
import Evergreen.V271.Id
import Evergreen.V271.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V271.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Int
    , history : Array.Array ( Evergreen.V271.Id.Id Evergreen.V271.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) Evergreen.V271.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)
    | Server_Redo (Evergreen.V271.Id.Id Evergreen.V271.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
