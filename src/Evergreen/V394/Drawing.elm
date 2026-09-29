module Evergreen.V394.Drawing exposing (..)

import Date
import Evergreen.V394.CssPixels
import Evergreen.V394.FileStatus
import Evergreen.V394.Id
import Evergreen.V394.Point2d
import Evergreen.V394.SafeFloat
import Evergreen.V394.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V394.SafeFloat.SafeFloat, Evergreen.V394.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V394.SafeFloat.SafeFloat, Evergreen.V394.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V394.Id.Id Evergreen.V394.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V394.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V394.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V394.SafeFloat.SafeFloat, Evergreen.V394.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V394.SafeFloat.SafeFloat, Evergreen.V394.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V394.SafeFloat.SafeFloat, Evergreen.V394.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V394.SafeFloat.SafeFloat, Evergreen.V394.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V394.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V394.Point2d.Point2d Evergreen.V394.CssPixels.CssPixels Evergreen.V394.Touch.ScreenCoordinate
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
