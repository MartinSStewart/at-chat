module PostFinderTests exposing (tests)

import Expect
import PostFinder
import Test exposing (Test)


tests : Test
tests =
    Test.describe
        "Post finder tests"
        [ Test.describe "Reading a tweet link"
            [ Test.test "Twitter link" <|
                \_ ->
                    PostFinder.parseTweetUrl "https://twitter.com/MartinSStewart/status/1234567890123456789"
                        |> Expect.equal
                            (Just { handle = Just "MartinSStewart", statusId = "1234567890123456789" })
            , Test.test "x.com link" <|
                \_ ->
                    PostFinder.parseTweetUrl "https://x.com/jack/status/20"
                        |> Expect.equal (Just { handle = Just "jack", statusId = "20" })
            , Test.test "Tracking parameters and a photo on the end are ignored" <|
                \_ ->
                    PostFinder.parseTweetUrl "https://x.com/jack/status/20/photo/1?s=20&t=xj4Rt"
                        |> Expect.equal (Just { handle = Just "jack", statusId = "20" })
            , Test.test "A proxy link works the same as the real thing" <|
                \_ ->
                    PostFinder.parseTweetUrl "https://fxtwitter.com/jack/status/20"
                        |> Expect.equal (Just { handle = Just "jack", statusId = "20" })
            , Test.test "So does a nitter instance" <|
                \_ ->
                    PostFinder.parseTweetUrl "https://nitter.poast.org/jack/status/20"
                        |> Expect.equal (Just { handle = Just "jack", statusId = "20" })
            , Test.test "Subdomains are ignored" <|
                \_ ->
                    PostFinder.parseTweetUrl "https://mobile.twitter.com/jack/statuses/20"
                        |> Expect.equal (Just { handle = Just "jack", statusId = "20" })
            , Test.test "A link pasted without the scheme still works" <|
                \_ ->
                    PostFinder.parseTweetUrl "x.com/jack/status/20"
                        |> Expect.equal (Just { handle = Just "jack", statusId = "20" })
            , Test.test "Surrounding whitespace is ignored" <|
                \_ ->
                    PostFinder.parseTweetUrl "  https://x.com/jack/status/20\n"
                        |> Expect.equal (Just { handle = Just "jack", statusId = "20" })
            , Test.test "A link that hides the handle still names a tweet" <|
                \_ ->
                    PostFinder.parseTweetUrl "https://x.com/i/status/20"
                        |> Expect.equal (Just { handle = Nothing, statusId = "20" })
            , Test.test "A bare id names a tweet too" <|
                \_ ->
                    PostFinder.parseTweetUrl "1234567890123456789"
                        |> Expect.equal
                            (Just { handle = Nothing, statusId = "1234567890123456789" })
            , Test.test "A link to something other than a tweet is rejected" <|
                \_ ->
                    PostFinder.parseTweetUrl "https://x.com/jack"
                        |> Expect.equal Nothing
            , Test.test "A link to another site is rejected" <|
                \_ ->
                    PostFinder.parseTweetUrl "https://bsky.app/profile/jay.bsky.team/post/3lab"
                        |> Expect.equal Nothing
            , Test.test "A host that merely ends in twitter.com is rejected" <|
                \_ ->
                    PostFinder.parseTweetUrl "https://nottwitter.com/jack/status/20"
                        |> Expect.equal Nothing
            , Test.test "Nothing at all is rejected" <|
                \_ ->
                    PostFinder.parseTweetUrl "" |> Expect.equal Nothing
            ]
        , Test.describe "Comparing what two posts say"
            [ Test.test "The same words score 1" <|
                \_ ->
                    PostFinder.similarity "Just setting up my twttr" "Just setting up my twttr"
                        |> Expect.within (Expect.Absolute 0.0001) 1
            , Test.test "Punctuation and capitals don't matter" <|
                \_ ->
                    PostFinder.similarity "Just setting up my twttr!" "just setting up my twttr"
                        |> Expect.within (Expect.Absolute 0.0001) 1
            , Test.test "A cross-post whose link was rewritten still matches" <|
                \_ ->
                    PostFinder.similarity
                        "New blog post about elm-review https://t.co/aBcDeFg"
                        "New blog post about elm-review https://jfmengels.net/elm-review"
                        |> Expect.within (Expect.Absolute 0.0001) 1
            , Test.test "A cross-post that got cut short still matches" <|
                \_ ->
                    PostFinder.similarity
                        "I spent the weekend writing a parser for a language nobody uses and I regret nothing at all"
                        "I spent the weekend writing a parser for a language nobody uses and I regret..."
                        |> Expect.greaterThan 0.7
            , Test.test "Two unrelated posts score low" <|
                \_ ->
                    PostFinder.similarity
                        "Just setting up my twttr"
                        "Here are seven photographs of my cat sleeping in a cardboard box"
                        |> Expect.lessThan 0.4
            , Test.test "Two short posts that share a word aren't a match" <|
                \_ ->
                    PostFinder.similarity "thanks!" "thanks for the write up"
                        |> Expect.lessThan 0.4
            , Test.test "Nothing to compare scores 0" <|
                \_ ->
                    PostFinder.similarity "" "Just setting up my twttr"
                        |> Expect.within (Expect.Absolute 0.0001) 0
            , Test.test "A post that's only a link has nothing to compare" <|
                \_ ->
                    PostFinder.normalizeText "https://example.com" |> Expect.equal ""
            ]
        , Test.describe "Reading accounts out of a twitter bio"
            [ Test.test "A fediverse handle written out in full" <|
                \_ ->
                    PostFinder.fediverseHandlesIn "Elm person. @martin@mastodon.social. He/him."
                        |> Expect.equal [ { user = "martin", instance = "mastodon.social" } ]
            , Test.test "A link to a mastodon profile" <|
                \_ ->
                    PostFinder.fediverseHandlesIn
                        "Creator of things. Mastodon: https://fedi.simonwillison.net/@simon Bsky: http://simonwillison.net"
                        |> Expect.equal [ { user = "simon", instance = "fedi.simonwillison.net" } ]
            , Test.test "An email address isn't a fediverse handle" <|
                \_ ->
                    PostFinder.fediverseHandlesIn "Get in touch: martin@example.com"
                        |> Expect.equal []
            , Test.test "A twitter mention isn't a fediverse handle" <|
                \_ ->
                    PostFinder.fediverseHandlesIn "Works with @someoneelse"
                        |> Expect.equal []
            , Test.test "A bluesky handle written out in full" <|
                \_ ->
                    PostFinder.blueskyHandlesIn "Now over at @martin.bsky.social instead"
                        |> Expect.equal [ "martin.bsky.social" ]
            , Test.test "A link to a bluesky profile" <|
                \_ ->
                    PostFinder.blueskyHandlesIn "https://bsky.app/profile/jay.bsky.team is where I am"
                        |> Expect.equal [ "jay.bsky.team" ]
            , Test.test "A bio with nowhere else named" <|
                \_ ->
                    PostFinder.blueskyHandlesIn "no state is the best state"
                        |> Expect.equal []
            ]
        , Test.describe "Reading Mastodon's html"
            [ Test.test "Tags are dropped and paragraphs stay apart" <|
                \_ ->
                    PostFinder.stripHtml "<p>First line</p><p>Second line</p>"
                        |> PostFinder.normalizeText
                        |> Expect.equal "first line second line"
            , Test.test "Escaped characters are turned back into what they were" <|
                \_ ->
                    PostFinder.stripHtml "<p>Elm &amp; friends &quot;rock&quot;</p>"
                        |> PostFinder.normalizeText
                        |> Expect.equal "elm & friends rock"
            , Test.test "A link split across spans reads as one link" <|
                \_ ->
                    PostFinder.stripHtml
                        "<p>Read it <a href=\"https://example.com/post\"><span class=\"invisible\">https://</span><span>example.com/post</span></a></p>"
                        |> PostFinder.normalizeText
                        |> Expect.equal "read it"
            ]
        ]
