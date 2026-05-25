module VideoPosAndSizeTests exposing (tests)

import Call
import Expect
import Id exposing (Id, VideoNodeId)
import Test exposing (Test)


makeVideo : Int -> Float -> { id : Id VideoNodeId, aspectRatio : Float }
makeVideo idInt ar =
    { id = Id.fromInt idInt, aspectRatio = ar }


tests : Test
tests =
    Test.describe "Call.videoPosAndSize"
        [ Test.test "Empty input returns empty list" <|
            \_ ->
                Call.videoPosAndSize
                    { containerWidth = 800, containerHeight = 600, spacing = 8 }
                    []
                    |> Expect.equal []
        , Test.test "Single video fills container as large as possible while respecting aspect ratio" <|
            \_ ->
                let
                    result =
                        Call.videoPosAndSize
                            { containerWidth = 1600, containerHeight = 900, spacing = 8 }
                            [ makeVideo 1 (16 / 9) ]
                in
                case result of
                    [ a ] ->
                        Expect.all
                            [ \v -> Expect.equal 1600 v.width
                            , \v -> Expect.equal 900 v.height
                            , \v -> Expect.equal 0 v.x
                            , \v -> Expect.equal 0 v.y
                            ]
                            a

                    _ ->
                        Expect.fail "Expected exactly one result"
        , Test.test "Single video is letterboxed when container aspect doesn't match" <|
            \_ ->
                let
                    result =
                        Call.videoPosAndSize
                            { containerWidth = 1000, containerHeight = 1000, spacing = 0 }
                            [ makeVideo 1 (16 / 9) ]
                in
                case result of
                    [ a ] ->
                        Expect.all
                            [ \v -> Expect.equal 1000 v.width
                            , \v -> Expect.equal 563 v.height
                            , \v -> Expect.equal 0 v.x
                            , \v -> Expect.equal 219 v.y
                            ]
                            a

                    _ ->
                        Expect.fail "Expected exactly one result"
        , Test.test "Two videos sit adjacent with the requested spacing between them" <|
            \_ ->
                let
                    spacing =
                        10

                    result =
                        Call.videoPosAndSize
                            { containerWidth = 1600, containerHeight = 600, spacing = spacing }
                            [ makeVideo 1 (16 / 9), makeVideo 2 (16 / 9) ]
                in
                case result of
                    [ a, b ] ->
                        Expect.all
                            [ \_ -> Expect.equal a.width b.width
                            , \_ -> Expect.equal a.height b.height
                            , \_ -> Expect.equal a.y b.y
                            , \_ -> Expect.equal (a.x + a.width + spacing) b.x
                            ]
                            ()

                    _ ->
                        Expect.fail "Expected two results"
        , Test.test "Three 16:9 videos form a 2+1 layout with rows packed adjacent" <|
            \_ ->
                let
                    spacing =
                        8

                    result =
                        Call.videoPosAndSize
                            { containerWidth = 1600, containerHeight = 1000, spacing = spacing }
                            [ makeVideo 1 (16 / 9), makeVideo 2 (16 / 9), makeVideo 3 (16 / 9) ]
                in
                case result of
                    [ a, b, c ] ->
                        Expect.all
                            [ \_ -> Expect.equal a.y b.y
                            , \_ -> Expect.equal a.height b.height
                            , \_ -> Expect.equal (a.x + a.width + spacing) b.x
                            , \_ -> Expect.equal (a.y + a.height + spacing) c.y
                            ]
                            ()

                    _ ->
                        Expect.fail "Expected three results"
        , Test.test "Two videos respect total spacing within container width" <|
            \_ ->
                let
                    spacing =
                        20

                    containerWidth =
                        1000

                    result =
                        Call.videoPosAndSize
                            { containerWidth = containerWidth, containerHeight = 200, spacing = spacing }
                            [ makeVideo 1 (16 / 9), makeVideo 2 (16 / 9) ]
                in
                case result of
                    [ a, b ] ->
                        let
                            totalUsed =
                                a.width + spacing + b.width
                        in
                        Expect.atMost containerWidth totalUsed

                    _ ->
                        Expect.fail "Expected two results"
        , Test.test "No video extends past the container bounds" <|
            \_ ->
                let
                    containerWidth =
                        800

                    containerHeight =
                        600

                    result =
                        Call.videoPosAndSize
                            { containerWidth = containerWidth, containerHeight = containerHeight, spacing = 8 }
                            (List.repeat 5 (makeVideo 0 (16 / 9))
                                |> List.indexedMap (\i v -> { v | id = Id.fromInt i })
                            )
                in
                result
                    |> List.all
                        (\v ->
                            (v.x >= 0)
                                && (v.y >= 0)
                                && (v.x + v.width <= containerWidth)
                                && (v.y + v.height <= containerHeight)
                        )
                    |> Expect.equal True
        , Test.test "Layout is centered horizontally" <|
            \_ ->
                let
                    containerWidth =
                        1000

                    spacing =
                        8

                    result =
                        Call.videoPosAndSize
                            { containerWidth = containerWidth, containerHeight = 1000, spacing = spacing }
                            [ makeVideo 1 (16 / 9), makeVideo 2 (16 / 9) ]
                in
                case result of
                    [ a, b ] ->
                        let
                            leftGap =
                                a.x

                            rightGap =
                                containerWidth - (b.x + b.width)
                        in
                        Expect.atMost 1 (abs (leftGap - rightGap))

                    _ ->
                        Expect.fail "Expected two results"
        , Test.test "Layout is centered vertically when there is extra space" <|
            \_ ->
                let
                    containerHeight =
                        1000

                    result =
                        Call.videoPosAndSize
                            { containerWidth = 1000, containerHeight = containerHeight, spacing = 8 }
                            [ makeVideo 1 (16 / 9) ]
                in
                case result of
                    [ a ] ->
                        let
                            topGap =
                                a.y

                            bottomGap =
                                containerHeight - (a.y + a.height)
                        in
                        Expect.atMost 1 (abs (topGap - bottomGap))

                    _ ->
                        Expect.fail "Expected one result"
        , Test.test "Each video preserves its aspect ratio (within rounding)" <|
            \_ ->
                let
                    result =
                        Call.videoPosAndSize
                            { containerWidth = 800, containerHeight = 600, spacing = 8 }
                            [ makeVideo 1 (16 / 9)
                            , makeVideo 2 (4 / 3)
                            , makeVideo 3 1
                            , makeVideo 4 2
                            ]
                in
                result
                    |> List.indexedMap
                        (\i v ->
                            let
                                expectedAr =
                                    case i of
                                        0 ->
                                            16 / 9

                                        1 ->
                                            4 / 3

                                        2 ->
                                            1

                                        _ ->
                                            2

                                actualAr =
                                    toFloat v.width / toFloat v.height
                            in
                            abs (actualAr - expectedAr) < 0.05
                        )
                    |> List.all identity
                    |> Expect.equal True
        , Test.test "All input ids appear in the output" <|
            \_ ->
                let
                    inputs =
                        [ makeVideo 7 (16 / 9)
                        , makeVideo 42 1
                        , makeVideo 99 (4 / 3)
                        ]

                    result =
                        Call.videoPosAndSize
                            { containerWidth = 800, containerHeight = 600, spacing = 8 }
                            inputs
                in
                List.map .id result
                    |> Expect.equal (List.map .id inputs)
        ]
