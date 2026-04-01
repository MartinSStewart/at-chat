module Evergreen.V183.TextEditor exposing (..)

import Array
import Evergreen.V183.Id
import Evergreen.V183.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V183.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Int
    , history : Array.Array ( Evergreen.V183.Id.Id Evergreen.V183.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) Evergreen.V183.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)
    | Server_Redo (Evergreen.V183.Id.Id Evergreen.V183.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
