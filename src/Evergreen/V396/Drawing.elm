module Evergreen.V396.Drawing exposing (..)

import Date
import Evergreen.V396.CssPixels
import Evergreen.V396.FileStatus
import Evergreen.V396.Id
import Evergreen.V396.Point2d
import Evergreen.V396.SafeFloat
import Evergreen.V396.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V396.SafeFloat.SafeFloat, Evergreen.V396.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V396.SafeFloat.SafeFloat, Evergreen.V396.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V396.Id.Id Evergreen.V396.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V396.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V396.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V396.SafeFloat.SafeFloat, Evergreen.V396.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V396.SafeFloat.SafeFloat, Evergreen.V396.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V396.SafeFloat.SafeFloat, Evergreen.V396.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V396.SafeFloat.SafeFloat, Evergreen.V396.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V396.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V396.Point2d.Point2d Evergreen.V396.CssPixels.CssPixels Evergreen.V396.Touch.ScreenCoordinate
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
