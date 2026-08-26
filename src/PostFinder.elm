module PostFinder exposing
    ( FrontendModel
    , Match
    , Msg
    , PlatformSearch
    , Post
    , Search
    , Tweet
    , TweetRef
    , blueskyHandlesIn
    , fediverseHandlesIn
    , init
    , isPressMsg
    , normalizeText
    , parseTweetUrl
    , searchFor
    , similarity
    , stripHtml
    , update
    , view
    )

{-| A page that takes a link to a tweet and looks for the same post on Bluesky
and Mastodon.

The tweet itself comes from fxtwitter, because twitter's own API needs a paid
key while fxtwitter hands over the text, the timestamp and the author's bio
without one. Bluesky and Mastodon both have public read-only APIs, so every
request here can be made straight from the browser.

Finding the post is two steps: work out which accounts on the other site might
belong to the same person, then read what those accounts posted around the time
of the tweet and see if any of it says the same thing.

-}

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Browser.Navigation as BrowserNavigation exposing (Key)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Http as Http exposing (Response(..))
import Effect.Task as Task exposing (Task)
import Effect.Time as Time
import Iso8601
import Json.Decode exposing (Decoder)
import List.Extra
import MyUi
import Quantity
import Route
import Set exposing (Set)
import Ui exposing (Element)
import Ui.Events
import Ui.Font
import Ui.Input
import Url
import Url.Builder


type alias FrontendModel =
    { input : String
    , search : Search

    -- Which search the replies still on their way belong to. A reply from a
    -- search that's been replaced arrives after the new one has already put its
    -- own tweet on screen, so without this it would file its results under the
    -- wrong tweet.
    , searchId : Int
    }


type Search
    = NoSearch
    | NotATweetLink
    | LoadingTweet
    | TweetFailed Http.Error
    | FoundTweet Tweet { bluesky : PlatformSearch, mastodon : PlatformSearch }


type PlatformSearch
    = SearchingPlatform
    | PlatformFailed Http.Error
    | PlatformMatches (List Match)


{-| Which tweet to look up. The handle is optional because fxtwitter finds a
tweet from its id alone, and links of the form `x.com/i/status/123` don't carry
one.
-}
type alias TweetRef =
    { handle : Maybe String
    , statusId : String
    }


type alias Tweet =
    { url : String
    , text : String
    , createdAt : Time.Posix
    , authorHandle : String
    , authorName : String
    , authorBio : String
    }


type alias Post =
    { url : String
    , text : String
    , createdAt : Time.Posix
    , authorHandle : String
    , authorName : String
    }


type alias Match =
    { post : Post
    , similarity : Float
    }


type Msg
    = TypedTweetLink String
    | PressedSearch
    | GotTweet Int (Result Http.Error Tweet)
    | GotBlueskyMatches Int (Result Http.Error (List Match))
    | GotMastodonMatches Int (Result Http.Error (List Match))


init : FrontendModel
init =
    { input = "", search = NoSearch, searchId = 0 }


{-| Start looking for the tweet that's in the address bar. Called when the page
opens and whenever the link in the address bar changes, which is also how the
search button starts a search.
-}
searchFor : Maybe String -> FrontendModel -> ( FrontendModel, Command restriction toBackend Msg )
searchFor maybeTweetLink model =
    let
        searchId : Int
        searchId =
            model.searchId + 1
    in
    case maybeTweetLink of
        Just tweetLink ->
            case parseTweetUrl tweetLink of
                Just tweetRef ->
                    ( { model | input = tweetLink, search = LoadingTweet, searchId = searchId }
                    , Http.get
                        { url = fxTwitterUrl tweetRef
                        , expect = Http.expectJson (GotTweet searchId) decodeTweet
                        }
                    )

                Nothing ->
                    ( { model | input = tweetLink, search = NotATweetLink, searchId = searchId }
                    , Command.none
                    )

        Nothing ->
            ( { model | search = NoSearch, searchId = searchId }, Command.none )


update : Key -> Msg -> FrontendModel -> ( FrontendModel, Command FrontendOnly toBackend Msg )
update navigationKey msg model =
    case msg of
        TypedTweetLink text ->
            ( { model | input = text }, Command.none )

        PressedSearch ->
            let
                tweetLink : Maybe String
                tweetLink =
                    case String.trim model.input of
                        "" ->
                            Nothing

                        trimmed ->
                            Just trimmed
            in
            ( model
            , Route.encode (Route.PostFinderRoute tweetLink)
                |> BrowserNavigation.pushUrl navigationKey
            )

        GotTweet searchId (Ok tweet) ->
            if isCurrentSearch searchId model then
                ( { model
                    | search =
                        FoundTweet tweet { bluesky = SearchingPlatform, mastodon = SearchingPlatform }
                  }
                , Command.batch
                    [ Task.attempt (GotBlueskyMatches searchId) (findBlueskyMatches tweet)
                    , Task.attempt (GotMastodonMatches searchId) (findMastodonMatches tweet)
                    ]
                )

            else
                ( model, Command.none )

        GotTweet searchId (Err error) ->
            if isCurrentSearch searchId model then
                ( { model | search = TweetFailed error }, Command.none )

            else
                ( model, Command.none )

        GotBlueskyMatches searchId result ->
            if isCurrentSearch searchId model then
                ( { model | search = setBlueskyResult result model.search }, Command.none )

            else
                ( model, Command.none )

        GotMastodonMatches searchId result ->
            if isCurrentSearch searchId model then
                ( { model | search = setMastodonResult result model.search }, Command.none )

            else
                ( model, Command.none )


