module Route exposing
    ( Route(..)
    , UserOverviewRouteData(..)
    , decode
    , encode
    , isSamePage
    )

import Id exposing (Id, UserId)
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query


type Route
    = HomePageRoute
    | AdminRoute { highlightLog : Maybe Int }
    | UserOverviewRoute UserOverviewRouteData


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Id UserId)


decode : Url -> Maybe Route
decode url =
    Url.Parser.parse urlDecoder url


urlDecoder : Url.Parser.Parser (Route -> c) c
urlDecoder =
    Url.Parser.oneOf
        [ Url.Parser.s adminPath <?> adminQuery |> Url.Parser.map (\a -> AdminRoute { highlightLog = a })
        , Url.Parser.s userOverviewPath </> idPath |> Url.Parser.map (\a -> UserOverviewRoute (SpecificUserRoute a))
        , Url.Parser.s userOverviewPath |> Url.Parser.map (UserOverviewRoute PersonalRoute)
        , Url.Parser.top |> Url.Parser.map HomePageRoute
        ]


idPath : Url.Parser.Parser (Id id -> a) a
idPath =
    Url.Parser.map
        (\text -> Url.percentDecode text |> Maybe.withDefault text |> Id.fromString)
        Url.Parser.string


adminQuery : Url.Parser.Query.Parser (Maybe Int)
adminQuery =
    Url.Parser.Query.int highlightLog


highlightLog : String
highlightLog =
    "highlight-log"


userOverviewPath : String
userOverviewPath =
    "user-overview"


adminPath : String
adminPath =
    "admin"


encode : Route -> String
encode route =
    let
        ( path, query ) =
            case route of
                HomePageRoute ->
                    ( [], [] )

                AdminRoute params ->
                    ( [ adminPath ]
                    , case params.highlightLog of
                        Just a ->
                            [ Url.Builder.int highlightLog a ]

                        Nothing ->
                            []
                    )

                UserOverviewRoute maybeUserId ->
                    ( userOverviewPath
                        :: (case maybeUserId of
                                SpecificUserRoute userId ->
                                    [ idToPath userId ]

                                PersonalRoute ->
                                    []
                           )
                    , []
                    )
    in
    Url.Builder.absolute path query


idToPath : Id a -> String
idToPath id =
    Id.toString id |> Url.percentEncode


isSamePage : Route -> Route -> Bool
isSamePage routeA routeB =
    case routeA of
        HomePageRoute ->
            routeB == routeA

        AdminRoute _ ->
            case routeB of
                AdminRoute _ ->
                    True

                _ ->
                    False

        UserOverviewRoute _ ->
            routeB == routeA
