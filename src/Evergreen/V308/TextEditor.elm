module Evergreen.V308.TextEditor exposing (..)

import Array
import Evergreen.V308.Id
import Evergreen.V308.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V308.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Int
    , history : Array.Array ( Evergreen.V308.Id.Id Evergreen.V308.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) Evergreen.V308.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)
    | Server_Redo (Evergreen.V308.Id.Id Evergreen.V308.Id.UserId)


type alias Model =
    {}
