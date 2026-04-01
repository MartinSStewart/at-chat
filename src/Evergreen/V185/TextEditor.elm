module Evergreen.V185.TextEditor exposing (..)

import Array
import Evergreen.V185.Id
import Evergreen.V185.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V185.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Int
    , history : Array.Array ( Evergreen.V185.Id.Id Evergreen.V185.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) Evergreen.V185.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)
    | Server_Redo (Evergreen.V185.Id.Id Evergreen.V185.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