setBlueskyResult : Result Http.Error (List Match) -> Search -> Search
setBlueskyResult result search =
    case search of
        FoundTweet tweet results ->
            FoundTweet tweet { results | bluesky = toPlatformSearch result }

        _ ->
            search


setMastodonResult : Result Http.Error (List Match) -> Search -> Search
setMastodonResult result search =
    case search of
        FoundTweet tweet results ->
            FoundTweet tweet { results | mastodon = toPlatformSearch result }

        _ ->
            search


toPlatformSearch : Result Http.Error (List Match) -> PlatformSearch
toPlatformSearch result =
    case result of
        Ok matches ->
            PlatformMatches matches

        Err error ->
            PlatformFailed error


isCurrentSearch : Int -> FrontendModel -> Bool
isCurrentSearch searchId model =
    searchId == model.searchId


isPressMsg : Msg -> Bool
isPressMsg msg =
    case msg of
        TypedTweetLink _ ->
            False

        PressedSearch ->
            True

        GotTweet _ _ ->
            False

        GotBlueskyMatches _ _ ->
            False

        GotMastodonMatches _ _ ->
            False



-- READING THE LINK


{-| Pick the tweet out of anything that identifies one: a link from twitter or
from one of the proxies people paste instead, with or without the scheme, and
the bare id on its own.
-}
parseTweetUrl : String -> Maybe TweetRef
parseTweetUrl text =
    let
        trimmed : String
        trimmed =
            String.trim text
    in
    if trimmed /= "" && String.all Char.isDigit trimmed then
        Just { handle = Nothing, statusId = trimmed }

    else
        case Url.fromString trimmed of
            Just url ->
                tweetRefFromUrl url

            Nothing ->
                Url.fromString ("https://" ++ trimmed) |> Maybe.andThen tweetRefFromUrl


tweetRefFromUrl : Url.Url -> Maybe TweetRef
tweetRefFromUrl url =
    if isTwitterHost url.host then
        case pathSegments url.path of
            handle :: "status" :: statusId :: _ ->
                toTweetRef handle statusId

            handle :: "statuses" :: statusId :: _ ->
                toTweetRef handle statusId

            _ ->
                Nothing

    else
        Nothing


toTweetRef : String -> String -> Maybe TweetRef
toTweetRef handle statusId =
    if statusId /= "" && String.all Char.isDigit statusId then
        Just
            { handle =
                if handle == "i" || handle == "" then
                    Nothing

                else
                    Just handle
            , statusId = statusId
            }

    else
        Nothing


{-| The proxies exist so that links unfurl properly elsewhere, so a link people
want looked up is as likely to come from one of them as from twitter itself.
-}
isTwitterHost : String -> Bool
isTwitterHost host =
    let
        withoutSubdomain : String
        withoutSubdomain =
            List.foldl
                (\subdomain rest ->
                    if String.startsWith subdomain rest then
                        String.dropLeft (String.length subdomain) rest

                    else
                        rest
                )
                (String.toLower host)
                [ "www.", "mobile.", "m." ]
    in
    List.member
        withoutSubdomain
        [ "twitter.com"
        , "x.com"
        , "fxtwitter.com"
        , "fixupx.com"
        , "vxtwitter.com"
        , "fixvx.com"
        , "twittpr.com"
        , "xcancel.com"
        , "nitter.net"
        ]
        || String.startsWith "nitter." withoutSubdomain


pathSegments : String -> List String
pathSegments path =
    String.split "/" path |> List.filter (\segment -> segment /= "")



-- LOOKING UP THE TWEET


fxTwitterUrl : TweetRef -> String
fxTwitterUrl tweetRef =
    Url.Builder.crossOrigin
        "https://api.fxtwitter.com"
        (case tweetRef.handle of
            Just handle ->
                [ handle, "status", tweetRef.statusId ]

            Nothing ->
                [ "status", tweetRef.statusId ]
        )
        []


decodeTweet : Decoder Tweet
decodeTweet =
    Json.Decode.field "tweet"
        (Json.Decode.map6 Tweet
            (Json.Decode.field "url" Json.Decode.string)
            (Json.Decode.field "text" Json.Decode.string)
            (Json.Decode.field "created_timestamp" Json.Decode.int
                |> Json.Decode.map (\seconds -> Time.millisToPosix (seconds * 1000))
            )
            (Json.Decode.at [ "author", "screen_name" ] Json.Decode.string)
            (Json.Decode.at [ "author", "name" ] Json.Decode.string)
            (Json.Decode.field "author" decodeAuthorBio)
        )


