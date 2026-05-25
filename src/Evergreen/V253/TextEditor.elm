module Evergreen.V253.TextEditor exposing (..)

import Array
import Evergreen.V253.Id
import Evergreen.V253.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V253.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Int
    , history : Array.Array ( Evergreen.V253.Id.Id Evergreen.V253.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) Evergreen.V253.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)
    | Server_Redo (Evergreen.V253.Id.Id Evergreen.V253.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
