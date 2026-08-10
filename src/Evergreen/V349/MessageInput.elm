module Evergreen.V349.MessageInput exposing (..)

import Effect.Browser.Dom
import Effect.File
import Evergreen.V349.Range
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
    | TypedPageUp
    | TypedPageDown
    | TypedTabInCodeBlock Evergreen.V349.Range.Range
    | IgnoredKeyPress


type alias TextInputFocus =
    { htmlId : Effect.Browser.Dom.HtmlId
    , selection : Evergreen.V349.Range.Range
    , direction : Evergreen.V349.Range.SelectionDirection
    , dropdown : Maybe MentionUserDropdown
    }
