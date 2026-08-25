module E2ESheepGame exposing (imageInQuestionOpensImageViewerTest, tests)

import Coord
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Expect
import FileStatus
import Html.Attributes
import Id exposing (ChannelMessageId, Id)
import Json.Encode
import SeqDict
import SheepGame
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
        , mobileHostMatchTest normalConfig
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

                        -- How the scoring works comes up on its own, before any of the
                        -- answers are given away.
                        , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "Scoring" ])
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "colour" ])
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
                , admin.input 100 (Dom.id "sheepGame_question_0") "Name\na\ncolour"
                , admin.input 100 (Dom.id "sheepGame_question_1") "Name an _animal_"
                , admin.click 100 (Dom.id "sheepGame_addQuestion")
                , admin.input 100 (Dom.id "sheepGame_question_2") "Name a fruit 🥝"
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
                                , stevie.input 100 (Dom.id "sheepGame_answer_2") "Apple\n\nline break"

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
                                , joe.snapshotView 100 { name = "Sheep game answers on desktop" }
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

                                -- The scoring explanation is the first thing revealed, on its own.
                                , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                                , wanda.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "Scoring" ])
                                , wanda.checkView
                                    100
                                    (Test.Html.Query.hasNot [ Test.Html.Selector.text "Name\na\ncolour" ])

                                -- Everyone scores the size of the group their answer landed in, so the first
                                -- question leaves Stevie and Joe on 2 apiece and Wanda on 1. Nobody has
                                -- passed anyone yet, so no arrows are drawn.
                                , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                                , wanda.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "Name\na\ncolour"
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

                                -- An answer can be reacted to the way a message can: the menu
                                -- comes up while the pointer is over it, and the reaction is
                                -- drawn underneath the answer afterwards for everyone
                                , stevie.mouseEnter
                                    100
                                    (SheepGame.reactionTargetId
                                        -- Joe is the third of the four to sign up, so his
                                        -- answer to the first question is this one
                                        (SheepGame.AnswerReaction (Id.fromInt 2) (Id.fromInt 0))
                                    )
                                    ( 10, 10 )
                                    []
                                , stevie.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.id "miniView_emojiReact_0" ])
                                , stevie.checkView
                                    100
                                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "miniView_reply" ])
                                , stevie.click 100 (Dom.id "miniView_emojiReact_0")
                                , stevie.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.id "guild_removeReactionEmoji_0" ])
                                , joe.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.id "guild_addReactionEmoji" ])

                                -- The notes the host wrote about the question take reactions too
                                , stevie.mouseEnter
                                    100
                                    (SheepGame.reactionTargetId (SheepGame.NotesReaction (Id.fromInt 0)))
                                    ( 10, 10 )
                                    []
                                , stevie.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.id "miniView_showReactionEmojiSelector" ])

                                -- Joe reads back over the first question instead of waiting at the
                                -- bottom, so the next one to turn up is announced to him rather than
                                -- scrolled onto, which would move what he's reading out from under him.
                                , scrollTabBodyToMiddle joe

                                -- Dog is worth two points to Joe and Wanda while Cat is worth one to Stevie,
                                -- which puts Joe past Stevie: one arrow up and one arrow down.
                                , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                                , joe.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.exactText "New question revealed!" ])

                                -- Stevie stayed at the bottom, so the question is already in front of
                                -- him and there's nothing to announce
                                , stevie.checkView
                                    100
                                    (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "New question revealed!" ])

                                -- Pressing it takes Joe down to the question, so it has nothing left to say
                                , joe.click 100 (Dom.id "sheepGame_newQuestionRevealed")
                                , joe.checkView
                                    100
                                    (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "New question revealed!" ])
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
                                        [ Test.Html.Selector.exactText "4"
                                        , Test.Html.Selector.exactText "5"
                                        , Test.Html.Selector.exactText "3"
                                        ]
                                    )
                                , wanda.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "7" ])

                                -- And with three players there are pairs to compare, so the grid turns up
                                -- alongside the winner.
                                , joe.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "And the winner is"
                                        , Test.Html.Selector.text "Which players think most alike"
                                        , Test.Html.Selector.text "Move your cursor over a grid square"
                                        ]
                                    )
                                , wanda.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "And the winner is"
                                        , Test.Html.Selector.text "Which players think most alike"
                                        ]
                                    )
                                , E2EHelper.tallSnapshot joe 100 { name = "Sheep game results on desktop" }
                                , wanda.snapshotView 100 { name = "Sheep game results on mobile" }
                                ]

                            Nothing ->
                                [ T.checkState 0 (\_ -> Err "Expected a sheep game in the guild channel") ]
                    )
                ]
            )
        ]


