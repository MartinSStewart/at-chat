module Physics exposing (Circle, simulate)

{-| A small, purpose built rigid body physics simulation for the game Booby
Trap.

Bodies are 2D circles. They start at rest and the only thing that moves them is
contact: when two circles overlap they push each other apart. Velocity is
internal to the simulation (it always starts at zero), so the observable effect
of running the simulation is that an initially overlapping pile of circles
settles into a configuration where nothing overlaps.

@docs Circle, simulate

-}

import Array exposing (Array)
import Duration exposing (Duration)


{-| A 2D circle: a center (`x`, `y`) and a `radius`.
-}
type alias Circle =
    { x : Float, y : Float, radius : Float }


{-| Internal simulation state. Mass is proportional to area (radius squared) so
that contacts conserve momentum: a small circle is shoved further than a large
one when they collide.
-}
type alias Body =
    { x : Float
    , y : Float
    , vx : Float
    , vy : Float
    , radius : Float
    , mass : Float
    }


{-| How hard overlapping circles push each other apart, per unit of
penetration. Higher values separate faster but need smaller time steps to stay
stable.
-}
stiffness : Float
stiffness =
    200


{-| Velocity damping, in units of "per second". Drains kinetic energy so the
pile settles instead of bouncing forever.
-}
dampingRate : Float
dampingRate =
    4


{-| Run the simulation.

  - `steps` is the number of integration steps. More steps means a smaller time
    step per integration, which is more accurate and more stable.
  - `duration` is how much simulated time should pass in total.
  - the circles are the bodies to simulate.

Returns the circles in the same order, moved to where they end up.

-}
simulate : Int -> Duration -> List Circle -> List Circle
simulate steps duration circles =
    if steps <= 0 then
        circles

    else
        let
            dt : Float
            dt =
                Duration.inSeconds duration / toFloat steps

            initial : Array Body
            initial =
                circles |> List.map toBody |> Array.fromList

            settled : Array Body
            settled =
                List.range 1 steps
                    |> List.foldl (\_ bodies -> step dt bodies) initial
        in
        settled |> Array.toList |> List.map toCircle


toBody : Circle -> Body
toBody circle =
    { x = circle.x
    , y = circle.y
    , vx = 0
    , vy = 0
    , radius = circle.radius
    , mass = max circle.radius 1.0e-6 ^ 2
    }


toCircle : Body -> Circle
toCircle body =
    { x = body.x, y = body.y, radius = body.radius }


{-| Advance the whole system by one time step using semi-implicit Euler:
compute contact forces from the current positions, integrate velocities (with
damping), then integrate positions from the new velocities.
-}
step : Float -> Array Body -> Array Body
step dt bodies =
    let
        forces : Array ( Float, Float )
        forces =
            contactForces bodies

        damping : Float
        damping =
            Basics.e ^ negate (dampingRate * dt)
    in
    Array.indexedMap
        (\i body ->
            let
                ( fx, fy ) =
                    Array.get i forces |> Maybe.withDefault ( 0, 0 )

                vx =
                    (body.vx + fx / body.mass * dt) * damping

                vy =
                    (body.vy + fy / body.mass * dt) * damping
            in
            { body
                | vx = vx
                , vy = vy
                , x = body.x + vx * dt
                , y = body.y + vy * dt
            }
        )
        bodies


{-| For every body, sum the repulsion from every other body it overlaps. Forces
are computed from the current positions of all bodies (so the result does not
depend on iteration order), and each contact pushes the pair apart along the
line between their centers with equal and opposite force.
-}
contactForces : Array Body -> Array ( Float, Float )
contactForces bodies =
    let
        indexed : List ( Int, Body )
        indexed =
            Array.toIndexedList bodies
    in
    indexed
        |> List.map
            (\( i, bi ) ->
                List.foldl
                    (\( j, bj ) ( fx, fy ) ->
                        if i == j then
                            ( fx, fy )

                        else
                            let
                                dx =
                                    bj.x - bi.x

                                dy =
                                    bj.y - bi.y

                                dist =
                                    sqrt (dx * dx + dy * dy)

                                penetration =
                                    bi.radius + bj.radius - dist
                            in
                            if penetration <= 0 then
                                ( fx, fy )

                            else
                                let
                                    -- Unit vector pointing from bi toward bj.
                                    -- If the centers coincide, pick an
                                    -- arbitrary but deterministic direction.
                                    ( nx, ny ) =
                                        if dist > 1.0e-9 then
                                            ( dx / dist, dy / dist )

                                        else
                                            ( 1, 0 )

                                    magnitude =
                                        stiffness * penetration
                                in
                                -- Push bi away from bj (opposite the normal).
                                ( fx - nx * magnitude, fy - ny * magnitude )
                    )
                    ( 0, 0 )
                    indexed
            )
        |> Array.fromList
