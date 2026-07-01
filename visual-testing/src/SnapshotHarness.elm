port module SnapshotHarness exposing (main)

-- import SnapshotRunner
-- import Types exposing (..)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation
import E2ETests
import Effect.Snapshot exposing (Snapshot)
import Effect.Test as T
import Html
import List.Extra
import List.Nonempty
import Task
import Types exposing (FrontendMsg_)
import Url exposing (Url)


{-| Tell the JS harness we're ready to make a snapshot
-}
port respondReadyForSnapshot : { name : String, hasMore : Bool, width : Int, height : Int } -> Cmd msg


{-| Received request to advance to next snapshot
-}
port advanceSnapshotRequested : (() -> msg) -> Sub msg


type Msg frontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | AdvanceSnapshotRequested ()
    | UserMsg
    | GotSnapshotData (Result () (List (Snapshot frontendMsg)))


type alias Model frontendMsg =
    { currentIndex : Int, snapshots : Maybe (List (Snapshot frontendMsg)), gotFirstSnapshotRequest : Bool }


main : Program () (Model FrontendMsg_) (Msg FrontendMsg_)
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> advanceSnapshotRequested AdvanceSnapshotRequested
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        }


init : () -> Url -> Browser.Navigation.Key -> ( Model FrontendMsg_, Cmd (Msg FrontendMsg_) )
init _ _ _ =
    let
        _ =
            Debug.log "init" ()
    in
    ( { currentIndex = -1, snapshots = Nothing, gotFirstSnapshotRequest = False }
    , E2ETests.setup.cmds
        |> Task.mapError
            (\error ->
                let
                    _ =
                        Debug.log "Failed to load" error
                in
                ()
            )
        |> Task.map (List.concatMap T.toSnapshots)
        |> Task.attempt GotSnapshotData
    )


update : Msg FrontendMsg_ -> Model FrontendMsg_ -> ( Model FrontendMsg_, Cmd (Msg FrontendMsg_) )
update msg model =
    let
        _ =
            Debug.log "Msg" msg
    in
    case msg of
        UrlClicked _ ->
            ( model, Cmd.none )

        UrlChanged _ ->
            ( model, Cmd.none )

        AdvanceSnapshotRequested _ ->
            case model.snapshots of
                Just snapshots ->
                    respondReadyForSnapshotHelper snapshots model

                Nothing ->
                    ( { model | gotFirstSnapshotRequest = True }, Cmd.none )

        UserMsg ->
            ( model, Cmd.none )

        GotSnapshotData result ->
            case result of
                Ok snapshots ->
                    if model.gotFirstSnapshotRequest then
                        respondReadyForSnapshotHelper snapshots { model | snapshots = Just snapshots }

                    else
                        ( { model | snapshots = Just snapshots }, Cmd.none )

                Err () ->
                    ( model, Cmd.none )


respondReadyForSnapshotHelper : List (Snapshot frontendMsg) -> Model frontendMsg -> ( Model frontendMsg, Cmd msg )
respondReadyForSnapshotHelper snapshots model =
    case List.Extra.getAt (model.currentIndex + 1) snapshots of
        Just snapshot ->
            ( { model | currentIndex = model.currentIndex + 1 }
            , respondReadyForSnapshot
                { name =
                    snapshot.name
                        |> String.filter (\char -> Char.toCode char >= 32)
                        |> String.replace "/" "-"
                , hasMore = model.currentIndex < List.length snapshots
                , width = List.Nonempty.head snapshot.widths
                , height = Maybe.withDefault 1000 snapshot.minimumHeight
                }
            )

        Nothing ->
            ( model, respondReadyForSnapshot { name = "", hasMore = False, width = 1000, height = 1000 } )


view : Model frontendMsg -> Document (Msg frontendMsg)
view model =
    { title = ""
    , body =
        case model.snapshots of
            Just snapshots ->
                case List.Extra.getAt model.currentIndex snapshots of
                    Just snapshot ->
                        snapshot.body |> List.map (Html.map (\_ -> UserMsg))

                    Nothing ->
                        [ "snapshot missing: " ++ String.fromInt model.currentIndex |> Html.text ]

            Nothing ->
                [ Html.text "Loading data" ]
    }
