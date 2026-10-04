module Evergreen.V397.SafeJson exposing (..)

import Dict
import Evergreen.V397.SafeFloat


type SafeJson
    = JsonString String
    | JsonNumber Evergreen.V397.SafeFloat.SafeFloat
    | JsonBool Bool
    | JsonObject (Dict.Dict String SafeJson)
    | JsonArray (List SafeJson)
    | JsonNull
