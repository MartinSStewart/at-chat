module Evergreen.V413.SafeJson exposing (..)

import Dict
import Evergreen.V413.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V413.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
