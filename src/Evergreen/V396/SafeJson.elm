module Evergreen.V396.SafeJson exposing (..)

import Dict
import Evergreen.V396.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V396.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
