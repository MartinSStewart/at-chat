module Evergreen.V408.Drawing exposing (..)

import Date
import Evergreen.V408.CssPixels
import Evergreen.V408.FileStatus
import Evergreen.V408.Id
import Evergreen.V408.Point2d
import Evergreen.V408.SafeFloat
import Evergreen.V408.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V408.SafeFloat.SafeFloat, Evergreen.V408.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V408.SafeFloat.SafeFloat, Evergreen.V408.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V408.Id.Id Evergreen.V408.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V408.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V408.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V408.SafeFloat.SafeFloat, Evergreen.V408.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V408.SafeFloat.SafeFloat, Evergreen.V408.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V408.SafeFloat.SafeFloat, Evergreen.V408.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V408.SafeFloat.SafeFloat, Evergreen.V408.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V408.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V408.Point2d.Point2d Evergreen.V408.CssPixels.CssPixels Evergreen.V408.Touch.ScreenCoordinate
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