{-| The bio and the link next to it, joined together, because both are places
people write where else they can be found.
-}
decodeAuthorBio : Decoder String
decodeAuthorBio =
    Json.Decode.map2
        (\description website -> description ++ " " ++ website)
        (decodeOptionalString "description")
        (Json.Decode.maybe (Json.Decode.at [ "website", "url" ] Json.Decode.string)
            |> Json.Decode.map (Maybe.withDefault "")
        )



-- BLUESKY


findBlueskyMatches : Tweet -> Task restriction Http.Error (List Match)
findBlueskyMatches tweet =
    searchTerms tweet
        |> List.map (\term -> searchBlueskyActors term)
        |> Task.sequence
        |> Task.andThen
            (\actors ->
                blueskyAccounts tweet (List.concat actors)
                    |> List.map (\handle -> blueskyPosts tweet handle)
                    |> Task.sequence
            )
        |> Task.map (\posts -> rankMatches (List.concat posts))


searchBlueskyActors : String -> Task restriction Http.Error (List BlueskyActor)
searchBlueskyActors term =
    Url.Builder.crossOrigin
        blueskyApi
        [ "xrpc", "app.bsky.actor.searchActors" ]
        [ Url.Builder.string "q" term, Url.Builder.int "limit" 10 ]
        |> jsonTask decodeBlueskyActors


{-| The accounts on Bluesky worth reading through. Someone who says where they
went writes it in their bio, and everyone else has to be guessed at from the
handle and the name they go by.
-}
blueskyAccounts : Tweet -> List BlueskyActor -> List String
blueskyAccounts tweet actors =
    (blueskyHandlesIn tweet.authorBio
        ++ [ String.toLower tweet.authorHandle ++ ".bsky.social" ]
        ++ (List.Extra.uniqueBy (\actor -> actor.handle) actors
                |> bestAccounts tweet
                |> List.map (\actor -> String.toLower actor.handle)
           )
    )
        |> List.Extra.unique
        |> List.take maxAccountsPerSite


blueskyPosts : Tweet -> String -> Task restriction Http.Error (List Match)
blueskyPosts tweet handle =
    Url.Builder.crossOrigin
        blueskyApi
        [ "xrpc", "app.bsky.feed.getAuthorFeed" ]
        [ Url.Builder.string "actor" handle
        , Url.Builder.int "limit" 60
        , Url.Builder.string "filter" "posts_no_replies"

        -- A feed cursor is the timestamp of the last post handed out, so starting
        -- from one made up out of the tweet's time skips straight back to when the
        -- cross-post would have gone up instead of paging back from today.
        , Url.Builder.string "cursor" (Iso8601.fromTime (Duration.addTo tweet.createdAt searchWindow))
        ]
        |> jsonTask decodeBlueskyFeed
        |> Task.map (\posts -> List.map (\post -> toMatch tweet post) posts)
        |> Task.onError (\_ -> Task.succeed [])


blueskyApi : String
blueskyApi =
    "https://public.api.bsky.app"


type alias BlueskyActor =
    { handle : String
    , displayName : String
    , description : String
    }


decodeBlueskyActors : Decoder (List BlueskyActor)
decodeBlueskyActors =
    Json.Decode.field "actors" (Json.Decode.list (Json.Decode.maybe decodeBlueskyActor))
        |> Json.Decode.map (\actors -> List.filterMap identity actors)


decodeBlueskyActor : Decoder BlueskyActor
decodeBlueskyActor =
    Json.Decode.map3
        (\handle displayName description ->
            { handle = handle, displayName = displayName, description = description }
        )
        (Json.Decode.field "handle" Json.Decode.string)
        (decodeOptionalString "displayName")
        (decodeOptionalString "description")


decodeBlueskyFeed : Decoder (List Post)
decodeBlueskyFeed =
    Json.Decode.field "feed" (Json.Decode.list (Json.Decode.maybe decodeBlueskyFeedItem))
        |> Json.Decode.map (\items -> List.filterMap identity items)


decodeBlueskyFeedItem : Decoder Post
decodeBlueskyFeedItem =
    Json.Decode.maybe (Json.Decode.field "reason" Json.Decode.value)
        |> Json.Decode.andThen
            (\reason ->
                case reason of
                    Just _ ->
                        -- A repost carries someone else's words, so it's never the post we're after.
                        Json.Decode.fail "Repost"

                    Nothing ->
                        Json.Decode.field "post" decodeBlueskyPost
            )


decodeBlueskyPost : Decoder Post
decodeBlueskyPost =
    Json.Decode.map4
        (\atUri handle displayName record ->
            { url = blueskyPostUrl handle atUri
            , text = record.text
            , createdAt = record.createdAt
            , authorHandle = handle
            , authorName =
                if displayName == "" then
                    handle

                else
                    displayName
            }
        )
        (Json.Decode.field "uri" Json.Decode.string)
        (Json.Decode.at [ "author", "handle" ] Json.Decode.string)
        (Json.Decode.field "author" (decodeOptionalString "displayName"))
        (Json.Decode.field "record" decodeBlueskyRecord)


