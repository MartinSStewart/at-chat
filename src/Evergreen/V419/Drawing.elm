module Evergreen.V419.Drawing exposing (..)

import Date
import Evergreen.V419.CssPixels
import Evergreen.V419.FileStatus
import Evergreen.V419.Id
import Evergreen.V419.Point2d
import Evergreen.V419.SafeFloat
import Evergreen.V419.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V419.SafeFloat.SafeFloat, Evergreen.V419.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V419.SafeFloat.SafeFloat, Evergreen.V419.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V419.Id.Id Evergreen.V419.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V419.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V419.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V419.SafeFloat.SafeFloat, Evergreen.V419.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V419.SafeFloat.SafeFloat, Evergreen.V419.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V419.SafeFloat.SafeFloat, Evergreen.V419.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V419.SafeFloat.SafeFloat, Evergreen.V419.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V419.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V419.Point2d.Point2d Evergreen.V419.CssPixels.CssPixels Evergreen.V419.Touch.ScreenCoordinate
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
