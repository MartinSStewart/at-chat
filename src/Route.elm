module Route exposing
    ( ChannelRoute(..)
    , Route(..)
    , UserOverviewRouteData(..)
    , decode
    , encode
    , push
    , replace
    )

import AppUrl exposing (AppUrl)
import Dict
import Effect.Browser.Navigation as BrowserNavigation
import Effect.Command exposing (Command, FrontendOnly)
import Id exposing (ChannelId, GuildId, Id, InviteLinkId, UserId)
import SecretId exposing (SecretId)
import Url exposing (Url)
import Url.Builder


type Route
    = HomePageRoute
    | AdminRoute { highlightLog : Maybe Int }
    | UserOverviewRoute UserOverviewRouteData
    | GuildRoute (Id GuildId) ChannelRoute


type ChannelRoute
    = ChannelRoute (Id ChannelId)
    | NewChannelRoute
    | EditChannelRoute (Id ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (SecretId InviteLinkId)


type UserOverviewRouteData
    = PersonalRoute
    | SpecificUserRoute (Id UserId)


push : BrowserNavigation.Key -> Route -> Command FrontendOnly toMsg msg
push navkey route =
    BrowserNavigation.pushUrl navkey (encode route)


replace : BrowserNavigation.Key -> Route -> Command FrontendOnly toMsg msg
replace navkey route =
    BrowserNavigation.replaceUrl navkey (encode route)


decode : Url -> Route
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

        [ "user-overview" ] ->
            UserOverviewRoute PersonalRoute

        [ "user-overview", userId ] ->
            case Id.fromString userId of
                Just userId2 ->
                    UserOverviewRoute (SpecificUserRoute userId2)

                Nothing ->
                    HomePageRoute

        "g" :: guildId :: rest ->
            case Id.fromString guildId of
                Just guildId2 ->
                    case rest of
                        [ "c", channelId ] ->
                            case Id.fromString channelId of
                                Just channelId2 ->
                                    GuildRoute guildId2 (ChannelRoute channelId2)

                                Nothing ->
                                    HomePageRoute

                        [ "c", channelId, "edit" ] ->
                            case Id.fromString channelId of
                                Just channelId2 ->
                                    GuildRoute guildId2 (EditChannelRoute channelId2)

                                Nothing ->
                                    HomePageRoute

                        [ "new" ] ->
                            GuildRoute guildId2 NewChannelRoute

                        [ "invite" ] ->
                            GuildRoute guildId2 InviteLinkCreatorRoute

                        [ "join", inviteLinkId ] ->
                            GuildRoute guildId2 (JoinRoute (SecretId.fromString inviteLinkId))

                        _ ->
                            HomePageRoute

                Nothing ->
                    HomePageRoute

        _ ->
            HomePageRoute


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

                GuildRoute guildId maybeChannelId ->
                    ( [ "g", Id.toString guildId ]
                        ++ (case maybeChannelId of
                                ChannelRoute channelId ->
                                    [ "c", Id.toString channelId ]

                                EditChannelRoute channelId ->
                                    [ "c", Id.toString channelId, "edit" ]

                                NewChannelRoute ->
                                    [ "new" ]

                                InviteLinkCreatorRoute ->
                                    [ "invite" ]

                                JoinRoute inviteLinkId ->
                                    [ "join", SecretId.toString inviteLinkId ]
                           )
                    , []
                    )
    in
    Url.Builder.absolute path query


idToPath : Id a -> String
idToPath id =
    Id.toString id |> Url.percentEncode
