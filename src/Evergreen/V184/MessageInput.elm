module Evergreen.V184.MessageInput exposing (..)

import Effect.Browser.Dom
import Effect.File
import Evergreen.V184.MyUi
import List.Nonempty


type alias MentionUserDropdown =
    { dropdownIndex : Int
    , inputElement :
        { x : Float
        , y : Float
        , width : Float
        , height : Float
        }
    }


type alias TextInputFocus =
    { htmlId : Effect.Browser.Dom.HtmlId
    , selection : Evergreen.V184.MyUi.Range
    , direction : Evergreen.V184.MyUi.SelectionDirection
    , dropdown : Maybe MentionUserDropdown
    }


type Msg
    = PressedTextInput
    | TypedMessage String
    | PressedSendMessage
    | PressedArrowInDropdown Int
    | PressedArrowUpInEmptyInput
    | PressedDropdownItem Int
    | PressedPingDropdownContainer
    | PressedUploadFile
    | PressedOpenEmojiSelector
    | OnPasteFiles (List.Nonempty.Nonempty Effect.File.File)
