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


{-| Coulomb friction coefficient. When the solver resolves a contact it pushes
the two bodies apart by `penetration` along the contact normal; it then also
tries to cancel however far they slid _tangentially_ during this substep, but
only up to `frictionCoeff * penetration` of sliding. Slides smaller than that
budget are cancelled completely (static friction: the contact sticks), larger
ones are only damped (kinetic friction: it slips).

Because the budget scales with penetration, a contact under more compression
resists more sliding — so a settled, compressed pile holds together and only
gives way once something pushes hard enough, instead of collapsing the moment
a circle is removed.

-}
frictionCoeff : Float
frictionCoeff =
    1


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
to avoid a `sqrt`. Body i's list doesn't depend on any other body's list, so
`Array.indexedMap` builds the whole array in a single pass.
-}
buildNeighbors : Array Body -> Array (List Int)
buildNeighbors bodies =
    let
        n : Int
        n =
            Array.length bodies
    in
    Array.indexedMap
        (\i bi -> buildInnerNeighbors i (i + 1) n bi bodies [])
        bodies


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
            findTopEdge bodies

        predicted : Array Body
        predicted =
            applyArmForceAndPredict dt topEdge bodies

        resolved : Array Body
        resolved =
            solveIters solverIters n neighbors bodies predicted
    in
    deriveVelocities dt damping bodies resolved


{-| Smallest `y - radius` value across the world — i.e. how high up the topmost
body's leading edge is. Pure fold with no writes, so `Array.foldl` lets the
kernel iterate without going through `Array.get`.
-}
findTopEdge : Array Body -> Float
findTopEdge bodies =
    Array.foldl
        (\b best ->
            let
                edge : Float
                edge =
                    b.y - b.radius
            in
            if edge - best < 0 then
                edge

            else
                best
        )
        1.0e18
        bodies


{-| Apply the spring arm's downward force and integrate the new velocity into
a predicted position, in a single `Array.map` pass. Both updates are
per-body independent given the captured `topEdge` and `dt`, so fusing them
saves one whole-array allocation per substep compared to running an arm pass
and a predict pass separately.
-}
applyArmForceAndPredict : Float -> Float -> Array Body -> Array Body
applyArmForceAndPredict dt topEdge bodies =
    Array.map
        (\b ->
            let
                distance : Float
                distance =
                    b.y - b.radius - topEdge

                falloff : Float
                falloff =
                    Basics.e ^ negate (falloffRate * distance)

                vy : Float
                vy =
                    b.vy + armStrength * falloff * dt
            in
            { x = b.x + b.vx * dt
            , y = b.y + vy * dt
            , vx = b.vx
            , vy = vy
            , radius = b.radius
            }
        )
        bodies


{-| Gauss-Seidel relaxation. Each round walks every body, resolves its
overlaps with the bodies in its neighbor list, then clamps it back inside the
box (with wall friction) before moving on. Clamping per-body inside the pair
walk avoids a full `Array.map` clamp pass between rounds.

`originals` is the state at the start of the substep; the solver compares
against it to work out how far each body has slid tangentially, which is what
friction resists.

-}
solveIters : Int -> Int -> Array (List Int) -> Array Body -> Array Body -> Array Body
solveIters remaining n neighbors originals bodies =
    if remaining <= 0 then
        bodies

    else
        solveIters (remaining - 1) n neighbors originals (resolveAllPairs 0 n neighbors originals bodies)


resolveAllPairs : Int -> Int -> Array (List Int) -> Array Body -> Array Body -> Array Body
resolveAllPairs i n neighbors originals bodies =
    if i - n < 0 then
        case Array.get i bodies of
            Just bi ->
                case ( Array.get i neighbors, Array.get i originals ) of
                    ( Just js, Just origI ) ->
                        resolveAllPairs (i + 1) n neighbors originals (resolvePairs i origI js bi originals bodies)

                    _ ->
                        bodies

            Nothing ->
                bodies

    else
        bodies


{-| Clamp a body back inside the box and apply wall friction. Clamping a wall
is a contact along that wall's normal, so the tangential direction is the
other axis: a body resting on the floor (a `y` clamp) has its `x` sliding
resisted, and a body against a side wall (an `x` clamp) has its `y` sliding
resisted. The friction budget is `frictionCoeff * penetration`, same Coulomb
rule as body-body contacts, with `orig` giving the substep-start position the
slide is measured from.

Floor friction matters most: the bottom row of a pile rests on the floor, so
without it the whole stack could slide sideways no matter how much the bodies
grip each other.

-}
resolveBody : Body -> Body -> Body
resolveBody orig b =
    let
        ( x1, penX ) =
            if b.x - b.radius < 0 then
                ( b.radius, b.radius - b.x )

            else if boundsX - b.x - b.radius < 0 then
                ( boundsX - b.radius, b.x + b.radius - boundsX )

            else
                ( b.x, 0 )

        ( y1, penY ) =
            if b.y - b.radius < 0 then
                ( b.radius, b.radius - b.y )

            else if boundsY - b.y - b.radius < 0 then
                ( boundsY - b.radius, b.y + b.radius - boundsY )

            else
                ( b.y, 0 )

        -- A floor/ceiling contact (penY) resists sliding along x; a side-wall
        -- contact (penX) resists sliding along y.
        x2 : Float
        x2 =
            if 0 - penY < 0 then
                frictionResist orig.x x1 (frictionCoeff * penY)

            else
                x1

        y2 : Float
        y2 =
            if 0 - penX < 0 then
                frictionResist orig.y y1 (frictionCoeff * penX)

            else
                y1
    in
    { x = x2
    , y = y2
    , vx = b.vx
    , vy = b.vy
    , radius = b.radius
    }


