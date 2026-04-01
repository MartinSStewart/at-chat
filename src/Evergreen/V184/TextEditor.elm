module Evergreen.V184.TextEditor exposing (..)

import Array
import Evergreen.V184.Id
import Evergreen.V184.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V184.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Int
    , history : Array.Array ( Evergreen.V184.Id.Id Evergreen.V184.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) Evergreen.V184.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)
    | Server_Redo (Evergreen.V184.Id.Id Evergreen.V184.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