{-| The same match again, only this time it's the host who's on a phone. They write the
questions, lock the answers, group them by hand and step the reveal from there, so every
screen only the host ever sees gets rendered at a mobile size.
-}
mobileHostMatchTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
mobileHostMatchTest normalConfig =
    E2EHelper.startTest
        "A sheep game host runs a three player match from a phone"
        E2EHelper.startTime
        normalConfig
        [ E2EHelper.connectFourUsersAndJoinNewGuild
            E2EHelper.tallDesktopWindow
            (\admin stevie joe wanda ->
                [ -- Everything the host does from here on happens at phone size, while the
                  -- three playing along stay on desktop.
                  admin.resizeWindow 0 E2EHelper.iphone14Window
                , admin.click 100 (Dom.id "guild_openGamesTab")
                , admin.click 100 (Dom.id "game_select_Sheep Game (WIP)")

                -- The setup opens with room for two questions, which is as many as this
                -- match needs.
                , admin.input 100 (Dom.id "sheepGame_question_0") "Name a **drink**"
                , admin.input 100 (Dom.id "sheepGame_question_1") "Name a country"
                , admin.snapshotView 100 { name = "Sheep game setup on mobile" }
                , admin.click 100 (Dom.id "sheepGame_start")
                , T.andThen
                    100
                    (\state ->
                        case guildChannelGameId state.backend of
                            Just messageId ->
                                [ stevie.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString messageId))
                                , joe.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString messageId))
                                , wanda.click 100 (Dom.id ("guild_gameStartedCard_" ++ Id.toString messageId))

                                -- Tea and Cuppa are the same drink written two ways, which is
                                -- the sort of thing the host has to sort out by hand later.
                                , stevie.input 100 (Dom.id "sheepGame_answer_0") "Tea"
                                , stevie.input 100 (Dom.id "sheepGame_answer_1") "Japan"
                                , joe.input 100 (Dom.id "sheepGame_answer_0") "Cuppa"
                                , joe.input 100 (Dom.id "sheepGame_answer_1") "Japan"
                                , wanda.input 100 (Dom.id "sheepGame_answer_0") "Coffee"
                                , wanda.input 100 (Dom.id "sheepGame_answer_1") "Brazil"

                                -- Answers save themselves a moment after the typing stops, so
                                -- this waits that out rather than pressing anything.
                                , admin.checkView
                                    2000
                                    (Test.Html.Query.has [ Test.Html.Selector.text "3 players have answered so far" ])
                                , admin.snapshotView 100 { name = "Sheep game waiting on answers on mobile" }
                                , admin.click 100 (Dom.id "sheepGame_lockAnswers")

                                -- Grouping is the host's alone, so this view has only ever been
                                -- seen on desktop until now. A group is one letter, and putting
                                -- Stevie and Joe on the same one makes their two drinks count as
                                -- the same answer. The three who answered are the second, third
                                -- and fourth to sign up, which makes Stevie 2 and Joe 3.
                                , admin.snapshotView 100 { name = "Sheep game grouping on mobile" }
                                , admin.input 100 (Dom.id "sheepGame_group_0_2") "a"
                                , admin.input 100 (Dom.id "sheepGame_group_0_3") "a"
                                , admin.input 100 (Dom.id "sheepGame_notes_0") "Nobody said **water**"

                                -- Notes save on the same delay the answers did.
                                , admin.checkView
                                    2000
                                    (Test.Html.Query.has [ Test.Html.Selector.id "sheepGame_revealScores" ])
                                , admin.click 100 (Dom.id "sheepGame_revealScores")

                                -- How the scoring works is revealed on its own first, without
                                -- giving away any of the questions.
                                , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Scoring" ])
                                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "drink" ])

                                -- Grouped together, Tea and Cuppa are worth two apiece while
                                -- Wanda's Coffee is worth the one for matching herself.
                                , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "drink"
                                        , Test.Html.Selector.text "Nobody said"
                                        ]
                                    )
                                , stevie.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "Tea"
                                        , Test.Html.Selector.text "Cuppa"
                                        ]
                                    )
                                , admin.snapshotView 100 { name = "Sheep game first question revealed on mobile" }

                                -- Japan carries Stevie and Joe to 4 while Brazil leaves Wanda on
                                -- 2. Without the grouping the first question would have been
                                -- worth one apiece and they'd be finishing on 3.
                                , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "And the winner is"
                                        , Test.Html.Selector.exactText "4"
                                        , Test.Html.Selector.exactText "2"
                                        ]
                                    )
                                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "3" ])
                                , E2EHelper.tallSnapshot admin 100 { name = "Sheep game results on mobile as the host" }
                                ]

                            Nothing ->
                                [ T.checkState 0 (\_ -> Err "Expected a sheep game in the guild channel") ]
                    )
                ]
            )
        ]