decodeBlueskyRecord : Decoder { text : String, createdAt : Time.Posix }
decodeBlueskyRecord =
    Json.Decode.map2
        (\text createdAt -> { text = text, createdAt = createdAt })
        (Json.Decode.field "text" Json.Decode.string)
        (Json.Decode.field "createdAt" Iso8601.decoder)


{-| Posts are named `at://did:plc:abc/app.bsky.feed.post/xyz` in the API and
`bsky.app/profile/handle/post/xyz` in a browser.
-}
blueskyPostUrl : String -> String -> String
blueskyPostUrl handle atUri =
    Url.Builder.crossOrigin
        "https://bsky.app"
        [ "profile"
        , handle
        , "post"
        , String.split "/" atUri |> List.Extra.last |> Maybe.withDefault ""
        ]
        []


{-| Bluesky handles as people write them in a bio, either as a handle ending in
`.bsky.social` or as a link to the profile.
-}
blueskyHandlesIn : String -> List String
blueskyHandlesIn text =
    String.words text |> List.filterMap blueskyHandle


blueskyHandle : String -> Maybe String
blueskyHandle word =
    let
        trimmed : String
        trimmed =
            trimPunctuation word

        withoutAt : String
        withoutAt =
            if String.startsWith "@" trimmed then
                String.dropLeft 1 trimmed

            else
                trimmed
    in
    if String.endsWith ".bsky.social" withoutAt && withoutAt /= ".bsky.social" then
        Just (String.toLower withoutAt)

    else
        case Url.fromString withoutAt of
            Just url ->
                case ( String.toLower url.host, pathSegments url.path ) of
                    ( "bsky.app", "profile" :: handle :: _ ) ->
                        Just (String.toLower handle)

                    _ ->
                        Nothing

            Nothing ->
                Nothing



-- MASTODON


{-| Mastodon's search only reaches accounts the instance running it has already
heard of, so asking the biggest instance covers the most of the fediverse.
Searching doesn't need an API key as long as we don't ask it to go and fetch
accounts it hasn't seen before.
-}
mastodonIndex : String
mastodonIndex =
    "https://mastodon.social"


findMastodonMatches : Tweet -> Task restriction Http.Error (List Match)
findMastodonMatches tweet =
    Task.map2
        (\fromBio fromSearch -> rankMatches (fromBio ++ fromSearch))
        (mastodonBioMatches tweet)
        (mastodonSearchMatches tweet)


{-| An account named in the bio is the one place the person has said outright
where they are, so it's worth reading even when the instance it's on is one
mastodon.social has never heard of.
-}
mastodonBioMatches : Tweet -> Task restriction Http.Error (List Match)
mastodonBioMatches tweet =
    fediverseHandlesIn tweet.authorBio
        |> List.take maxAccountsPerSite
        |> List.map (\handle -> mastodonHandlePosts tweet handle)
        |> Task.sequence
        |> Task.map List.concat


mastodonHandlePosts : Tweet -> { user : String, instance : String } -> Task restriction Http.Error (List Match)
mastodonHandlePosts tweet handle =
    let
        instance : String
        instance =
            "https://" ++ handle.instance
    in
    Url.Builder.crossOrigin
        instance
        [ "api", "v1", "accounts", "lookup" ]
        [ Url.Builder.string "acct" handle.user ]
        |> jsonTask (Json.Decode.field "id" Json.Decode.string)
        |> Task.andThen
            (\accountId -> mastodonPosts tweet { instance = instance, accountId = accountId })
        |> Task.onError (\_ -> Task.succeed [])


mastodonSearchMatches : Tweet -> Task restriction Http.Error (List Match)
mastodonSearchMatches tweet =
    searchTerms tweet
        |> List.map (\term -> searchMastodonAccounts term)
        |> Task.sequence
        |> Task.andThen
            (\accounts ->
                List.concat accounts
                    |> List.Extra.uniqueBy (\account -> account.id)
                    |> bestAccounts tweet
                    |> List.map
                        (\account ->
                            mastodonPosts tweet { instance = mastodonIndex, accountId = account.id }
                        )
                    |> Task.sequence
            )
        |> Task.map List.concat


searchMastodonAccounts : String -> Task restriction Http.Error (List MastodonAccount)
searchMastodonAccounts term =
    Url.Builder.crossOrigin
        mastodonIndex
        [ "api", "v2", "search" ]
        [ Url.Builder.string "q" term
        , Url.Builder.string "type" "accounts"
        , Url.Builder.int "limit" 10
        ]
        |> jsonTask decodeMastodonAccounts


