module Evergreen.V190.TextEditor exposing (..)

import Array
import Evergreen.V190.Id
import Evergreen.V190.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V190.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Int
    , history : Array.Array ( Evergreen.V190.Id.Id Evergreen.V190.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) Evergreen.V190.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)
    | Server_Redo (Evergreen.V190.Id.Id Evergreen.V190.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
