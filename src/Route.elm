module Route exposing
    ( Route(..)
    , UserOverviewRouteData(..)
    , decode
    , encode
    )

import AppUrl exposing (AppUrl)
import Dict
import Id exposing (ChannelId, GuildId, Id, UserId)
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query


type Route
    = HomePageRoute
    | AdminRoute { highlightLog : Maybe Int }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Id GuildId)
    | ChannelRoute (Id GuildId) (Id ChannelId)


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Id UserId)


decode : Url -> Maybe Route
decode url =
    let
        url2 =
            AppUrl.fromUrl url
    in
    case url2.path of
        [ "admin" ] ->
            AdminRoute
                { highlightLog =
                    case Dict.get "highlight-log" url2.queryParameters of
                        Just [ a ] ->
                            String.toInt a

                        _ ->
                            Nothing
                }
                |> Just

        [ "user-overview" ] ->
            UserOverviewRoute PersonalRoute |> Just

        [ "user-overview", userId ] ->
            UserOverviewRoute (SpecificUserRoute (Id.fromString userId)) |> Just

        [ "channels", guildId ] ->
            GuildRoute (Id.fromString guildId) |> Just

        [ "channels", guildId, channelId ] ->
            ChannelRoute (Id.fromString guildId) (Id.fromString channelId) |> Just

        [] ->
            Just HomePageRoute

        _ ->
            Nothing


encode : Route -> String
encode route =
    let
        ( path, query ) =
            case route of
                HomePageRoute ->
                    ( [], [] )

                AdminRoute params ->
                    ( [ "admin" ]
                    , case params.highlightLog of
                        Just a ->
                            [ Url.Builder.int "highlight-log" a ]

                        Nothing ->
                            []
                    )

                UserOverviewRoute maybeUserId ->
                    ( "user-overview"
                        :: (case maybeUserId of
                                SpecificUserRoute userId ->
                                    [ idToPath userId ]

                                PersonalRoute ->
                                    []
                           )
                    , []
                    )

                GuildRoute guildId ->
                    ( [ "channels", Id.toString guildId ], [] )

                ChannelRoute guildId channelId ->
                    ( [ "channels", Id.toString guildId, Id.toString channelId ], [] )
    in
    Url.Builder.absolute path query


idToPath : Id a -> String
idToPath id =
    Id.toString id |> Url.percentEncode
