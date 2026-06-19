module Evergreen.V290.Drawing exposing (..)

import Date
import Evergreen.V290.CssPixels
import Evergreen.V290.FileStatus
import Evergreen.V290.Id
import Evergreen.V290.Point2d
import Evergreen.V290.Touch
import List.Nonempty
import SeqDict


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
    | ImageAttachmentAnchor (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId)
    | EmbedImageAnchor Int


type AnchorType
    = MessageAnchor Evergreen.V290.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V290.Id.ThreadRoute Date.Date


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
    { guildOrDmId : Evergreen.V290.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V290.Point2d.Point2d Evergreen.V290.CssPixels.CssPixels Evergreen.V290.Touch.ScreenCoordinate
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


type Msg
    = MouseDown Float Float
    | MouseMoved Float Float
    | MouseUp
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
