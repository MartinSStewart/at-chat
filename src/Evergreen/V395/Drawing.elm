module Evergreen.V395.Drawing exposing (..)

import Date
import Evergreen.V395.CssPixels
import Evergreen.V395.FileStatus
import Evergreen.V395.Id
import Evergreen.V395.Point2d
import Evergreen.V395.SafeFloat
import Evergreen.V395.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V395.SafeFloat.SafeFloat, Evergreen.V395.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V395.SafeFloat.SafeFloat, Evergreen.V395.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V395.Id.Id Evergreen.V395.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V395.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V395.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V395.SafeFloat.SafeFloat, Evergreen.V395.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V395.SafeFloat.SafeFloat, Evergreen.V395.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V395.SafeFloat.SafeFloat, Evergreen.V395.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V395.SafeFloat.SafeFloat, Evergreen.V395.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V395.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V395.Point2d.Point2d Evergreen.V395.CssPixels.CssPixels Evergreen.V395.Touch.ScreenCoordinate
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
