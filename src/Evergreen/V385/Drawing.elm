module Evergreen.V385.Drawing exposing (..)

import Date
import Evergreen.V385.CssPixels
import Evergreen.V385.FileStatus
import Evergreen.V385.Id
import Evergreen.V385.Point2d
import Evergreen.V385.SafeFloat
import Evergreen.V385.Touch
import List.Nonempty
import SeqDict


type Msg
    = PointerDown Float Float
    | PointerMoved Float Float
    | PointerUp
    | PressedUndo
    | PressedRedo
    | PressedZoom
    | GotZoomContainer
        (Maybe
            { x : Float
            , y : Float
            , width : Float
            , height : Float
            }
        )
    | PressedDone


type alias Stroke =
    { points : List.Nonempty.Nonempty ( Evergreen.V385.SafeFloat.SafeFloat, Evergreen.V385.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V385.SafeFloat.SafeFloat, Evergreen.V385.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V385.Id.Id Evergreen.V385.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V385.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V385.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V385.SafeFloat.SafeFloat, Evergreen.V385.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V385.SafeFloat.SafeFloat, Evergreen.V385.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V385.SafeFloat.SafeFloat, Evergreen.V385.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V385.SafeFloat.SafeFloat, Evergreen.V385.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V385.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V385.Point2d.Point2d Evergreen.V385.CssPixels.CssPixels Evergreen.V385.Touch.ScreenCoordinate
    , pointScale : Float
    , stroke : Maybe ActiveStroke
    , anchorHalfSize : ( Float, Float )
    , zoom : Float
    , zoomContainer :
        Maybe
            { x : Float
            , y : Float
            , width : Float
            , height : Float
            }
    }


type Model
    = NoSelectedAnchor
    | SelectedAnchor SelectedAnchorData
