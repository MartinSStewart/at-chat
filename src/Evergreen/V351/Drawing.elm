module Evergreen.V351.Drawing exposing (..)

import Date
import Evergreen.V351.CssPixels
import Evergreen.V351.FileStatus
import Evergreen.V351.Id
import Evergreen.V351.Point2d
import Evergreen.V351.Touch
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
    { points : List.Nonempty.Nonempty ( Float, Float )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Float, Float )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V351.Id.Id Evergreen.V351.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V351.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V351.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Float, Float )
    | ContinueStroke (List.Nonempty.Nonempty ( Float, Float ))
    | EndStroke (List ( Float, Float ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Float, Float )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V351.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V351.Point2d.Point2d Evergreen.V351.CssPixels.CssPixels Evergreen.V351.Touch.ScreenCoordinate
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
