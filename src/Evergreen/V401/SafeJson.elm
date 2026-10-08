module Evergreen.V401.SafeJson exposing (..)

import Dict
import Evergreen.V401.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V401.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
