module Evergreen.V203.TextEditor exposing (..)

import Array
import Evergreen.V203.Id
import Evergreen.V203.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V203.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Int
    , history : Array.Array ( Evergreen.V203.Id.Id Evergreen.V203.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) Evergreen.V203.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)
    | Server_Redo (Evergreen.V203.Id.Id Evergreen.V203.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
