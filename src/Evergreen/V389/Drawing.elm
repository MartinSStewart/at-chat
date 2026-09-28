module Evergreen.V389.Drawing exposing (..)

import Date
import Evergreen.V389.CssPixels
import Evergreen.V389.FileStatus
import Evergreen.V389.Id
import Evergreen.V389.Point2d
import Evergreen.V389.SafeFloat
import Evergreen.V389.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V389.SafeFloat.SafeFloat, Evergreen.V389.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V389.SafeFloat.SafeFloat, Evergreen.V389.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V389.Id.Id Evergreen.V389.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V389.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V389.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V389.SafeFloat.SafeFloat, Evergreen.V389.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V389.SafeFloat.SafeFloat, Evergreen.V389.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V389.SafeFloat.SafeFloat, Evergreen.V389.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V389.SafeFloat.SafeFloat, Evergreen.V389.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V389.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V389.Point2d.Point2d Evergreen.V389.CssPixels.CssPixels Evergreen.V389.Touch.ScreenCoordinate
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
