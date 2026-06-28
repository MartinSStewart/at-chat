module Evergreen.V296.TextEditor exposing (..)

import Array
import Evergreen.V296.Id
import Evergreen.V296.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V296.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Int
    , history : Array.Array ( Evergreen.V296.Id.Id Evergreen.V296.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) Evergreen.V296.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId)
    | Server_Redo (Evergreen.V296.Id.Id Evergreen.V296.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack
