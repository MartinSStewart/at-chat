module E2ESheepGame exposing (tests)

import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Expect
import Html.Attributes
import Id exposing (ChannelMessageId, Id)
import SeqDict
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


tests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
tests normalConfig =
    T.testGroup
        "Sheep game"
        [ sheepGameDmTest normalConfig
        , setupNeedsAQuestionTest normalConfig
        , questionsSurviveAReloadTest normalConfig
        , threePlayerMatchTest normalConfig
        ]


{-| A whole match: the host writes the questions, everyone else answers them, and the host
locks, groups and reveals. A DM only has room for one player besides the host, so this is
the smallest match there is.
-}
sheepGameDmTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
sheepGameDmTest normalConfig =
    E2EHelper.startTest
        "Play a sheep game in a DM"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.tallDesktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ E2EHelper.openDm user 1000 "0"
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , E2EHelper.openDm admin 100 "2"
                        , admin.click 100 (Dom.id "guild_openGamesTab")
                        , admin.click 100 (Dom.id "game_select_Sheep Game (WIP)")

                        -- Cancelling out of the setup goes back to picking a game.
                        , admin.click 100 (Dom.id "sheepGame_cancel")
                        , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "sheepGame_start" ])
                        , admin.click 100 (Dom.id "game_select_Sheep Game (WIP)")
                        , admin.input 100 (Dom.id "sheepGame_question_0") "Name a **colour**"
                        , admin.input 100 (Dom.id "sheepGame_question_1") "Name an animal"
                        , admin.click 100 (Dom.id "sheepGame_start")

                        -- Questions are rich text, so the part the host wrote in asterisks
                        -- is rendered bold rather than shown with the asterisks in it.
                        , admin.checkView
                            100
                            (\view ->
                                Test.Html.Query.findAll
                                    [ Test.Html.Selector.style "font-weight" "700"
                                    , Test.Html.Selector.text "colour"
                                    ]
                                    view
                                    |> Test.Html.Query.count (Expect.greaterThan 0)
                            )

                        -- The host writes the questions rather than answering them, so they
                        -- get no answer of their own to fill in.
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "sheepGame_answer_0" ])
                        , user.click 100 (Dom.id "guild_gameStartedCard_0")

                        -- An answer is written in the same input a question is, buttons and
                        -- all.
                        , user.click 100 (Dom.id "sheepGame_answer_0_openEmojiSelector")
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.id "emoji_search_input" ])
                        , user.click 100 (Dom.id "sheepGame_answer_0_openEmojiSelector")
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "emoji_search_input" ])
                        , user.input 100 (Dom.id "sheepGame_answer_0") "blue"
                        , user.input 100 (Dom.id "sheepGame_answer_1") "Cat"

                        -- There's no button to press: an answer saves itself once the player
                        -- has stopped typing it for a moment, which is what this waits out.
                        , admin.checkView
                            2000
                            (Test.Html.Query.has [ Test.Html.Selector.text "1 player has answered so far" ])

                        -- Saving as they're typed is what makes a refresh survivable, so
                        -- opening the match fresh puts them back in the boxes.
                        , T.connectFrontend
                            100
                            E2EHelper.sessionId1
                            "/"
                            E2EHelper.tallDesktopWindow
                            (\user2 ->
                                [ T.andThen
                                    10
                                    (\data ->
                                        [ user2.portEvent
                                            10
                                            "load_startup_data_from_js"
                                            (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop)
                                        ]
                                    )
                                , user2.click 100 (Dom.id "guild_friendLabel_0")
                                , user2.click 100 (Dom.id "guild_gameStartedCard_0")
                                , user2.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.attribute (Html.Attributes.value "blue") ]
                                    )
                                ]
                            )

                        -- Only the host gets to lock the answers and group them.
                        , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "sheepGame_lockAnswers" ])
                        , admin.click 100 (Dom.id "sheepGame_lockAnswers")
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "The host is grouping the answers" ])

                        -- Unlocking hands the answers back so that someone who was still
                        -- typing gets to finish, and what they'd already sent is still there.
                        , admin.click 100 (Dom.id "sheepGame_unlockAnswers")
                        , user.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.value "blue") ]
                            )
                        , admin.click 100 (Dom.id "sheepGame_lockAnswers")
                        , admin.click 100 (Dom.id "sheepGame_revealScores")

                        -- Nothing is revealed until the host starts stepping through the
                        -- questions.
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.text "The results will be revealed shortly" ]
                            )
                        , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.text "Scoring"
                                , Test.Html.Selector.text "colour"
                                ]
                            )

                        -- The reveal is shared, so the other player sees it without doing
                        -- anything, and the answers that matched are shown together.
                        , user.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.text "Scoring"
                                , Test.Html.Selector.text "blue"
                                ]
                            )

                        -- The question that hasn't been revealed yet isn't given away.
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "Cat" ])
                        , admin.click 100 (Dom.id "sheepGame_showNextQuestion")

                        -- Everything revealed, so the match is summed up: who won, and how
                        -- alike everyone answered.
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "And the winner is" ])
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "And the winner is" ])

                        -- One player is nobody to compare against, so the grid of who thinks
                        -- alike is left out of a match this small.
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.text "Which players think most alike" ]
                            )

                        -- Nobody else is answering, so each question is worth the one point
                        -- for matching yourself.
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "2" ])

                        -- Stepping back hides the last question again, and the summing up
                        -- with it.
                        , admin.click 100 (Dom.id "sheepGame_hidePreviousQuestion")
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "And the winner is" ])
                        ]
                    )
                ]
            )
        ]


