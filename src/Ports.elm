port module Ports exposing
    ( copyToClipboard
    , textInputSelectAll
    )

import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Json.Encode


port copy_to_clipboard_to_js : Json.Encode.Value -> Cmd msg


port text_input_select_all_to_js : Json.Encode.Value -> Cmd msg


textInputSelectAll : HtmlId -> Command FrontendOnly toMsg msg
textInputSelectAll htmlId =
    Dom.idToString htmlId
        |> Json.Encode.string
        |> Command.sendToJs "text_input_select_all_to_js" text_input_select_all_to_js


copyToClipboard : String -> Command FrontendOnly toMsg msg
copyToClipboard text =
    Command.sendToJs "copy_to_clipboard_to_js" copy_to_clipboard_to_js (Json.Encode.string text)
