module MessageArrayTests exposing (tests)

import Array exposing (Array)
import Expect
import Fuzz exposing (Fuzzer)
import Id
import MessageArray exposing (MessageArray)
import Test exposing (Test)


{-| The tests compare a `MessageArray` against an `Array (Maybe Int)`, which is
the naive version of the same thing.
-}
type Op
    = Set Int Int
    | Update Int
    | Push Int


opFuzzer : Fuzzer Op
opFuzzer =
    Fuzz.oneOf
        [ Fuzz.map2 Set (Fuzz.intRange -2 30) (Fuzz.intRange 0 999)
        , Fuzz.map Update (Fuzz.intRange -2 30)
        , Fuzz.map Push (Fuzz.intRange 0 999)
        ]


applyToReference : Op -> Array (Maybe Int) -> Array (Maybe Int)
applyToReference op array =
    case op of
        Set index value ->
            if index >= 0 && index < Array.length array then
                Array.set index (Just value) array

            else
                array

        Update index ->
            case Array.get index array of
                Just (Just value) ->
                    Array.set index (Just (negate value)) array

                _ ->
                    array

        Push value ->
            Array.push (Just value) array


applyToMessageArray : Op -> MessageArray () Int -> MessageArray () Int
applyToMessageArray op array =
    case op of
        Set index value ->
            MessageArray.set (Id.fromInt index) value array

        Update index ->
            MessageArray.updateIfExists (Id.fromInt index) negate array

        Push value ->
            MessageArray.push value array


{-| Turns a `MessageArray` back into the naive representation so the two can be
compared.
-}
toReference : MessageArray () Int -> List (Maybe Int)
toReference array =
    MessageArray.foldr (\_ maybe list -> maybe :: list) [] array


fromOps : List Op -> ( Array (Maybe Int), MessageArray () Int )
fromOps ops =
    List.foldl
        (\op ( reference, array ) -> ( applyToReference op reference, applyToMessageArray op array ))
        ( Array.empty, MessageArray.empty )
        ops


expectMatches : Array (Maybe Int) -> MessageArray () Int -> Expect.Expectation
expectMatches reference array =
    Expect.all
        [ \_ -> toReference array |> Expect.equalLists (Array.toList reference)
        , \_ -> MessageArray.length array |> Expect.equal (Array.length reference)
        , \_ -> MessageArray.isEmpty array |> Expect.equal (Array.isEmpty reference)
        , \_ ->
            MessageArray.last array
                |> Expect.equal (Array.get (Array.length reference - 1) reference |> Maybe.andThen identity)
        , \_ ->
            List.range -2 (Array.length reference + 2)
                |> List.map (\index -> MessageArray.get (Id.fromInt index) array)
                |> Expect.equalLists
                    (List.range -2 (Array.length reference + 2)
                        |> List.map (\index -> Array.get index reference |> Maybe.andThen identity)
                    )
        , \_ ->
            MessageArray.toList array
                |> Expect.equalLists
                    (Array.toList reference
                        |> List.indexedMap
                            (\index maybe -> Maybe.map (\value -> ( Id.fromInt index, value )) maybe)
                        |> List.filterMap identity
                    )
        ]
        ()


