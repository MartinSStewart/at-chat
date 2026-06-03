module Evergreen.V270.TextEditor exposing (..)

import Array
import Evergreen.V270.Id
import Evergreen.V270.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V270.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Int
    , history : Array.Array ( Evergreen.V270.Id.Id Evergreen.V270.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) Evergreen.V270.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)
    | Server_Redo (Evergreen.V270.Id.Id Evergreen.V270.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
