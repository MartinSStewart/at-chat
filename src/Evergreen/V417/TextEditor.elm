module Evergreen.V417.TextEditor exposing (..)

import Array
import Evergreen.V417.Id
import Evergreen.V417.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V417.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Int
    , history : Array.Array ( Evergreen.V417.Id.Id Evergreen.V417.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) Evergreen.V417.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)
    | Server_Redo (Evergreen.V417.Id.Id Evergreen.V417.Id.UserId)


type alias Model =
    {}