mastodonPosts : Tweet -> { instance : String, accountId : String } -> Task restriction Http.Error (List Match)
mastodonPosts tweet account =
    Url.Builder.crossOrigin
        account.instance
        [ "api", "v1", "accounts", account.accountId, "statuses" ]
        [ Url.Builder.int "limit" 40
        , Url.Builder.string "exclude_replies" "true"
        , Url.Builder.string "exclude_reblogs" "true"
        , Url.Builder.string "max_id" (mastodonIdAt (Duration.addTo tweet.createdAt searchWindow))
        ]
        |> jsonTask decodeMastodonStatuses
        |> Task.map (\posts -> List.map (\post -> toMatch tweet post) posts)
        |> Task.onError (\_ -> Task.succeed [])


{-| Mastodon counts milliseconds since 1970 in the top bits of a post id, so an
id built out of a time asks for the posts from around then rather than the most
recent ones.
-}
mastodonIdAt : Time.Posix -> String
mastodonIdAt time =
    String.fromInt (Time.posixToMillis time * 65536)


type alias MastodonAccount =
    { id : String
    , handle : String
    , displayName : String
    , description : String
    }


decodeMastodonAccounts : Decoder (List MastodonAccount)
decodeMastodonAccounts =
    Json.Decode.field "accounts" (Json.Decode.list (Json.Decode.maybe decodeMastodonAccount))
        |> Json.Decode.map (\accounts -> List.filterMap identity accounts)


decodeMastodonAccount : Decoder MastodonAccount
decodeMastodonAccount =
    Json.Decode.map4
        (\id acct displayName note ->
            { id = id, handle = acct, displayName = displayName, description = stripHtml note }
        )
        (Json.Decode.field "id" Json.Decode.string)
        (Json.Decode.field "acct" Json.Decode.string)
        (decodeOptionalString "display_name")
        (decodeOptionalString "note")


decodeMastodonStatuses : Decoder (List Post)
decodeMastodonStatuses =
    Json.Decode.list (Json.Decode.maybe decodeMastodonStatus)
        |> Json.Decode.map (\statuses -> List.filterMap identity statuses)


decodeMastodonStatus : Decoder Post
decodeMastodonStatus =
    Json.Decode.map5
        (\url content createdAt acct displayName ->
            { url = url
            , text = stripHtml content
            , createdAt = createdAt
            , authorHandle = mastodonFullHandle url acct
            , authorName =
                if displayName == "" then
                    acct

                else
                    displayName
            }
        )
        (Json.Decode.oneOf
            [ Json.Decode.field "url" Json.Decode.string
            , Json.Decode.field "uri" Json.Decode.string
            ]
        )
        (Json.Decode.field "content" Json.Decode.string)
        (Json.Decode.field "created_at" Iso8601.decoder)
        (Json.Decode.at [ "account", "acct" ] Json.Decode.string)
        (Json.Decode.field "account" (decodeOptionalString "display_name"))


{-| An account local to the instance answering has no instance in its `acct`,
which reads as an incomplete handle once it's out of that context.
-}
mastodonFullHandle : String -> String -> String
mastodonFullHandle statusUrl acct =
    if String.contains "@" acct then
        acct

    else
        case Url.fromString statusUrl of
            Just url ->
                acct ++ "@" ++ url.host

            Nothing ->
                acct


{-| Fediverse handles as people write them in a bio, either as `@name@instance`
or as a link to the profile page.
-}
fediverseHandlesIn : String -> List { user : String, instance : String }
fediverseHandlesIn text =
    String.words text |> List.filterMap fediverseHandle


fediverseHandle : String -> Maybe { user : String, instance : String }
fediverseHandle word =
    let
        trimmed : String
        trimmed =
            trimPunctuation word
    in
    case String.split "@" trimmed of
        [ "", user, instance ] ->
            if user /= "" && isHostName instance then
                Just { user = user, instance = String.toLower instance }

            else
                Nothing

        _ ->
            case Url.fromString trimmed of
                Just url ->
                    case pathSegments url.path of
                        [ user ] ->
                            if String.startsWith "@" user && String.length user > 1 then
                                Just
                                    { user = String.dropLeft 1 user
                                    , instance = String.toLower url.host
                                    }

                            else
                                Nothing

                        _ ->
                            Nothing

                Nothing ->
                    Nothing


isHostName : String -> Bool
isHostName text =
    String.contains "." text
        && not (String.startsWith "." text)
        && not (String.endsWith "." text)
        && String.all (\char -> Char.isAlphaNum char || char == '.' || char == '-') text



-- DECIDING WHAT COUNTS AS THE SAME POST


{-| The handle and the name to search the other sites for. People rarely get to
keep their handle when they move, but the name they go by follows them, so both
are worth asking about.
-}
searchTerms : Tweet -> List String
searchTerms tweet =
    [ tweet.authorHandle, tweet.authorName ]
        |> List.filter (\term -> String.trim term /= "")
        |> List.Extra.uniqueBy String.toLower


{-| The accounts a search turned up that are most likely to belong to whoever
wrote the tweet, best first. Being wrong is cheap in both directions: a missed
account only means one fewer place to look, and a wrong one won't have a post
that matches.
-}
bestAccounts :
    Tweet
    -> List { a | handle : String, displayName : String, description : String }
    -> List { a | handle : String, displayName : String, description : String }
