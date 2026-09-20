module Evergreen.V384.Drawing exposing (..)

import Date
import Evergreen.V384.CssPixels
import Evergreen.V384.FileStatus
import Evergreen.V384.Id
import Evergreen.V384.Point2d
import Evergreen.V384.SafeFloat
import Evergreen.V384.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V384.SafeFloat.SafeFloat, Evergreen.V384.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V384.SafeFloat.SafeFloat, Evergreen.V384.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V384.Id.Id Evergreen.V384.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V384.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V384.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V384.SafeFloat.SafeFloat, Evergreen.V384.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V384.SafeFloat.SafeFloat, Evergreen.V384.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V384.SafeFloat.SafeFloat, Evergreen.V384.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V384.SafeFloat.SafeFloat, Evergreen.V384.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V384.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V384.Point2d.Point2d Evergreen.V384.CssPixels.CssPixels Evergreen.V384.Touch.ScreenCoordinate
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
