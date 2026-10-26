module Evergreen.V414.Drawing exposing (..)

import Date
import Evergreen.V414.CssPixels
import Evergreen.V414.FileStatus
import Evergreen.V414.Id
import Evergreen.V414.Point2d
import Evergreen.V414.SafeFloat
import Evergreen.V414.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V414.SafeFloat.SafeFloat, Evergreen.V414.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V414.SafeFloat.SafeFloat, Evergreen.V414.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V414.Id.Id Evergreen.V414.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V414.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V414.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V414.SafeFloat.SafeFloat, Evergreen.V414.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V414.SafeFloat.SafeFloat, Evergreen.V414.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V414.SafeFloat.SafeFloat, Evergreen.V414.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V414.SafeFloat.SafeFloat, Evergreen.V414.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V414.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V414.Point2d.Point2d Evergreen.V414.CssPixels.CssPixels Evergreen.V414.Touch.ScreenCoordinate
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