tests : Test
tests =
    Test.describe
        "MessageArray"
        [ Test.test "Empty array" <|
            \_ -> expectMatches Array.empty MessageArray.empty
        , Test.fuzz (Fuzz.list opFuzzer) "Matches a plain array of maybes" <|
            \ops ->
                let
                    ( reference, array ) =
                        fromOps ops
                in
                expectMatches reference array
        , Test.fuzz3
            (Fuzz.list opFuzzer)
            (Fuzz.intRange -2 32)
            (Fuzz.intRange -2 32)
            "Slicing matches slicing a plain array of maybes"
          <|
            \ops start end ->
                let
                    ( reference, array ) =
                        fromOps ops

                    -- The slice keeps the indices the values had in the original
                    -- array, so pad the reference slice back out to compare.
                    clampedStart : Int
                    clampedStart =
                        clamp 0 (Array.length reference) start

                    clampedEnd : Int
                    clampedEnd =
                        clamp clampedStart (Array.length reference) end
                in
                MessageArray.toList (MessageArray.slice (Id.fromInt start) (Id.fromInt end) array)
                    |> Expect.equalLists
                        (MessageArray.toList array
                            |> List.filter
                                (\( id, _ ) -> Id.toInt id >= clampedStart && Id.toInt id < clampedEnd)
                        )
        , Test.fuzz3
            (Fuzz.list opFuzzer)
            (Fuzz.intRange -2 32)
            (Fuzz.intRange -2 32)
            "Folding over a slice hands back the original indices"
          <|
            \ops start end ->
                let
                    ( reference, array ) =
                        fromOps ops

                    clampedStart : Int
                    clampedStart =
                        clamp 0 (Array.length reference) start

                    clampedEnd : Int
                    clampedEnd =
                        clamp clampedStart (Array.length reference) end

                    sliced : MessageArray () Int
                    sliced =
                        MessageArray.slice (Id.fromInt start) (Id.fromInt end) array
                in
                MessageArray.foldr (\id maybe list -> ( Id.toInt id, maybe ) :: list) [] sliced
                    |> Expect.equalLists
                        (List.range clampedStart (clampedEnd - 1)
                            |> List.map
                                (\index -> ( index, Array.get index reference |> Maybe.andThen identity ))
                        )
        , Test.fuzz2
            (Fuzz.list opFuzzer)
            (Fuzz.list (Fuzz.pair (Fuzz.intRange -2 30) (Fuzz.intRange 0 999)))
            "setMany gives the same result as setting one at a time"
          <|
            \ops batch ->
                let
                    ( reference, array ) =
                        fromOps ops

                    entries : List ( Id.Id (), Int )
                    entries =
                        List.map (Tuple.mapFirst Id.fromInt) batch
                in
                expectMatches
                    (List.foldl
                        (\( index, value ) acc -> applyToReference (Set index value) acc)
                        reference
                        batch
                    )
                    (MessageArray.setMany entries array)
        , Test.fuzz (Fuzz.list opFuzzer) "Finding the last value that passes a test" <|
            \ops ->
                let
                    ( reference, array ) =
                        fromOps ops

                    isEven : Int -> Bool
                    isEven value =
                        modBy 2 value == 0
                in
                MessageArray.findRight isEven array
                    |> Maybe.map (Tuple.mapFirst Id.toInt)
                    |> Expect.equal
                        (Array.toList reference
                            |> List.indexedMap Tuple.pair
                            |> List.filterMap
                                (\( index, maybe ) ->
                                    case maybe of
                                        Just value ->
                                            if isEven value then
                                                Just ( index, value )

                                            else
                                                Nothing

                                        Nothing ->
                                            Nothing
                                )
                            |> List.reverse
                            |> List.head
                        )
        , Test.fuzz3
            (Fuzz.intRange 0 20)
            (Fuzz.intRange -2 20)
            (Fuzz.list (Fuzz.intRange 0 999))
            "fromArray loads a single run of values"
          <|
            \count start values ->
                let
                    clampedStart : Int
                    clampedStart =
                        clamp 0 count start

                    reference : Array (Maybe Int)
                    reference =
                        List.range 0 (count - 1)
                            |> List.map
                                (\index ->
                                    if index >= clampedStart then
                                        List.drop (index - clampedStart) values |> List.head

                                    else
                                        Nothing
                                )
                            |> Array.fromList
                in
                expectMatches
                    reference
                    (MessageArray.fromArray count (Id.fromInt start) (Array.fromList values))
        , Test.test "Values loaded either side of a gap stay put once the gap is filled" <|
            \_ ->
                let
                    array : MessageArray () Int
                    array =
                        MessageArray.fromArray 5 (Id.fromInt 0) Array.empty
                            |> MessageArray.set (Id.fromInt 0) 10
                            |> MessageArray.set (Id.fromInt 2) 12
                            |> MessageArray.set (Id.fromInt 4) 14
                            |> MessageArray.set (Id.fromInt 1) 11
                            |> MessageArray.set (Id.fromInt 3) 13
                in
                expectMatches (Array.fromList (List.map Just [ 10, 11, 12, 13, 14 ])) array
        ]
