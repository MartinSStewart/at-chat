module Evergreen.V229.TextEditor exposing (..)

import Array
import Evergreen.V229.Id
import Evergreen.V229.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V229.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Int
    , history : Array.Array ( Evergreen.V229.Id.Id Evergreen.V229.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) Evergreen.V229.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)
    | Server_Redo (Evergreen.V229.Id.Id Evergreen.V229.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