{-| The host can't start a match without writing something to answer.
-}
setupNeedsAQuestionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
setupNeedsAQuestionTest normalConfig =
    E2EHelper.startTest
        "A sheep game needs at least one question"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.tallDesktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , admin.click 1000 (Dom.id "guild_friendLabel_0")
                , admin.click 100 (Dom.id "guild_openGamesTab")
                , admin.click 100 (Dom.id "game_select_Sheep Game (WIP)")

                -- The setup opens with questions already written in, so emptying them is what
                -- it takes to have none.
                , admin.input 100 (Dom.id "sheepGame_question_0") ""
                , admin.input 100 (Dom.id "sheepGame_question_1") ""
                , admin.click 100 (Dom.id "sheepGame_start")
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.text "Write at least one question before starting" ])

                -- A question left blank stops the rest from starting.
                , admin.input 100 (Dom.id "sheepGame_question_0") "Name a colour"
                , admin.click 100 (Dom.id "sheepGame_start")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Can't be empty" ])

                -- Writing every question and starting leaves the setup view for the game
                -- itself, where the host locks the answers rather than writing one.
                , admin.input 100 (Dom.id "sheepGame_question_1") "Name an animal"
                , admin.click 100 (Dom.id "sheepGame_start")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "sheepGame_lockAnswers" ])
                ]
            )
        ]


