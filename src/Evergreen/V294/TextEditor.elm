module Evergreen.V294.TextEditor exposing (..)

import Array
import Evergreen.V294.Id
import Evergreen.V294.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V294.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Int
    , history : Array.Array ( Evergreen.V294.Id.Id Evergreen.V294.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) Evergreen.V294.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)
    | Server_Redo (Evergreen.V294.Id.Id Evergreen.V294.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack
