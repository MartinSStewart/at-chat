module Local exposing (ChangeId, Local, init, model, networkError, update, updateFromBackend)

import Dict exposing (Dict)
import Duration
import Env
import MyUi
import Quantity
import Time
import Ui exposing (Element)
import Ui.Font
import Ui.Prose
import Ui.Shadow


type Local msg model
    = Local
        { localMsgs : Dict Int { createdAt : Time.Posix, msg : msg }
        , localModel : model
        , serverModel : model
        , counter : ChangeId
        }


type ChangeId
    = ChangeId Int


increment : ChangeId -> ChangeId
increment (ChangeId a) =
    ChangeId (a + 1)


toInt : ChangeId -> Int
toInt (ChangeId a) =
    a


init : model -> Local msg model
init model2 =
    Local { localMsgs = Dict.empty, localModel = model2, serverModel = model2, counter = ChangeId 0 }


update : (msg -> model -> model) -> Time.Posix -> msg -> Local msg model -> ( ChangeId, Local msg model )
update userUpdate time msg (Local localModel_) =
    ( localModel_.counter
    , Local
        { localMsgs = Dict.insert (toInt localModel_.counter) { createdAt = time, msg = msg } localModel_.localMsgs
        , localModel = userUpdate msg localModel_.localModel
        , serverModel = localModel_.serverModel
        , counter = increment localModel_.counter
        }
    )


model : Local msg model -> model
model (Local localModel_) =
    localModel_.localModel


updateFromBackend :
    (msg -> model -> model)
    -> Maybe ChangeId
    -> msg
    -> Local msg model
    -> Local msg model
updateFromBackend userUpdate maybeChangeId msg (Local localModel_) =
    let
        newModel : model
        newModel =
            userUpdate msg localModel_.serverModel

        newLocalMsgs : Dict Int { createdAt : Time.Posix, msg : msg }
        newLocalMsgs =
            case maybeChangeId of
                Just changeId ->
                    Dict.remove (toInt changeId) localModel_.localMsgs

                Nothing ->
                    localModel_.localMsgs
    in
    Local
        { localMsgs = newLocalMsgs
        , localModel = Dict.foldl (\_ localMsg state -> userUpdate localMsg.msg state) newModel newLocalMsgs
        , serverModel = newModel
        , counter = localModel_.counter
        }


networkError : (msg -> String) -> Time.Posix -> Local msg model -> Element msg2
networkError msgToString currentTime (Local localModel_) =
    let
        hasNetworkIssue : Bool
        hasNetworkIssue =
            Dict.values localModel_.localMsgs
                |> List.any (\a -> Duration.from a.createdAt currentTime |> Quantity.greaterThan (Duration.seconds 10))
    in
    if hasNetworkIssue then
        Ui.column
            [ Ui.background (Ui.rgb 77 42 42)
            , Ui.centerX
            , Ui.alignBottom
            , Ui.paddingXY 16 8
            , Ui.rounded 8
            , Ui.border 1
            , Ui.borderColor (Ui.rgb 40 26 26)
            , Ui.Shadow.shadows
                [ { color = Ui.rgba 0 0 0 0.2, x = 0, y = 0, blur = 6, size = -1 }
                , { color = Ui.rgba 0 0 0 0.2, x = 0, y = 0, blur = 4, size = -2 }
                ]
            , Ui.move { x = 0, y = -4, z = 0 }
            ]
            [ Ui.el
                [ Ui.Font.bold ]
                (Ui.text "Unable to reach the server. The following are not saved:")
            , Dict.values localModel_.localMsgs
                |> List.map (\{ msg } -> Ui.Prose.item [] (Ui.text (msgToString msg)))
                |> Ui.Prose.bulleted
                    [ Ui.spacing 4
                    , Ui.Font.size 14
                    , Ui.paddingLeft 16
                    , Ui.scrollable
                    , Ui.heightMax 100
                    ]
                |> Ui.el [ Ui.paddingWith { left = 0, right = 0, top = 4, bottom = 4 } ]
            ]

    else
        Ui.none
