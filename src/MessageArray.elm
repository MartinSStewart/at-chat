module MessageArray exposing
    ( MessageArray
    , empty
    , findRight
    , foldr
    , fromArray
    , get
    , isEmpty
    , last
    , length
    , push
    , set
    , setMany
    , slice
    , toList
    , update
    )

{-| An array indexed by `Id` where only some of the indices actually contain a
value. It's used for the messages in a channel on the frontend, where the array
spans every message in the channel but only the messages the user has scrolled to
are actually loaded.

The obvious approach, an `IdArray` holding a placeholder at every unloaded index,
means a channel containing 10k messages allocates (and, since the frontend
channels are created on the backend, serializes) 10k values just to say "not
loaded". Instead only the loaded values are stored, grouped into contiguous runs.
Loaded messages are usually contiguous (the newest page of messages, plus
whatever the user has scrolled back through), so there are typically only a
handful of runs no matter how many messages the channel contains. Messages that
sit on their own, such as the thread starters or the message someone replied to,
just add another small run.

Runs are kept sorted, non-empty, and never touching (two runs that grow into each
other are merged), so a lookup is a binary search over the runs and `slice` costs
the size of the slice instead of the size of the channel.

-}

import Array exposing (Array)
import Id exposing (Id)


{-| OpaqueVariants

`start` and `end` are the range of indices this array spans (`start` is
inclusive, `end` is exclusive). `start` is only ever non-zero for the result of
`slice`, which keeps the indices of the values it contains rather than rebasing
them to zero.

-}
type MessageArray k v
    = MessageArray
        { start : Int
        , end : Int
        , runs : Array (Run v)
        }


{-| A group of values at consecutive indices. `values` is never empty.
-}
type alias Run v =
    { start : Int, values : Array v }


empty : MessageArray k v
empty =
    MessageArray { start = 0, end = 0, runs = Array.empty }


{-| An array spanning `count` indices, where `values` is loaded starting at
`start` and everything else is unloaded.
-}
fromArray : Int -> Id k -> Array v -> MessageArray k v
fromArray count startId values =
    let
        end : Int
        end =
            max 0 count

        start : Int
        start =
            Id.toInt startId |> clamp 0 end

        clipped : Array v
        clipped =
            Array.slice 0 (min (Array.length values) (end - start)) values
    in
    MessageArray
        { start = 0
        , end = end
        , runs =
            if Array.isEmpty clipped then
                Array.empty

            else
                Array.repeat 1 { start = start, values = clipped }
        }


{-| The number of indices this array spans, loaded or not.
-}
length : MessageArray k v -> Int
length (MessageArray array) =
    array.end - array.start


isEmpty : MessageArray k v -> Bool
isEmpty (MessageArray array) =
    array.end <= array.start


{-| `Nothing` means the index is either out of range or not loaded.
-}
get : Id k -> MessageArray k v -> Maybe v
get id (MessageArray array) =
    let
        index : Int
        index =
            Id.toInt id
    in
    if index < array.start || index >= array.end then
        Nothing

    else
        case Array.get (lowerBound index array.runs) array.runs of
            Just run ->
                if run.start <= index then
                    Array.get (index - run.start) run.values

                else
                    Nothing

            Nothing ->
                Nothing


{-| Loads a value at the given index. Does nothing if the index is out of range.
-}
set : Id k -> v -> MessageArray k v -> MessageArray k v
set id value (MessageArray array) =
    let
        index : Int
        index =
            Id.toInt id
    in
    if index < array.start || index >= array.end then
        MessageArray array

    else
        let
            position : Int
            position =
                lowerBound index array.runs
        in
        case Array.get position array.runs of
            Just run ->
                if run.start <= index then
                    MessageArray
                        { array
                            | runs =
                                Array.set
                                    position
                                    { run | values = Array.set (index - run.start) value run.values }
                                    array.runs
                        }

                else
                    MessageArray { array | runs = insertAt index value position array.runs }

            Nothing ->
                MessageArray { array | runs = insertAt index value position array.runs }