{-| Writing the questions for a sheep game takes a while, so they're kept in the host's
session as they type. A page reload gets them back instead of landing on a blank form,
and starting or cancelling the setup lets go of them again.
-}
questionsSurviveAReloadTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
questionsSurviveAReloadTest normalConfig =
    E2EHelper.startTest
        "Sheep game questions survive a page reload"
        E2EHelper.startTime
        normalConfig
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.tallDesktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , admin.click 1000 (Dom.id "guild_friendLabel_0")
                , admin.click 100 (Dom.id "guild_openGamesTab")
                , admin.click 100 (Dom.id "game_select_Sheep Game (WIP)")

                -- The button beside a question opens the emoji picker for that question.
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "emoji_search_input" ])
                , admin.click 100 (Dom.id "sheepGame_question_0_openEmojiSelector")
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.id "emoji_search_input" ])
                , admin.click 100 (Dom.id "sheepGame_question_0_openEmojiSelector")
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "emoji_search_input" ])
                , admin.input 100 (Dom.id "sheepGame_question_0") "Name a colour"
                , admin.click 100 (Dom.id "sheepGame_addQuestion")
                , admin.input 100 (Dom.id "sheepGame_question_1") "Name an animal"

                -- The questions are only sent once the host has stopped typing for a moment,
                -- so this waits out the debounce before the page is reloaded.
                , admin.checkView
                    2000
                    (Test.Html.Query.has [ Test.Html.Selector.id "sheepGame_start" ])
                , T.connectFrontend
                    100
                    E2EHelper.sessionId0
                    "/"
                    E2EHelper.tallDesktopWindow
                    (\reloaded ->
                        [ T.andThen
                            10
                            (\data ->
                                [ reloaded.portEvent
                                    10
                                    "load_startup_data_from_js"
                                    (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop)
                                ]
                            )
                        , reloaded.click 100 (Dom.id "guild_friendLabel_0")
                        , reloaded.click 100 (Dom.id "guild_openGamesTab")
                        , reloaded.click 100 (Dom.id "game_select_Sheep Game (WIP)")
                        , reloaded.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.value "Name a colour") ]
                            )
                        , reloaded.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.value "Name an animal") ]
                            )

                        -- Cancelling is the host saying they're done with these questions, so
                        -- starting again gives them the blank form they asked for.
                        , reloaded.click 100 (Dom.id "sheepGame_cancel")
                        , reloaded.click 100 (Dom.id "game_select_Sheep Game (WIP)")
                        , reloaded.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.attribute (Html.Attributes.value "Name a colour") ]
                            )
                        ]
                    )
                ]
            )
        ]


