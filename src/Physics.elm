module Physics exposing
    ( Body, simulate
    , boundsX, boundsY
    )

{-| A small, purpose built rigid body physics simulation for the game Booby
Trap.

The solver is position-based: each substep predicts where every circle would
move under its current velocity, then resolves overlaps and walls by moving
positions directly (overlapping pairs are split along their contact normal, and
anything outside the box is clamped back in). The new velocity is read out from
how far each circle actually ended up moving.

Because there is no stiff spring, the substep size is no longer pinned by
stability and the caller can use a much smaller number of substeps than the
penalty-based version required.

@docs Body, simulate

-}

import Array exposing (Array)
import Browser
import Browser.Events
import Duration exposing (Duration)
import Html
import Html.Attributes
import Html.Events
import List.Extra
import Random
import Time


{-| A 2D circle: position, velocity and radius. All pegs are assumed to have
the same (unit) mass, which is realistic enough for Booby Trap.
-}
type alias Body =
    { x : Float, y : Float, vx : Float, vy : Float, radius : Float }


{-| The simulation happens inside a fixed square box.
-}
boundsX : number
boundsX =
    60


boundsY : number
boundsY =
    160


{-| How many Gauss-Seidel passes the constraint solver makes per substep. Eight
is a typical value for position-based dynamics and handles small stacks of
contacts.
-}
solverIters : Int
solverIters =
    8


{-| Velocity damping, in units of "per second". Drains kinetic energy so the
world settles instead of jittering forever.
-}
dampingRate : Float
dampingRate =
    5


{-| Acceleration the spring loaded arm applies, in y per second per second.
Booby Trap's arm comes down hard, so this is intentionally well above gravity.
-}
armStrength : Float
armStrength =
    5000


{-| How rapidly the arm force falls off with distance below the topmost body.
Higher values concentrate the force on the very topmost body; lower values
spread it across nearby bodies. We pick a value that gives the body sitting at
the top edge full force, a body 0.1 units below ~60% of it, and a body a full
unit below almost nothing — so the arm doesn't flicker between near-tied
candidates but doesn't reach down into the pile either.
-}
falloffRate : Float
falloffRate =
    5


{-| Conservative upper bound on how far any body could move during a single
`simulate` call. At the start of the call we build, for each body, a list of
the other bodies whose centers are within `r_i + r_j + 2 * maxTravelPerCall`
of it — anything farther away than that cannot possibly come into contact
during the call, and we skip it in the constraint solver. This is the win:
`resolvePairs` then runs over a short neighbor list instead of every other
body.

If a body genuinely moves further than this in one call (e.g. absurdly high
velocities), pair contacts can be missed and circles could pass through each
other, so pick a generous value.

-}
maxTravelPerCall : Float
maxTravelPerCall =
    10


{-| Sentinel returned from out-of-range `Array.get` calls. Every index used
below is always in range, so this is never observed.
-}
dummyBody : Body
dummyBody =
    { x = 0, y = 0, vx = 0, vy = 0, radius = 0 }


type Msg
    = RemoveCircle Int
    | AnimationFrame Time.Posix