bestAccounts tweet accounts =
    List.filter (\account -> accountScore tweet account > 0) accounts
        |> List.sortBy (\account -> -(accountScore tweet account))
        |> List.take maxAccountsPerSite


{-| Nobody writes down which twitter account is theirs in a way that can be
followed, so how much an account looks like the same person is guesswork. Going
by the name counts for more than going by the handle, because a name is
distinctive while a short handle collects namesakes.
-}
accountScore : Tweet -> { a | handle : String, displayName : String, description : String } -> Int
accountScore tweet account =
    let
        handle : String
        handle =
            String.toLower tweet.authorHandle

        sameName : Int
        sameName =
            if String.toLower account.displayName == String.toLower tweet.authorName then
                2

            else
                0

        bioMentionsTheTweeter : Int
        bioMentionsTheTweeter =
            if String.contains handle (String.toLower account.description) then
                2

            else
                0

        sameHandle : Int
        sameHandle =
            if handleRoot account.handle == handle then
                1

            else
                0
    in
    sameName + bioMentionsTheTweeter + sameHandle


{-| The part of a handle the person picked themselves: `martin` out of
`martin.bsky.social` or `martin@mastodon.social`.
-}
handleRoot : String -> String
handleRoot handle =
    String.toLower handle
        |> String.split "@"
        |> List.head
        |> Maybe.withDefault ""
        |> String.split "."
        |> List.head
        |> Maybe.withDefault ""


toMatch : Tweet -> Post -> Match
toMatch tweet post =
    { post = post, similarity = similarity tweet.text post.text }


{-| How much of the same thing two posts say, from 0 to 1.

Cross-posts are rarely identical: links get rewritten, long posts get cut short
and mentions get pointed at accounts on the site the post ended up on. Comparing
the three-character runs the two have in common copes with all of that, and
unlike splitting into words it doesn't care what language the post is in.

-}
similarity : String -> String -> Float
similarity left right =
    let
        leftText : String
        leftText =
            normalizeText left

        rightText : String
        rightText =
            normalizeText right
    in
    if leftText == "" || rightText == "" then
        0

    else if leftText == rightText then
        1

    else
        max
            (diceCoefficient (trigrams leftText) (trigrams rightText))
            (containment leftText rightText)


diceCoefficient : Set String -> Set String -> Float
diceCoefficient left right =
    case Set.size left + Set.size right of
        0 ->
            0

        total ->
            2 * toFloat (Set.size (Set.intersect left right)) / toFloat total


trigrams : String -> Set String
trigrams text =
    List.range 0 (String.length text - 3)
        |> List.map (\index -> String.slice index (index + 3) text)
        |> Set.fromList


{-| A cross-post that got cut short, or one that added a line pointing back at
the original, still holds the whole of the other post. There has to be enough
text for that to mean anything though, or every "thanks!" matches every other.
-}
containment : String -> String -> Float
containment left right =
    if
        min (String.length left) (String.length right)
            >= 24
            && (String.contains left right || String.contains right left)
    then
        0.9

    else
        0


{-| Drop everything a cross-post is likely to have changed, leaving just what
the post said.
-}
normalizeText : String -> String
normalizeText text =
    String.toLower text
        |> String.words
        |> List.filter (\word -> not (isLink word))
        |> List.map (\word -> String.filter (\char -> not (isPunctuation char)) word)
        |> List.filter (\word -> word /= "")
        |> String.join " "


isLink : String -> Bool
isLink word =
    String.startsWith "http://" word
        || String.startsWith "https://" word
        || String.startsWith "www." word


isPunctuation : Char -> Bool
isPunctuation char =
    String.contains (String.fromChar char) punctuationCharacters


punctuationCharacters : String
punctuationCharacters =
    ".,!?;:'\"“”‘’()[]{}<>…—–-*_#@/\\|`~"


trimPunctuation : String -> String
trimPunctuation word =
    String.toList word
        |> List.Extra.dropWhile isTrimmablePunctuation
        |> List.Extra.dropWhileRight isTrimmablePunctuation
        |> String.fromList


isTrimmablePunctuation : Char -> Bool
isTrimmablePunctuation char =
    String.contains (String.fromChar char) ".,!?;:'\"“”‘’()[]{}<>…"


rankMatches : List Match -> List Match
rankMatches matches =
    List.filter (\match -> match.similarity >= matchThreshold) matches
        |> List.Extra.uniqueBy (\match -> match.post.url)
        |> List.sortBy (\match -> -match.similarity)
        |> List.take maxMatchesPerSite


{-| How alike two posts have to read before it's worth showing one. Low enough
that a cross-post which got cut short still counts, high enough that two posts
which happen to share a turn of phrase don't.
-}
matchThreshold : Float
matchThreshold =
    0.5


maxAccountsPerSite : Int
maxAccountsPerSite =
    3


maxMatchesPerSite : Int
maxMatchesPerSite =
    5


