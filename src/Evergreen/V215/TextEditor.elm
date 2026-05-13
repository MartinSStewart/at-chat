module Evergreen.V215.TextEditor exposing (..)

import Array
import Evergreen.V215.Id
import Evergreen.V215.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V215.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Int
    , history : Array.Array ( Evergreen.V215.Id.Id Evergreen.V215.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) Evergreen.V215.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)
    | Server_Redo (Evergreen.V215.Id.Id Evergreen.V215.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
