module Evergreen.V266.TextEditor exposing (..)

import Array
import Evergreen.V266.Id
import Evergreen.V266.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V266.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Int
    , history : Array.Array ( Evergreen.V266.Id.Id Evergreen.V266.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) Evergreen.V266.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)
    | Server_Redo (Evergreen.V266.Id.Id Evergreen.V266.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
