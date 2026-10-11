module Evergreen.V403.Drawing exposing (..)

import Date
import Evergreen.V403.CssPixels
import Evergreen.V403.FileStatus
import Evergreen.V403.Id
import Evergreen.V403.Point2d
import Evergreen.V403.SafeFloat
import Evergreen.V403.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V403.SafeFloat.SafeFloat, Evergreen.V403.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V403.SafeFloat.SafeFloat, Evergreen.V403.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V403.Id.Id Evergreen.V403.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V403.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V403.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V403.SafeFloat.SafeFloat, Evergreen.V403.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V403.SafeFloat.SafeFloat, Evergreen.V403.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V403.SafeFloat.SafeFloat, Evergreen.V403.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V403.SafeFloat.SafeFloat, Evergreen.V403.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V403.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V403.Point2d.Point2d Evergreen.V403.CssPixels.CssPixels Evergreen.V403.Touch.ScreenCoordinate
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
