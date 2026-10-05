module Evergreen.V398.TextEditor exposing (..)

import Array
import Evergreen.V398.Id
import Evergreen.V398.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V398.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Int
    , history : Array.Array ( Evergreen.V398.Id.Id Evergreen.V398.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) Evergreen.V398.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)
    | Server_Redo (Evergreen.V398.Id.Id Evergreen.V398.Id.UserId)


type alias Model =
    {}
