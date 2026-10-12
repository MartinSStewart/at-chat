module Evergreen.V405.Drawing exposing (..)

import Date
import Evergreen.V405.CssPixels
import Evergreen.V405.FileStatus
import Evergreen.V405.Id
import Evergreen.V405.Point2d
import Evergreen.V405.SafeFloat
import Evergreen.V405.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V405.SafeFloat.SafeFloat, Evergreen.V405.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V405.SafeFloat.SafeFloat, Evergreen.V405.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V405.Id.Id Evergreen.V405.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V405.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V405.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V405.SafeFloat.SafeFloat, Evergreen.V405.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V405.SafeFloat.SafeFloat, Evergreen.V405.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V405.SafeFloat.SafeFloat, Evergreen.V405.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V405.SafeFloat.SafeFloat, Evergreen.V405.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V405.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V405.Point2d.Point2d Evergreen.V405.CssPixels.CssPixels Evergreen.V405.Touch.ScreenCoordinate
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