main : Program () (List Body) Msg
main =
    Browser.element
        { init =
            \_ ->
                let
                    small =
                        List.repeat 30 4

                    medium =
                        List.repeat 25 5

                    large =
                        List.repeat 12 6
                in
                ( Random.step (small ++ medium ++ large |> shuffle) (Random.initialSeed 125)
                    |> Tuple.first
                    |> List.indexedMap
                        (\index radius ->
                            let
                                columns : Int
                                columns =
                                    boundsX // 10
                            in
                            makeCircle
                                (modBy columns index * 10 |> toFloat)
                                (10 * toFloat (index // columns))
                                radius
                        )
                , Cmd.none
                )
        , update =
            \msg model ->
                case msg of
                    RemoveCircle index ->
                        ( List.Extra.removeAt index model, Cmd.none )

                    AnimationFrame time ->
                        let
                            speedup =
                                1
                        in
                        ( simulate (8 * speedup) (Duration.milliseconds (16.6 * speedup)) model
                        , Cmd.none
                        )
        , view =
            \model ->
                Html.div
                    []
                    (List.indexedMap
                        (\index { x, y, radius } ->
                            Html.div
                                [ Html.Attributes.style "position" "absolute"
                                , Html.Attributes.style "top" (String.fromFloat ((y - radius) * 10) ++ "px")
                                , Html.Attributes.style "left" (String.fromFloat ((x - radius) * 10) ++ "px")
                                , Html.Attributes.style "background-color"
                                    (if radius == 4 then
                                        "rgb(245, 240, 80)"

                                     else if radius == 5 then
                                        "rgb(80, 100, 240)"

                                     else
                                        "rgb(230, 40, 40)"
                                    )
                                , Html.Attributes.style "width" (String.fromFloat (radius * 20) ++ "px")
                                , Html.Attributes.style "height" (String.fromFloat (radius * 20) ++ "px")
                                , Html.Attributes.style "border-radius" "999px"
                                , Html.Events.onClick (RemoveCircle index)
                                ]
                                []
                        )
                        model
                    )
        , subscriptions = \_ -> Browser.Events.onAnimationFrame AnimationFrame
        }


anyInt : Random.Generator Int
anyInt =
    Random.int Random.minInt Random.maxInt


{-| Shuffle the list. Takes O(_n_ log _n_) time and no extra space. Original code from <https://github.com/elm-community/random-extra/blob/3.2.0/src/Random/List.elm>
-}
shuffle : List a -> Random.Generator (List a)
shuffle list =
    Random.map
        (\independentSeed ->
            list
                |> List.foldl
                    (\item ( acc, seed ) ->
                        let
                            ( tag, nextSeed ) =
                                Random.step anyInt seed
                        in
                        ( ( item, tag ) :: acc, nextSeed )
                    )
                    ( [], independentSeed )
                |> Tuple.first
                |> List.sortBy Tuple.second
                |> List.map Tuple.first
        )
        Random.independentSeed


makeCircle : Float -> Float -> Float -> Body
makeCircle x y r =
    { x = x, y = y, vx = 0, vy = 0, radius = r }


{-| Run the simulation. `steps` is the number of substeps and `duration` is
how much simulated time should pass in total.
-}
simulate : Int -> Duration -> List Body -> List Body
simulate steps duration bodies =
    let
        durSeconds : Float
        durSeconds =
            Duration.inSeconds duration
    in
    if steps <= 0 || durSeconds <= 0 then
        bodies

    else
        let
            dt : Float
            dt =
                durSeconds / toFloat steps

            initial : Array Body
            initial =
                Array.fromList bodies

            neighbors : Array (List Int)
            neighbors =
                buildNeighbors initial
        in
        stepN steps dt neighbors initial |> Array.toList


stepN : Int -> Float -> Array (List Int) -> Array Body -> Array Body
stepN remaining dt neighbors bodies =
    if remaining <= 0 then
        bodies

    else
        stepN (remaining - 1) dt neighbors (step dt neighbors bodies)


{-| Build the neighbor list once at the start of `simulate`. For each body i,
record every j > i whose initial center is close enough that the two could
possibly come into contact during this call, using the squared-distance test
to avoid a `sqrt`.
-}
buildNeighbors : Array Body -> Array (List Int)
buildNeighbors bodies =
    let
        n : Int
        n =
            Array.length bodies
    in
    buildOuterNeighbors 0 n bodies (Array.repeat n [])


buildOuterNeighbors : Int -> Int -> Array Body -> Array (List Int) -> Array (List Int)
buildOuterNeighbors i n bodies acc =
    if i + 1 - n < 0 then
        let
            bi : Body
            bi =
                Array.get i bodies |> Maybe.withDefault dummyBody

            list : List Int
            list =
                buildInnerNeighbors i (i + 1) n bi bodies []
        in
        buildOuterNeighbors (i + 1) n bodies (Array.set i list acc)

    else
        acc


buildInnerNeighbors : Int -> Int -> Int -> Body -> Array Body -> List Int -> List Int
buildInnerNeighbors i j n bi bodies acc =
    if j - n < 0 then
        let
            bj : Body
            bj =
                Array.get j bodies |> Maybe.withDefault dummyBody

            dx : Float
            dx =
                bj.x - bi.x

            dy : Float
            dy =
                bj.y - bi.y

            threshold : Float
            threshold =
                bi.radius + bj.radius + 2 * maxTravelPerCall
        in
        if dx * dx + dy * dy - threshold * threshold < 0 then
            buildInnerNeighbors i (j + 1) n bi bodies (j :: acc)

        else
            buildInnerNeighbors i (j + 1) n bi bodies acc

    else
        acc


{-| One position-based dynamics substep:

1.  Predict where each body would end up under its current velocity.
2.  Run the constraint solver (overlap separation + wall clamping) to push the
    predicted positions into a valid configuration.
3.  Read the new velocity out of the actual position change and apply damping.

-}
step : Float -> Array (List Int) -> Array Body -> Array Body
step dt neighbors bodies =
    let
        n : Int
        n =
            Array.length bodies

        damping : Float
        damping =
            Basics.e ^ negate (dampingRate * dt)

        topEdge : Float
        topEdge =
            findTopEdge 0 n bodies 1.0e18

        withArm : Array Body
        withArm =
            applyArmForce 0 n dt topEdge bodies bodies

        predicted : Array Body
        predicted =
            predictAll 0 n dt withArm withArm

        resolved : Array Body
        resolved =
            solveIters solverIters n neighbors predicted
    in
    deriveVelocities 0 n dt damping bodies resolved resolved


{-| Smallest `y - radius` value across the world — i.e. how high up the topmost
body's leading edge is.
-}
findTopEdge : Int -> Int -> Array Body -> Float -> Float
findTopEdge i n bodies best =
    if i - n < 0 then
        let
            b : Body
            b =
                Array.get i bodies |> Maybe.withDefault dummyBody

            edge : Float
            edge =
                b.y - b.radius

            next : Float
            next =
                if edge - best < 0 then
                    edge

                else
                    best
        in
        findTopEdge (i + 1) n bodies next

    else
        best


{-| Push each body downward with `armStrength`, scaled by an exponential
falloff in how far below `topEdge` its leading edge sits. The body whose edge
matches `topEdge` gets the full force; anything else gets less, very quickly.
-}
applyArmForce : Int -> Int -> Float -> Float -> Array Body -> Array Body -> Array Body
applyArmForce i n dt topEdge original acc =
    if i - n < 0 then
        let
            b : Body
            b =
                Array.get i original |> Maybe.withDefault dummyBody

            distance : Float
            distance =
                b.y - b.radius - topEdge

            falloff : Float
            falloff =
                Basics.e ^ negate (falloffRate * distance)

            new : Body
            new =
                { x = b.x
                , y = b.y
                , vx = b.vx
                , vy = b.vy + armStrength * falloff * dt
                , radius = b.radius
                }
        in
        applyArmForce (i + 1) n dt topEdge original (Array.set i new acc)

    else
        acc


{-| Predicted position: each body advances by `velocity * dt`. Velocity carried
through unchanged.
-}
predictAll : Int -> Int -> Float -> Array Body -> Array Body -> Array Body
predictAll i n dt original acc =
    if i - n < 0 then
        let
            b : Body
            b =
                Array.get i original |> Maybe.withDefault dummyBody

            new : Body
            new =
                { x = b.x + b.vx * dt
                , y = b.y + b.vy * dt
                , vx = b.vx
                , vy = b.vy
                , radius = b.radius
                }
        in
        predictAll (i + 1) n dt original (Array.set i new acc)

    else
        acc


{-| Gauss-Seidel relaxation: alternate between resolving overlapping pairs and
clamping bodies back inside the box, for `solverIters` rounds.
-}
solveIters : Int -> Int -> Array (List Int) -> Array Body -> Array Body
solveIters remaining n neighbors bodies =
    if remaining <= 0 then
        bodies

    else
        solveIters
            (remaining - 1)
            n
            neighbors
            (Array.map
                (\b ->
                    { x =
                        if b.x - b.radius < 0 then
                            b.radius

                        else if boundsX - b.x - b.radius < 0 then
                            boundsX - b.radius

                        else
                            b.x
                    , y =
                        if b.y - b.radius < 0 then
                            b.radius

                        else if boundsY - b.y - b.radius < 0 then
                            boundsY - b.radius

                        else
                            b.y
                    , vx = b.vx
                    , vy = b.vy
                    , radius = b.radius
                    }
                )
                (resolveAllPairs 0 n neighbors bodies)
            )


resolveAllPairs : Int -> Int -> Array (List Int) -> Array Body -> Array Body
resolveAllPairs i n neighbors bodies =
    if i + 1 - n < 0 then
        case Array.get i bodies of
            Just bi ->
                case Array.get i neighbors of
                    Just js ->
                        resolveAllPairs (i + 1) n neighbors (resolvePairs i js bi bodies)

                    Nothing ->
                        bodies

            Nothing ->
                bodies

    else
        bodies


{-| Walk i's neighbor list. If body i and body j overlap, push each one half
the penetration along the contact normal so that they end up exactly touching.
The running `bi` is updated as it moves so subsequent j contacts see the
latest position.
-}
resolvePairs : Int -> List Int -> Body -> Array Body -> Array Body
resolvePairs i js bi bodies =
    case js of
        [] ->
            bodies

        j :: rest ->
            case Array.get j bodies of
                Just bj ->
                    let
                        dx : Float
                        dx =
                            bj.x - bi.x

                        dy : Float
                        dy =
                            bj.y - bi.y

                        dist : Float
                        dist =
                            sqrt (dx * dx + dy * dy)

                        penetration : Float
                        penetration =
                            bi.radius + bj.radius - dist
                    in
                    if penetration <= 0 then
                        resolvePairs i rest bi bodies

                    else
                        let
                            ( nx, ny ) =
                                if 1.0e-9 - dist < 0 then
                                    ( dx / dist, dy / dist )

                                else
                                    ( 1, 0 )

                            half : Float
                            half =
                                penetration * 0.5

                            biNew : Body
                            biNew =
                                { x = bi.x - nx * half
                                , y = bi.y - ny * half
                                , vx = bi.vx
                                , vy = bi.vy
                                , radius = bi.radius
                                }

                            bjNew : Body
                            bjNew =
                                { x = bj.x + nx * half
                                , y = bj.y + ny * half
                                , vx = bj.vx
                                , vy = bj.vy
                                , radius = bj.radius
                                }
                        in
                        resolvePairs i rest biNew (Array.set j bjNew (Array.set i biNew bodies))

                Nothing ->
                    bodies


{-| The new velocity is the actual displacement (after constraint resolution)
divided by `dt`. A body that got pushed back to where it started has zero
velocity, which is what gives contacts and walls their inelastic feel.
-}
deriveVelocities : Int -> Int -> Float -> Float -> Array Body -> Array Body -> Array Body -> Array Body
deriveVelocities i n dt damping originals resolved acc =
    if i - n < 0 then
        let
            orig : Body
            orig =
                Array.get i originals |> Maybe.withDefault dummyBody

            now : Body
            now =
                Array.get i resolved |> Maybe.withDefault dummyBody

            new : Body
            new =
                { x = now.x
                , y = now.y
                , vx = (now.x - orig.x) / dt * damping
                , vy = (now.y - orig.y) / dt * damping
                , radius = now.radius
                }
        in
        deriveVelocities (i + 1) n dt damping originals resolved (Array.set i new acc)

    else
        acc