{-| Resist a 1D slide from `origValue` to `value`, given a friction `budget`.
If the slide is within budget it is cancelled entirely (static friction: the
value snaps back to where it started); otherwise it is shortened by the budget
(kinetic friction: it keeps moving but loses ground).
-}
frictionResist : Float -> Float -> Float -> Float
frictionResist origValue value budget =
    let
        d : Float
        d =
            value - origValue
    in
    if abs d - budget < 0 then
        origValue

    else if d - 0 < 0 then
        value + budget

    else
        value - budget


{-| Walk i's neighbor list. If body i and body j overlap, push each one half
the penetration along the contact normal so that they end up exactly touching,
then apply tangential friction to resist however far they have slid past each
other this substep. The running `bi` is updated as it moves so subsequent j
contacts see the latest position, but it's only written back to the array once
at the end of the walk — earlier writes would be overwritten by the next
contact anyway.

`origI` / `originals` give the substep-start positions that the friction
slide is measured against.

-}
resolvePairs : Int -> Body -> List Int -> Body -> Array Body -> Array Body -> Array Body
resolvePairs i origI js bi originals bodies =
    case js of
        [] ->
            Array.set i (resolveBody origI bi) bodies

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

                        distSq : Float
                        distSq =
                            dx * dx + dy * dy

                        sumR : Float
                        sumR =
                            bi.radius + bj.radius
                    in
                    -- Most neighbors aren't actually overlapping this iteration;
                    -- skip the sqrt when the squared distance test rules them out.
                    if distSq - sumR * sumR < 0 then
                        let
                            dist : Float
                            dist =
                                sqrt distSq

                            penetration : Float
                            penetration =
                                sumR - dist

                            ( nx, ny ) =
                                if 1.0e-9 - dist < 0 then
                                    ( dx / dist, dy / dist )

                                else
                                    ( 1, 0 )

                            half : Float
                            half =
                                penetration * 0.5

                            -- Position after the normal (overlap) correction.
                            biNormX : Float
                            biNormX =
                                bi.x - nx * half

                            biNormY : Float
                            biNormY =
                                bi.y - ny * half

                            bjNormX : Float
                            bjNormX =
                                bj.x + nx * half

                            bjNormY : Float
                            bjNormY =
                                bj.y + ny * half

                            origJ : Body
                            origJ =
                                Array.get j originals |> Maybe.withDefault dummyBody

                            -- Tangential slide of the contact over this substep
                            -- (relative displacement with the normal part removed).
                            rdx : Float
                            rdx =
                                (biNormX - origI.x) - (bjNormX - origJ.x)

                            rdy : Float
                            rdy =
                                (biNormY - origI.y) - (bjNormY - origJ.y)

                            dot : Float
                            dot =
                                rdx * nx + rdy * ny

                            tx : Float
                            tx =
                                rdx - dot * nx

                            ty : Float
                            ty =
                                rdy - dot * ny

                            tSq : Float
                            tSq =
                                tx * tx + ty * ty

                            budget : Float
                            budget =
                                frictionCoeff * penetration

                            -- Fraction of the slide each body gives back.
                            -- Within budget: cancel it all (0.5 each, no sqrt).
                            -- Over budget: only walk it back by the budget.
                            scale : Float
                            scale =
                                if tSq - budget * budget < 0 then
                                    0.5

                                else
                                    budget / sqrt tSq * 0.5

                            cx : Float
                            cx =
                                tx * scale

                            cy : Float
                            cy =
                                ty * scale

                            biNew : Body
                            biNew =
                                { x = biNormX - cx
                                , y = biNormY - cy
                                , vx = bi.vx
                                , vy = bi.vy
                                , radius = bi.radius
                                }

                            bjNew : Body
                            bjNew =
                                { x = bjNormX + cx
                                , y = bjNormY + cy
                                , vx = bj.vx
                                , vy = bj.vy
                                , radius = bj.radius
                                }
                        in
                        resolvePairs i origI rest biNew originals (Array.set j bjNew bodies)

                    else
                        resolvePairs i origI rest bi originals bodies

                Nothing ->
                    Array.set i (resolveBody origI bi) bodies


{-| The new velocity is the actual displacement (after constraint resolution)
divided by `dt`. A body that got pushed back to where it started has zero
velocity, which is what gives contacts and walls their inelastic feel.

Per-body update needs both `resolved[i]` and `originals[i]`, so we walk
`resolved` with `Array.indexedMap` and do one `Array.get` against `originals`
per element. That still beats the previous full Gauss-Seidel-style `Array.set`
loop because the output array is built in a single allocation.

-}
deriveVelocities : Float -> Float -> Array Body -> Array Body -> Array Body
deriveVelocities dt damping originals resolved =
    Array.indexedMap
        (\i now ->
            let
                orig : Body
                orig =
                    Array.get i originals |> Maybe.withDefault dummyBody
            in
            { x = now.x
            , y = now.y
            , vx = (now.x - orig.x) / dt * damping
            , vy = (now.y - orig.y) / dt * damping
            , radius = now.radius
            }
        )
        resolved
