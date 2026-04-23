module Evergreen.V207.MessageInput exposing (..)

import Effect.Browser.Dom
import Effect.File
import Evergreen.V207.Range
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
    , selection : Evergreen.V207.Range.Range
    , direction : Evergreen.V207.Range.SelectionDirection
    , dropdown : Maybe MentionUserDropdown
    }


type Msg
    = PressedTextInput
    | TypedMessage String
    | PressedSendMessage
        { charsLeft : Int
        }
    | PressedArrowInDropdown Int
    | PressedArrowUpInEmptyInput
    | PressedDropdownItem Int
    | PressedPingDropdownContainer
    | PressedUploadFile
    | PressedOpenEmojiSelector
    | OnPasteFiles (List.Nonempty.Nonempty Effect.File.File)