{-| How far past the tweet to start reading. A cross-post normally goes up
within seconds, but one that was posted by hand later in the day should still
turn up.
-}
searchWindow : Duration
searchWindow =
    Duration.days 2



-- HTTP


jsonTask : Decoder a -> String -> Task restriction Http.Error a
jsonTask decoder url =
    Http.task
        { method = "GET"
        , headers = []
        , url = url
        , body = Http.emptyBody
        , resolver =
            Http.stringResolver
                (\response ->
                    case response of
                        BadUrl_ badUrl ->
                            Err (Http.BadUrl badUrl)

                        Timeout_ ->
                            Err Http.Timeout

                        NetworkError_ ->
                            Err Http.NetworkError

                        BadStatus_ metadata _ ->
                            Err (Http.BadStatus metadata.statusCode)

                        GoodStatus_ _ body ->
                            case Json.Decode.decodeString decoder body of
                                Ok ok ->
                                    Ok ok

                                Err error ->
                                    Json.Decode.errorToString error |> Http.BadBody |> Err
                )
        , timeout = Just (Duration.seconds 30)
        }


decodeOptionalString : String -> Decoder String
decodeOptionalString fieldName =
    Json.Decode.maybe (Json.Decode.field fieldName Json.Decode.string)
        |> Json.Decode.map (Maybe.withDefault "")


{-| Mastodon hands out post text as html, and the only part of it worth keeping
is the words.

Only the tags that put text on a new line become a space. Mastodon wraps a link
in spans so that the browser can hide the dull half of it, and turning those
into spaces would leave a link broken into pieces that no longer looks like one.

-}
stripHtml : String -> String
stripHtml html =
    String.replace "<br>" " " html
        |> String.replace "<br/>" " "
        |> String.replace "<br />" " "
        |> String.replace "</p>" " "
        |> String.replace "</div>" " "
        |> String.replace "</li>" " "
        |> dropTags
        -- Last, so that text which was escaped to keep it out of the html isn't
        -- read as html once it's been unescaped.
        |> decodeHtmlEntities


dropTags : String -> String
dropTags html =
    String.foldl
        (\char ( insideTag, characters ) ->
            if char == '<' then
                ( True, characters )

            else if char == '>' then
                ( False, characters )

            else if insideTag then
                ( True, characters )

            else
                ( False, char :: characters )
        )
        ( False, [] )
        html
        |> Tuple.second
        |> List.reverse
        |> String.fromList


decodeHtmlEntities : String -> String
decodeHtmlEntities text =
    String.replace "&lt;" "<" text
        |> String.replace "&gt;" ">"
        |> String.replace "&quot;" "\""
        |> String.replace "&apos;" "'"
        |> String.replace "&#39;" "'"
        |> String.replace "&#x27;" "'"
        |> String.replace "&nbsp;" " "
        |> String.replace "&hellip;" "…"
        -- Last, so that an escaped escape doesn't turn into a real one.
        |> String.replace "&amp;" "&"


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl url ->
            "Tried to load " ++ url ++ " which isn't a valid address."

        Http.Timeout ->
            "The request took too long."

        Http.NetworkError ->
            "Couldn't reach the server."

        Http.BadStatus 404 ->
            "It wasn't found. It might be from an account that's private or gone."

        Http.BadStatus status ->
            "The server replied with an error (" ++ String.fromInt status ++ ")."

        Http.BadBody _ ->
            "The reply wasn't in the shape we expected."



-- VIEW


tweetLinkInputId : HtmlId
tweetLinkInputId =
    Dom.id "postFinder_tweetLink"


searchButtonId : HtmlId
searchButtonId =
    Dom.id "postFinder_search"


view : Coord CssPixels -> Time.Zone -> FrontendModel -> Element Msg
view windowSize timezone model =
    Ui.column
        [ MyUi.notoSans
        , Ui.Font.color MyUi.font1
        , Ui.paddingXY
            (if MyUi.isMobileAlt windowSize then
                16

             else
                48
            )
            32
        , Ui.spacing 24
        , Ui.widthMax 900
        , Ui.centerX
        , Ui.height Ui.fill
        , Ui.scrollable
        ]
        [ Ui.el [ Ui.Font.size 24, Ui.Font.bold ] (Ui.text "Find a post on other sites")
        , Ui.el
            [ Ui.Font.color MyUi.font2 ]
            (Ui.text "Paste a link to a tweet and this looks for the same post on Bluesky and Mastodon.")
        , searchBoxView model.input
        , searchView timezone model.search
        ]


searchBoxView : String -> Element Msg
searchBoxView input =
    Ui.row
        [ Ui.spacing 8 ]
        [ Ui.Input.text
            [ MyUi.id tweetLinkInputId
            , Ui.background MyUi.inputBackground
            , Ui.border 1
            , Ui.borderColor MyUi.inputBorder
            , Ui.rounded 4
            , Ui.paddingXY 8 6
            , Ui.Events.preventDefaultOn
                "keydown"
                (Json.Decode.field "key" Json.Decode.string
                    |> Json.Decode.andThen
                        (\key ->
                            if key == "Enter" then
                                Json.Decode.succeed ( PressedSearch, True )

                            else
                                Json.Decode.fail ""
                        )
                )
            ]
            { onChange = TypedTweetLink
            , text = input
            , placeholder = Just "https://x.com/username/status/1234567890"
            , label = Ui.Input.labelHidden "Link to a tweet"
            }
        , MyUi.simpleButton searchButtonId PressedSearch (Ui.text "Search")
        ]