{-| A guild channel has room for more than the one player a DM does. Three of them is
enough for the scoreboard to reorder itself as the questions are revealed, and for the
grid at the end to have pairs to compare. One player submits with a question left blank,
so they score nothing for it while everyone else moves on. That player is also the one on
a phone, so the answering and results views are checked at a mobile size as well.
-}
threePlayerMatchTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
threePlayerMatchTest normalConfig =
    E2EHelper.startTest
        "Three players play a sheep game in a guild channel"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectFourUsersAndJoinNewGuild
            E2EHelper.tallDesktopWindow
            (\admin stevie joe wanda ->
                [ -- Wanda plays along on a phone, so the answering and results views are
                  -- rendered at a mobile size here rather than everyone being on desktop.
                  wanda.resizeWindow 0 E2EHelper.iphone14Window
                , admin.click 100 (Dom.id "guild_openGamesTab")
                , admin.click 100 (Dom.id "game_select_Sheep Game (WIP)")

                -- The setup opens with two questions written in, so a third is added.
                , admin.input 100 (Dom.id "sheepGame_question_0") "Name a colour"
                , admin.input 100 (Dom.id "sheepGame_question_1") "Name an animal"
                , admin.click 100 (Dom.id "sheepGame_addQuestion")
                , admin.input 100 (Dom.id "sheepGame_question_2") "Name a fruit"
                , admin.click 100 (Dom.id "sheepGame_start")

                -- Everyone else opens the match from the card it wrote to the channel.
                , T.andThen
                    100
                    (\state ->
                        case guildChannelGameId state.backend of
                            Just messageId ->
                                [ stevie.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString messageId))
                                , joe.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString messageId))
                                , wanda.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString messageId))
                                , stevie.input 100 (Dom.id "sheepGame_answer_0") "Blue"
                                , stevie.input 100 (Dom.id "sheepGame_answer_1") "Cat"
                                , stevie.input 100 (Dom.id "sheepGame_answer_2") "Apple"

                                -- Answers save themselves a moment after the typing stops,
                                -- so there's no button to press here either.
                                , admin.checkView
                                    2000
                                    (Test.Html.Query.has [ Test.Html.Selector.text "1 player has answered so far" ])

                                -- Case doesn't matter to the grouping, so blue scores together with Blue.
                                , joe.input 100 (Dom.id "sheepGame_answer_0") "blue"
                                , joe.input 100 (Dom.id "sheepGame_answer_1") "Dog"
                                , joe.input 100 (Dom.id "sheepGame_answer_2") "apple"

                                -- Wanda can't think of a fruit and submits with that box left empty.
                                , wanda.input 100 (Dom.id "sheepGame_answer_0") "Red"
                                , wanda.input 100 (Dom.id "sheepGame_answer_1") "Dog"
                                , wanda.snapshotView 100 { name = "Sheep game answers on mobile" }

                                -- Answering two of the three questions still counts as playing.
                                , admin.checkView
                                    2000
                                    (Test.Html.Query.has [ Test.Html.Selector.text "3 players have answered so far" ])
                                , admin.click 100 (Dom.id "sheepGame_lockAnswers")

                                -- The host writes a comment on the first question, which the results
                                -- screen shows under it. Notes are rich text like everything else
                                -- here, and save on the same delay, so this waits that out before
                                -- the grouping view goes away.
                                , admin.input 100 (Dom.id "sheepGame_notes_0") "Nobody said **green**"
                                , admin.checkView
                                    2000
                                    (Test.Html.Query.has [ Test.Html.Selector.id "sheepGame_revealScores" ])
                                , admin.click 100 (Dom.id "sheepGame_revealScores")

                                -- Everyone scores the size of the group their answer landed in, so the first
                                -- question leaves Stevie and Joe on 2 apiece and Wanda on 1. Nobody has
                                -- passed anyone yet, so no arrows are drawn.
                                , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                                , wanda.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "Name a colour"
                                        , Test.Html.Selector.text "Nobody said"
                                        ]
                                    )

                                -- The host's comment is drawn as the rich text they wrote, so the
                                -- word they put in asterisks comes out bold.
                                , wanda.checkView
                                    100
                                    (\view ->
                                        Test.Html.Query.findAll
                                            [ Test.Html.Selector.style "font-weight" "700"
                                            , Test.Html.Selector.text "green"
                                            ]
                                            view
                                            |> Test.Html.Query.count (Expect.greaterThan 0)
                                    )
                                , wanda.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Name an animal" ])
                                , wanda.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "▲" ])
                                , wanda.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "▼" ])

                                -- Dog is worth two points to Joe and Wanda while Cat is worth one to Stevie,
                                -- which puts Joe past Stevie: one arrow up and one arrow down.
                                , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                                , wanda.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "Cat"
                                        , Test.Html.Selector.text "Dog"
                                        , Test.Html.Selector.text "▲"
                                        , Test.Html.Selector.text "▼"
                                        ]
                                    )

                                -- The last question is only worth something to the two who answered it, so
                                -- Stevie finishes on 5 and Joe on 6 while Wanda stays on the 3 she had.
                                , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                                , wanda.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.exactText "5"
                                        , Test.Html.Selector.exactText "6"
                                        , Test.Html.Selector.exactText "3"
                                        ]
                                    )
                                , wanda.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "7" ])

                                -- And with three players there are pairs to compare, so the grid turns up
                                -- alongside the winner.
                                , wanda.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "And the winner is"
                                        , Test.Html.Selector.text "Which players think most alike"
                                        , Test.Html.Selector.text "Move your cursor over a grid square"
                                        ]
                                    )
                                , wanda.snapshotView 100 { name = "Sheep game results on mobile" }
                                ]

                            Nothing ->
                                [ T.checkState 0 (\_ -> Err "Expected a sheep game in the guild channel") ]
                    )
                ]
            )
        ]


{-| The channel message the sheep game was started from, which is what the card that opens
the match is named after.
-}
guildChannelGameId : E2EHelper.BackendModel2 -> Maybe (Id ChannelMessageId)
guildChannelGameId backend =
    SeqDict.values (E2EHelper.unwrapBackend backend).guilds
        |> List.concatMap (\guild -> SeqDict.values guild.channels)
        |> List.concatMap (\channel -> SeqDict.keys channel.games)
        |> List.head
