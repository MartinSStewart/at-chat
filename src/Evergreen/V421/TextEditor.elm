module Evergreen.V421.TextEditor exposing (..)

import Array
import Evergreen.V421.Id
import Evergreen.V421.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V421.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Int
    , history : Array.Array ( Evergreen.V421.Id.Id Evergreen.V421.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) Evergreen.V421.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)
    | Server_Redo (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId)


type alias Model =
    {}
