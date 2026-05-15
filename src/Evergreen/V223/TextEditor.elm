module Evergreen.V223.TextEditor exposing (..)

import Array
import Evergreen.V223.Id
import Evergreen.V223.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V223.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) Int
    , history : Array.Array ( Evergreen.V223.Id.Id Evergreen.V223.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) Evergreen.V223.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)
    | Server_Redo (Evergreen.V223.Id.Id Evergreen.V223.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
