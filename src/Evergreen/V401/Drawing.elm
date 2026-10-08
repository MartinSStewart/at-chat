module Evergreen.V401.Drawing exposing (..)

import Date
import Evergreen.V401.CssPixels
import Evergreen.V401.FileStatus
import Evergreen.V401.Id
import Evergreen.V401.Point2d
import Evergreen.V401.SafeFloat
import Evergreen.V401.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V401.SafeFloat.SafeFloat, Evergreen.V401.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V401.SafeFloat.SafeFloat, Evergreen.V401.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V401.Id.Id Evergreen.V401.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V401.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V401.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V401.SafeFloat.SafeFloat, Evergreen.V401.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V401.SafeFloat.SafeFloat, Evergreen.V401.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V401.SafeFloat.SafeFloat, Evergreen.V401.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V401.SafeFloat.SafeFloat, Evergreen.V401.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V401.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V401.Point2d.Point2d Evergreen.V401.CssPixels.CssPixels Evergreen.V401.Touch.ScreenCoordinate
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
