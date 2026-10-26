module Evergreen.V413.TextEditor exposing (..)

import Array
import Evergreen.V413.Id
import Evergreen.V413.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V413.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Int
    , history : Array.Array ( Evergreen.V413.Id.Id Evergreen.V413.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) Evergreen.V413.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)
    | Server_Redo (Evergreen.V413.Id.Id Evergreen.V413.Id.UserId)


type alias Model =
    {}
