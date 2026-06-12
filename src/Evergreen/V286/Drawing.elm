module Evergreen.V286.Drawing exposing (..)

import Date
import Evergreen.V286.CssPixels
import Evergreen.V286.FileStatus
import Evergreen.V286.Id
import Evergreen.V286.Point2d
import Evergreen.V286.Touch
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
    | ImageAttachmentAnchor (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId)
    | EmbedImageAnchor Int


type AnchorType
    = MessageAnchor Evergreen.V286.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V286.Id.ThreadRoute Date.Date


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
    { guildOrDmId : Evergreen.V286.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V286.Point2d.Point2d Evergreen.V286.CssPixels.CssPixels Evergreen.V286.Touch.ScreenCoordinate
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
