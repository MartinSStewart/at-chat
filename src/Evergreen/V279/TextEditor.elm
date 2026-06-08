module Evergreen.V279.TextEditor exposing (..)

import Array
import Evergreen.V279.Id
import Evergreen.V279.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V279.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Int
    , history : Array.Array ( Evergreen.V279.Id.Id Evergreen.V279.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) Evergreen.V279.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)
    | Server_Redo (Evergreen.V279.Id.Id Evergreen.V279.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
