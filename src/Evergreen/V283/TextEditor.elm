module Evergreen.V283.TextEditor exposing (..)

import Array
import Evergreen.V283.Id
import Evergreen.V283.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V283.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Int
    , history : Array.Array ( Evergreen.V283.Id.Id Evergreen.V283.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) Evergreen.V283.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId)
    | Server_Redo (Evergreen.V283.Id.Id Evergreen.V283.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
