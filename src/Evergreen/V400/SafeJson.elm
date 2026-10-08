module Evergreen.V400.SafeJson exposing (..)

import Dict
import Evergreen.V400.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V400.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
