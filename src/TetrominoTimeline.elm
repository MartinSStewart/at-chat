module TetrominoTimeline exposing (Timeline, init, latest, stateAt, update)

{-| Keeps recent states of a match so that an input arriving late (it was stamped with a frame
this client has already simulated) only costs re-simulating from just before that frame.
-}

import Array exposing (Array)
import Dict exposing (Dict)
import TetrominoSim exposing (InputEvent, MatchState)


type alias Timeline =
    { seed : Int
    , initial : MatchState
    , cache : List MatchState
    , inputs : Array InputEvent
    , inputsByFrame : Dict Int (List InputEvent)
    , target : Int
    }


init : Int -> Timeline
init seed =
    { seed = seed
    , initial = TetrominoSim.init seed
    , cache = []
    , inputs = Array.empty
    , inputsByFrame = Dict.empty
    , target = 0
    }


{-| How many frames back every state is kept. Inputs further back than this still work, they
just mean re-simulating from the last checkpoint.
-}
recentFrames : Int
recentFrames =
    2 * TetrominoSim.framesPerSecond


checkpointInterval : Int
checkpointInterval =
    10 * TetrominoSim.framesPerSecond


{-| Simulating a long match from the start is spread over several calls so that the page keeps
drawing while it catches up.
-}
maxStepsPerUpdate : Int
maxStepsPerUpdate =
    3000


latest : Timeline -> MatchState
latest timeline =
    case timeline.cache of
        state :: _ ->
            state

        [] ->
            timeline.initial


{-| The match as it was on a frame that has already been simulated, if it is still cached. The
end-to-end test uses it to compare two clients that are showing the match at slightly different
frames.
-}
stateAt : Int -> Timeline -> Maybe MatchState
stateAt frame timeline =
    List.filter (\state -> state.frame == frame) timeline.cache |> List.head


update : Int -> Array InputEvent -> Timeline -> Timeline
update targetFrame inputs timeline =
    let
        timeline2 : Timeline
        timeline2 =
            if inputs == timeline.inputs then
                timeline

            else
                let
                    changedFrom : Int
                    changedFrom =
                        firstDifference 0 timeline.inputs inputs

                    earliestChangedFrame : Int
                    earliestChangedFrame =
                        Array.append
                            (Array.slice changedFrom (Array.length timeline.inputs) timeline.inputs)
                            (Array.slice changedFrom (Array.length inputs) inputs)
                            |> Array.foldl (\event earliest -> min earliest event.frame) targetFrame
                in
                { timeline
                    | cache = List.filter (\state -> state.frame <= earliestChangedFrame) timeline.cache
                    , inputs = inputs
                    , inputsByFrame =
                        Array.foldr
                            (\event dict ->
                                Dict.update
                                    event.frame
                                    (\maybeList -> Just (event :: Maybe.withDefault [] maybeList))
                                    dict
                            )
                            Dict.empty
                            inputs
                }

        cache : List MatchState
        cache =
            dropWhile (\state -> state.frame > targetFrame) timeline2.cache

        start : MatchState
        start =
            case cache of
                state :: _ ->
                    state

                [] ->
                    timeline2.initial

        end : Int
        end =
            min targetFrame (start.frame + maxStepsPerUpdate)

        cache2 : List MatchState
        cache2 =
            simulate end timeline2.inputsByFrame start cache
    in
    { timeline2
        | cache =
            case cache2 of
                newest :: _ ->
                    List.filter
                        (\state -> newest.frame - state.frame <= recentFrames || modBy checkpointInterval state.frame == 0)
                        cache2

                [] ->
                    cache2
        , target = targetFrame
    }


simulate : Int -> Dict Int (List InputEvent) -> MatchState -> List MatchState -> List MatchState
simulate end inputsByFrame state cache =
    if state.frame >= end then
        cache

    else
        let
            state2 : MatchState
            state2 =
                TetrominoSim.step (Dict.get state.frame inputsByFrame |> Maybe.withDefault []) state
        in
        simulate
            end
            inputsByFrame
            state2
            (if end - state2.frame <= recentFrames || modBy checkpointInterval state2.frame == 0 then
                state2 :: cache

             else
                cache
            )


firstDifference : Int -> Array InputEvent -> Array InputEvent -> Int
firstDifference index old new =
    case ( Array.get index old, Array.get index new ) of
        ( Just oldEvent, Just newEvent ) ->
            if oldEvent == newEvent then
                firstDifference (index + 1) old new

            else
                index

        _ ->
            index


dropWhile : (a -> Bool) -> List a -> List a
dropWhile predicate list =
    case list of
        head :: rest ->
            if predicate head then
                dropWhile predicate rest

            else
                list

        [] ->
            []
