module Evergreen.V285.Drawing exposing (..)

import Date
import Evergreen.V285.CssPixels
import Evergreen.V285.FileStatus
import Evergreen.V285.Id
import Evergreen.V285.Point2d
import Evergreen.V285.Touch
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
    | ImageAttachmentAnchor (Evergreen.V285.Id.Id Evergreen.V285.FileStatus.FileId)


type AnchorType
    = MessageAnchor Evergreen.V285.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V285.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Float, Float )
    | ContinueStroke (List.Nonempty.Nonempty ( Float, Float ))
    | EndStroke
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Float, Float )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V285.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V285.Point2d.Point2d Evergreen.V285.CssPixels.CssPixels Evergreen.V285.Touch.ScreenCoordinate
    , stroke : Maybe ActiveStroke
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
