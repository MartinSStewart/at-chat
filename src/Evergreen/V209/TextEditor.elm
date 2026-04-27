module Evergreen.V209.TextEditor exposing (..)

import Array
import Evergreen.V209.Id
import Evergreen.V209.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V209.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Int
    , history : Array.Array ( Evergreen.V209.Id.Id Evergreen.V209.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) Evergreen.V209.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)
    | Server_Redo (Evergreen.V209.Id.Id Evergreen.V209.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
