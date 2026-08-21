module E2ESheepGame exposing (tests)

import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Expect
import Html.Attributes
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
                        , user.click 100 (Dom.id "sheepGame_submitAnswers")
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "1 player has answered so far" ])

                        -- Opening the match fresh puts the answers already submitted back in
                        -- the boxes, so pressing the button again can't blank them out.
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
                            (Test.Html.Query.has
                                [ Test.Html.Selector.text "And the winner is"
                                , Test.Html.Selector.text "Which players think most alike"
                                ]
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