{-| Nothing on screen has a size in these tests, so how far the tab body is scrolled is fed
in as the numbers a real scroll event would carry.
-}
scrollTabBodyToMiddle :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
scrollTabBodyToMiddle user =
    user.custom
        100
        SheepGame.gameViewId
        "scroll"
        (Json.Encode.object
            [ ( "target"
              , Json.Encode.object
                    [ ( "scrollTop", Json.Encode.float 1000 )
                    , ( "scrollHeight", Json.Encode.float 2000 )
                    , ( "clientHeight", Json.Encode.float 500 )
                    ]
              )
            ]
        )


{-| A file attached to a question is drawn as the image it is, and pressing it opens the
image viewer the same way pressing one in a message does.
-}
imageInQuestionOpensImageViewerTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
imageInQuestionOpensImageViewerTest imageUploadConfig =
    E2EHelper.startTest
        "An image attached to a sheep game question opens in the image viewer"
        E2EHelper.startTime
        imageUploadConfig
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.tallDesktopWindow
            (\admin _ ->
                [ admin.click 100 (Dom.id "guild_openGamesTab")
                , admin.click 100 (Dom.id "game_select_Sheep Game (WIP)")
                , admin.input 100 (Dom.id "sheepGame_question_0") "What is this a picture of?"

                -- Attaching a file to the question puts a reference to it at the end of what
                -- the host wrote, which is what draws it as an image
                , admin.click 100 (Dom.id "sheepGame_question_0_uploadFile")
                , T.backendUpdate
                    100
                    (Types.Rpc_GotFileUpload (FileStatus.fileHash "123123123") 1234 (Just (Coord.xy 128 128)))
                , admin.click 100 (Dom.id "sheepGame_start")

                -- Nobody has to answer for the host to reveal, and the first reveal is the
                -- scoring explanation, so the question needs a second one
                , admin.click 100 (Dom.id "sheepGame_lockAnswers")
                , admin.click 100 (Dom.id "sheepGame_revealScores")
                , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                , admin.click 100 (Dom.id "sheepGame_showNextQuestion")
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "imageViewer_overlay" ])
                , admin.click 100 (Dom.id "sheepGame_revealedQuestion_0_image_1")
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.id "imageViewer_overlay" ])
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
