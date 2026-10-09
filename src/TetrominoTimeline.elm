module TetrominoTimeline exposing (Timeline, addInput, advance, init, latest, recent, removeInput, stateAt)

{-| Keeps the last couple of seconds of a match, one state per frame, so that an input arriving
late (stamped with a frame this client has already simulated) only costs re-simulating from just
before that frame.
-}

import Dict exposing (Dict)
import TetrominoSim exposing (InputEvent, MatchState)


type alias Timeline =
    { latest : MatchState
    , previous : List MatchState
    , inputs : Dict Int (List InputEvent)
    }


{-| Start from a state some other player had, or a brand new match.
-}
init : MatchState -> Timeline
init state =
    { latest = state, previous = [], inputs = Dict.empty }


{-| How many frames back every state is kept. The backend never accepts an input stamped
further back than a fraction of this.
-}
recentFrames : Int
recentFrames =
    2 * TetrominoSim.framesPerSecond


latest : Timeline -> MatchState
latest timeline =
    timeline.latest


{-| Every state kept, newest first.
-}
recent : Timeline -> List MatchState
recent timeline =
    timeline.latest :: timeline.previous


{-| The match as it was at the start of a frame, before that frame's inputs, if it's recent
enough to still be kept.
-}
stateAt : Int -> Timeline -> Maybe MatchState
stateAt frame timeline =
    List.filter (\state -> state.frame == frame) (timeline.latest :: timeline.previous) |> List.head


{-| Note an input, winding back to the frame it's stamped with if that has already been
simulated. The same input arriving twice only counts once.
-}
addInput : InputEvent -> Timeline -> Timeline
addInput event timeline =
    if List.member event (Dict.get event.frame timeline.inputs |> Maybe.withDefault []) then
        timeline

    else
        let
            inputs : Dict Int (List InputEvent)
            inputs =
                Dict.update
                    event.frame
                    (\maybeList -> Just (Maybe.withDefault [] maybeList ++ [ event ]))
                    timeline.inputs
        in
        windBack event.frame { timeline | inputs = inputs }


{-| Take back an input this client guessed at, winding back to its frame if that has already
been simulated.
-}
removeInput : InputEvent -> Timeline -> Timeline
removeInput event timeline =
    case Dict.get event.frame timeline.inputs of
        Just events ->
            if List.member event events then
                let
                    inputs : Dict Int (List InputEvent)
                    inputs =
                        Dict.insert event.frame (List.filter (\other -> other /= event) events) timeline.inputs
                in
                windBack event.frame { timeline | inputs = inputs }

            else
                timeline

        Nothing ->
            timeline


{-| Go back to the start of a frame so that it gets simulated again, if the state then is still
kept.
-}
windBack : Int -> Timeline -> Timeline
windBack frame timeline =
    if frame < timeline.latest.frame then
        case dropWhile (\state -> state.frame > frame) timeline.previous of
            state :: rest ->
                { timeline | latest = state, previous = rest }

            [] ->
                timeline

    else
        timeline


{-| Simulate up to the given frame and forget whatever has fallen out of the recent window.
-}
advance : Int -> Timeline -> Timeline
advance targetFrame timeline =
    let
        ( newest, previous ) =
            simulate targetFrame timeline.inputs timeline.latest timeline.previous

        previous2 : List MatchState
        previous2 =
            List.filter (\state -> newest.frame - state.frame <= recentFrames) previous

        oldestFrame : Int
        oldestFrame =
            List.foldl (\state oldest -> min oldest state.frame) newest.frame previous2
    in
    { latest = newest
    , previous = previous2
    , inputs = Dict.filter (\frame _ -> frame >= oldestFrame) timeline.inputs
    }


simulate : Int -> Dict Int (List InputEvent) -> MatchState -> List MatchState -> ( MatchState, List MatchState )
simulate targetFrame inputs state previous =
    if state.frame >= targetFrame then
        ( state, previous )

    else
        simulate
            targetFrame
            inputs
            (TetrominoSim.step (Dict.get state.frame inputs |> Maybe.withDefault []) state)
            (if targetFrame - state.frame <= recentFrames then
                state :: previous

             else
                previous
            )


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
