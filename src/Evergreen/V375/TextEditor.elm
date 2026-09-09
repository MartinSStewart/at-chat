module Evergreen.V375.TextEditor exposing (..)

import Array
import Evergreen.V375.Id
import Evergreen.V375.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V375.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Int
    , history : Array.Array ( Evergreen.V375.Id.Id Evergreen.V375.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) Evergreen.V375.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)
    | Server_Redo (Evergreen.V375.Id.Id Evergreen.V375.Id.UserId)


type alias Model =
    {}
