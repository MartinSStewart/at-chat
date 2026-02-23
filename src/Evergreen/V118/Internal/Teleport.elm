module Evergreen.V118.Internal.Teleport exposing (..)


type Trigger
    = OnHover
    | OnRender
    | OnFocus
    | OnFocusWithin
    | OnActive
    | OnDismount


type alias CssAnimation =
    { trigger : String
    , hash : String
    , keyframesHash : String
    , keyframes : String
    , transition : String
    , props : List ( String, String )
    }


type alias ParentTriggerDetails =
    { trigger : String
    , identifierClass : String
    , children : List CssAnimation
    }


type Data
    = Css CssAnimation
    | ParentTrigger ParentTriggerDetails


type alias Event =
    { timestamp : Float
    , data : List Data
    }
