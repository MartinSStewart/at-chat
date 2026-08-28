module Evergreen.V364.TextEditor exposing (..)

import Array
import Evergreen.V364.Id
import Evergreen.V364.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V364.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Int
    , history : Array.Array ( Evergreen.V364.Id.Id Evergreen.V364.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) Evergreen.V364.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)
    | Server_Redo (Evergreen.V364.Id.Id Evergreen.V364.Id.UserId)


type alias Model =
    {}