{-| Loads a batch of values at once. Equivalent to folding `set` over the list,
but the runs are only rebuilt once instead of once per value, which matters when
loading something like the thread starters of a channel that has a lot of
threads. If the same index appears twice, the value later in the list wins.
-}
setMany : List ( Id k, v ) -> MessageArray k v -> MessageArray k v
setMany entries (MessageArray array) =
    case
        List.filterMap
            (\( id, value ) ->
                let
                    index : Int
                    index =
                        Id.toInt id
                in
                if index < array.start || index >= array.end then
                    Nothing

                else
                    Just ( index, value )
            )
            entries
            |> List.sortBy Tuple.first
            |> dropShadowed []
    of
        [] ->
            MessageArray array

        sorted ->
            let
                ( loadedRuns, gaps ) =
                    replaceLoaded sorted (Array.toList array.runs) [] []
            in
            MessageArray
                { array | runs = mergeRuns loadedRuns (gapsToRuns gaps) [] |> Array.fromList }


{-| Changes a value if it's loaded. Does nothing otherwise.
-}
update : Id k -> (v -> v) -> MessageArray k v -> MessageArray k v
update id updateFunc array =
    case get id array of
        Just value ->
            set id (updateFunc value) array

        Nothing ->
            array


{-| Grows the array by one index and loads `value` into it.
-}
push : v -> MessageArray k v -> MessageArray k v
push value (MessageArray array) =
    set (Id.fromInt array.end) value (MessageArray { array | end = array.end + 1 })


{-| The value at the last index, if that index is loaded.
-}
last : MessageArray k v -> Maybe v
last (MessageArray array) =
    get (Id.fromInt (array.end - 1)) (MessageArray array)


{-| The values in the `[start, end)` range of indices. The result keeps the
indices the values had in the original array, so folding over a slice hands back
the same ids as folding over the whole thing.
-}
slice : Id k -> Id k -> MessageArray k v -> MessageArray k v
slice startId endId (MessageArray array) =
    let
        start : Int
        start =
            Id.toInt startId |> clamp array.start array.end

        end : Int
        end =
            Id.toInt endId |> clamp start array.end
    in
    if end <= start then
        MessageArray { start = start, end = start, runs = Array.empty }

    else
        MessageArray
            { start = start
            , end = end
            , runs =
                Array.slice
                    (lowerBound start array.runs)
                    (upperBound end array.runs)
                    array.runs
                    |> Array.map (clipRun start end)
            }


{-| Folds over every index in the array, starting at the last one. Indices that
aren't loaded are handed to the fold function as `Nothing`.
-}
foldr : (Id k -> Maybe v -> b -> b) -> b -> MessageArray k v -> b
foldr foldFunc startingValue (MessageArray array) =
    foldrHelper
        foldFunc
        (Array.length array.runs - 1)
        (array.end - 1)
        array.start
        array.runs
        startingValue


{-| Every loaded value paired with its index, in ascending index order.
-}
toList : MessageArray k v -> List ( Id k, v )
toList (MessageArray array) =
    Array.foldr
        (\run list ->
            Array.foldr
                (\value ( index, list2 ) -> ( index - 1, ( Id.fromInt index, value ) :: list2 ))
                ( runEnd run - 1, list )
                run.values
                |> Tuple.second
        )
        []
        array.runs


{-| The last loaded value that passes the given test, searching backwards from
the end of the array. Unloaded indices are skipped over.
-}
findRight : (v -> Bool) -> MessageArray k v -> Maybe ( Id k, v )
findRight selectFunc (MessageArray array) =
    findRightHelper selectFunc (Array.length array.runs - 1) array.runs



-- Internals


runEnd : Run v -> Int
runEnd run =
    run.start + Array.length run.values


{-| The position of the first run that ends after `index`. Equal to the number of
runs if every run ends at or before it.
-}
lowerBound : Int -> Array (Run v) -> Int
lowerBound index runs =
    lowerBoundHelper index 0 (Array.length runs) runs