searchView : Time.Zone -> Search -> Element msg
searchView timezone search =
    case search of
        NoSearch ->
            Ui.none

        NotATweetLink ->
            Ui.el
                [ Ui.Font.color MyUi.errorColor ]
                (Ui.text "That isn't a link to a tweet. It should look like https://x.com/username/status/1234567890")

        LoadingTweet ->
            Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text "Looking up the tweet...")

        TweetFailed error ->
            Ui.el
                [ Ui.Font.color MyUi.errorColor ]
                (Ui.text ("Couldn't load the tweet. " ++ httpErrorToString error))

        FoundTweet tweet results ->
            Ui.column
                [ Ui.spacing 24 ]
                [ tweetView timezone tweet
                , platformView "Bluesky" tweet.createdAt results.bluesky
                , platformView "Mastodon" tweet.createdAt results.mastodon
                ]


tweetView : Time.Zone -> Tweet -> Element msg
tweetView timezone tweet =
    Ui.column
        [ Ui.spacing 8
        , Ui.padding 12
        , Ui.background MyUi.background1
        , Ui.border 1
        , Ui.borderColor MyUi.border1
        , Ui.rounded 4
        ]
        [ authorView tweet.authorName ("@" ++ tweet.authorHandle)
        , Ui.el [ MyUi.prewrap ] (Ui.text tweet.text)
        , Ui.el
            [ Ui.Font.size 14, Ui.Font.color MyUi.font3 ]
            (Ui.text (MyUi.datestamp timezone tweet.createdAt))
        , postLinkView tweet.url "Open the tweet"
        ]


platformView : String -> Time.Posix -> PlatformSearch -> Element msg
platformView siteName tweetTime platformSearch =
    Ui.column
        [ Ui.spacing 8 ]
        [ Ui.el [ Ui.Font.size 18, Ui.Font.bold ] (Ui.text siteName)
        , case platformSearch of
            SearchingPlatform ->
                Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text ("Looking through " ++ siteName ++ "..."))

            PlatformFailed error ->
                Ui.el
                    [ Ui.Font.color MyUi.errorColor ]
                    (Ui.text (siteName ++ " couldn't be searched. " ++ httpErrorToString error))

            PlatformMatches [] ->
                Ui.el
                    [ Ui.Font.color MyUi.font3 ]
                    (Ui.text ("Nothing on " ++ siteName ++ " looks like this tweet."))

            PlatformMatches matches ->
                Ui.column
                    [ Ui.spacing 8 ]
                    (List.map (\match -> matchView tweetTime match) matches)
        ]


matchView : Time.Posix -> Match -> Element msg
matchView tweetTime match =
    Ui.column
        [ Ui.spacing 8
        , Ui.padding 12
        , Ui.background MyUi.background1
        , Ui.border 1
        , Ui.borderColor MyUi.border1
        , Ui.rounded 4
        ]
        [ authorView match.post.authorName ("@" ++ match.post.authorHandle)
        , Ui.el [ MyUi.prewrap ] (Ui.text match.post.text)
        , Ui.el
            [ Ui.Font.size 14, Ui.Font.color MyUi.font3 ]
            (Ui.text
                (String.fromInt (round (match.similarity * 100))
                    ++ "% the same, posted "
                    ++ offsetFromTweet tweetTime match.post.createdAt
                )
            )
        , postLinkView match.post.url "Open the post"
        ]


authorView : String -> String -> Element msg
authorView displayName handle =
    Ui.row
        [ Ui.spacing 8 ]
        [ Ui.el [ Ui.Font.bold ] (Ui.text displayName)
        , Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text handle)
        ]


postLinkView : String -> String -> Element msg
postLinkView url text =
    Ui.el
        [ Ui.linkNewTab url
        , Ui.Font.color MyUi.textLinkColorOnDarkBackground
        , Ui.width Ui.shrink
        ]
        (Ui.text text)


{-| How long after the tweet the post went up, which is what separates a
cross-post from someone saying the same thing weeks later.
-}
offsetFromTweet : Time.Posix -> Time.Posix -> String
offsetFromTweet tweetTime postTime =
    if
        Duration.from tweetTime postTime
            |> Quantity.abs
            |> Quantity.lessThan (Duration.minutes 2)
    then
        "at the same time as the tweet"

    else if Time.posixToMillis postTime < Time.posixToMillis tweetTime then
        MyUi.timeElapsed postTime tweetTime ++ " before the tweet"

    else
        MyUi.timeElapsed tweetTime postTime ++ " after the tweet"