lowerBoundHelper : Int -> Int -> Int -> Array (Run v) -> Int
lowerBoundHelper index low high runs =
    if low >= high then
        low

    else
        let
            middle : Int
            middle =
                low + (high - low) // 2
        in
        case Array.get middle runs of
            Just run ->
                if runEnd run <= index then
                    lowerBoundHelper index (middle + 1) high runs

                else
                    lowerBoundHelper index low middle runs

            Nothing ->
                low


{-| The position of the first run that starts at or after `index`. Equal to the
number of runs if every run starts before it.
-}
upperBound : Int -> Array (Run v) -> Int
upperBound index runs =
    upperBoundHelper index 0 (Array.length runs) runs


upperBoundHelper : Int -> Int -> Int -> Array (Run v) -> Int
upperBoundHelper index low high runs =
    if low >= high then
        low

    else
        let
            middle : Int
            middle =
                low + (high - low) // 2
        in
        case Array.get middle runs of
            Just run ->
                if run.start < index then
                    upperBoundHelper index (middle + 1) high runs

                else
                    upperBoundHelper index low middle runs

            Nothing ->
                low


{-| Keeps only the last of any entries that share an index, so that later entries
win over earlier ones. Takes an ascending list and hands back an ascending one.
-}
dropShadowed : List ( Int, v ) -> List ( Int, v ) -> List ( Int, v )
dropShadowed reversed entries =
    case entries of
        (( index, _ ) as entry) :: rest ->
            case rest of
                ( nextIndex, _ ) :: _ ->
                    if index == nextIndex then
                        dropShadowed reversed rest

                    else
                        dropShadowed (entry :: reversed) rest

                [] ->
                    List.reverse (entry :: reversed)

        [] ->
            List.reverse reversed


{-| Writes the entries that land on an already loaded index straight into the run
holding them, and sets the rest aside. Both lists are ascending; the entries that
were set aside come back descending.
-}
replaceLoaded :
    List ( Int, v )
    -> List (Run v)
    -> List (Run v)
    -> List ( Int, v )
    -> ( List (Run v), List ( Int, v ) )
replaceLoaded entries runs passedRuns gaps =
    case runs of
        run :: restRuns ->
            case entries of
                ( index, value ) :: restEntries ->
                    if index < run.start then
                        replaceLoaded restEntries runs passedRuns (( index, value ) :: gaps)

                    else if index < runEnd run then
                        replaceLoaded
                            restEntries
                            ({ run | values = Array.set (index - run.start) value run.values } :: restRuns)
                            passedRuns
                            gaps

                    else
                        replaceLoaded entries restRuns (run :: passedRuns) gaps

                [] ->
                    ( List.reverse passedRuns ++ runs, gaps )

        [] ->
            ( List.reverse passedRuns, List.foldl (::) gaps entries )


{-| Groups entries that aren't inside any existing run into runs of their own.
Takes a descending list and hands back an ascending one.
-}
gapsToRuns : List ( Int, v ) -> List (Run v)
gapsToRuns gaps =
    List.foldl
        (\( index, value ) runs ->
            case runs of
                run :: restRuns ->
                    if runEnd run == index then
                        { run | values = Array.push value run.values } :: restRuns

                    else
                        { start = index, values = Array.repeat 1 value } :: runs

                [] ->
                    [ { start = index, values = Array.repeat 1 value } ]
        )
        []
        (List.reverse gaps)
        |> List.reverse


{-| Merges two ascending lists of runs that don't overlap each other, joining any
runs that turn out to be adjacent.
-}
mergeRuns : List (Run v) -> List (Run v) -> List (Run v) -> List (Run v)
mergeRuns runsA runsB reversed =
    case ( runsA, runsB ) of
        ( runA :: restA, runB :: restB ) ->
            if runA.start < runB.start then
                mergeRuns restA runsB (appendRun runA reversed)

            else
                mergeRuns runsA restB (appendRun runB reversed)

        ( runA :: restA, [] ) ->
            mergeRuns restA [] (appendRun runA reversed)

        ( [], runB :: restB ) ->
            mergeRuns [] restB (appendRun runB reversed)

        ( [], [] ) ->
            List.reverse reversed


{-| Adds a run to a descending list of runs, joining it onto the previous run if
the two are adjacent.
-}
appendRun : Run v -> List (Run v) -> List (Run v)
appendRun run reversed =
    case reversed of
        previous :: rest ->
            if runEnd previous == run.start then
                { previous | values = Array.append previous.values run.values } :: rest

            else
                run :: reversed

        [] ->
            [ run ]


{-| Adds a value at an index that isn't loaded yet. `position` is where a run
containing only `index` would belong. If the neighbouring runs now touch this
index they absorb it instead, so runs never end up adjacent to each other.
-}
insertAt : Int -> v -> Int -> Array (Run v) -> Array (Run v)
insertAt index value position runs =
    let
        previous : Maybe (Run v)
        previous =
            case Array.get (position - 1) runs of
                Just run ->
                    if runEnd run == index then
                        Just run

                    else
                        Nothing

                Nothing ->
                    Nothing

        next : Maybe (Run v)
        next =
            case Array.get position runs of
                Just run ->
                    if run.start == index + 1 then
                        Just run

                    else
                        Nothing

                Nothing ->
                    Nothing
    in
    case ( previous, next ) of
        ( Just previous2, Just next2 ) ->
            Array.append
                (Array.slice 0 position runs
                    |> Array.set
                        (position - 1)
                        { previous2 | values = Array.append (Array.push value previous2.values) next2.values }
                )
                (Array.slice (position + 1) (Array.length runs) runs)

        ( Just previous2, Nothing ) ->
            Array.set (position - 1) { previous2 | values = Array.push value previous2.values } runs

        ( Nothing, Just next2 ) ->
            Array.set position { start = index, values = Array.append (Array.repeat 1 value) next2.values } runs

        ( Nothing, Nothing ) ->
            Array.append
                (Array.slice 0 position runs
                    |> Array.push { start = index, values = Array.repeat 1 value }
                )
                (Array.slice position (Array.length runs) runs)


{-| Drops the parts of a run that fall outside of `[start, end)`. Only ever
called on runs that overlap that range, so the result is never empty.
-}
clipRun : Int -> Int -> Run v -> Run v
clipRun start end run =
    if run.start >= start && runEnd run <= end then
        run

    else
        let
            from : Int
            from =
                max start run.start

            to : Int
            to =
                min end (runEnd run)
        in
        { start = from, values = Array.slice (from - run.start) (to - run.start) run.values }


foldrHelper : (Id k -> Maybe v -> b -> b) -> Int -> Int -> Int -> Array (Run v) -> b -> b
foldrHelper foldFunc runIndex index start runs state =
    if index < start then
        state

    else
        case Array.get runIndex runs of
            Just run ->
                if index >= runEnd run then
                    foldrHelper foldFunc runIndex (index - 1) start runs (foldFunc (Id.fromInt index) Nothing state)

                else if index >= run.start then
                    foldrHelper
                        foldFunc
                        runIndex
                        (index - 1)
                        start
                        runs
                        (foldFunc (Id.fromInt index) (Array.get (index - run.start) run.values) state)

                else
                    foldrHelper foldFunc (runIndex - 1) index start runs state

            Nothing ->
                foldrHelper foldFunc runIndex (index - 1) start runs (foldFunc (Id.fromInt index) Nothing state)


findRightHelper : (v -> Bool) -> Int -> Array (Run v) -> Maybe ( Id k, v )
findRightHelper selectFunc runIndex runs =
    case Array.get runIndex runs of
        Just run ->
            case findRightInRun selectFunc (Array.length run.values - 1) run of
                Just found ->
                    Just found

                Nothing ->
                    findRightHelper selectFunc (runIndex - 1) runs

        Nothing ->
            Nothing


findRightInRun : (v -> Bool) -> Int -> Run v -> Maybe ( Id k, v )
findRightInRun selectFunc index run =
    case Array.get index run.values of
        Just value ->
            if selectFunc value then
                Just ( Id.fromInt (run.start + index), value )

            else
                findRightInRun selectFunc (index - 1) run

        Nothing ->
            Nothing
