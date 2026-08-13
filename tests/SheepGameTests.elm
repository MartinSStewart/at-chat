module SheepGameTests exposing (tests)

import Array
import Effect.Time as Time
import Expect
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty(..))
import SeqDict
import SheepGame exposing (Action(..), Phase(..))
import String.Nonempty exposing (NonemptyString(..))
import Test exposing (Test)


host : Id UserId
host =
    Id.fromInt 0


playerA : Id UserId
playerA =
    Id.fromInt 1


playerB : Id UserId
playerB =
    Id.fromInt 2


{-| A match with `questionCount` questions, whose wording never matters to these tests.
-}
setup : Int -> SheepGame.ValidatedSetup
setup questionCount =
    { questions =
        Nonempty
            (NonemptyString 'Q' "1")
            (List.range 2 questionCount |> List.map (\index -> NonemptyString 'Q' (String.fromInt index)))
    , createdBy = host
    }


action : Id UserId -> Action -> SheepGame.ActionWithTime
action userId change =
    { userId = userId, time = Time.millisToPosix 0, change = change }


{-| Replay a list of actions the way the backend and every client do.
-}
apply : SheepGame.ValidatedSetup -> List SheepGame.ActionWithTime -> SheepGame.Shared
apply setup2 actions =
    List.foldl (SheepGame.updateAction setup2) SheepGame.initShared actions


answers : List String -> Action
answers list =
    SubmittedAnswers (Array.fromList list)


tests : Test
tests =
    Test.describe "Sheep game"
        [ Test.test "Everyone who wrote the same answer scores the size of their group"
            (\_ ->
                apply (setup 1)
                    [ action host (answers [ "Blue" ])
                    , action playerA (answers [ "blue " ])
                    , action playerB (answers [ "Red" ])
                    , action host LockedAnswers
                    , action host FinishedGrouping
                    , action host (ChangedQuestionsRevealed 1)
                    ]
                    |> SheepGame.scoresThroughQuestion 1
                    |> SeqDict.toList
                    |> List.sortBy (\( userId, _ ) -> Id.toInt userId)
                    |> Expect.equal [ ( host, 2 ), ( playerA, 2 ), ( playerB, 1 ) ]
            )
        , Test.test "Only the questions revealed so far count towards the score"
            (\_ ->
                let
                    shared : SheepGame.Shared
                    shared =
                        apply (setup 2)
                            [ action host (answers [ "Blue", "Dog" ])
                            , action playerA (answers [ "Blue", "Cat" ])
                            , action host LockedAnswers
                            , action host FinishedGrouping
                            ]
                in
                Expect.equal
                    ( [ ( host, 0 ), ( playerA, 0 ) ], [ ( host, 2 ), ( playerA, 2 ) ], [ ( host, 3 ), ( playerA, 3 ) ] )
                    ( scoreList 0 shared, scoreList 1 shared, scoreList 2 shared )
            )
        , Test.test "The host can merge answers that don't match word for word"
            (\_ ->
                let
                    grouped : SheepGame.Shared
                    grouped =
                        apply (setup 1)
                            [ action host (answers [ "a dog" ])
                            , action playerA (answers [ "dogs" ])
                            , action host LockedAnswers

                            -- Auto-grouping can't see that these are the same answer, so the
                            -- host puts them in the same group by hand.
                            , action host (ChangedGroup playerA 0 "a")
                            , action host FinishedGrouping
                            ]
                in
                Expect.equal [ ( host, 2 ), ( playerA, 2 ) ] (scoreList 1 grouped)
            )
        , Test.test "A blank answer scores nothing and keeps the player off the scoreboard"
            (\_ ->
                apply (setup 1)
                    [ action host (answers [ "Blue" ])
                    , action playerA (answers [ "  " ])
                    , action host LockedAnswers
                    , action host FinishedGrouping
                    ]
                    |> scoreList 1
                    |> Expect.equal [ ( host, 1 ) ]
            )
        , Test.test "Only the host can lock the answers"
            (\_ ->
                apply (setup 1) [ action playerA LockedAnswers ]
                    |> .phase
                    |> Expect.equal Answering
            )
        , Test.test "Only the host can move the reveal along"
            (\_ ->
                apply (setup 2)
                    [ action host (answers [ "Blue", "Dog" ])
                    , action host LockedAnswers
                    , action host FinishedGrouping
                    , action playerA (ChangedQuestionsRevealed 2)
                    ]
                    |> .questionsRevealed
                    |> Expect.equal 0
            )
        , Test.test "Answers submitted after the host locked them are ignored"
            (\_ ->
                apply (setup 1)
                    [ action host (answers [ "Blue" ])
                    , action host LockedAnswers
                    , action playerA (answers [ "Blue" ])
                    ]
                    |> .answers
                    |> SeqDict.keys
                    |> Expect.equal [ host ]
            )
        , Test.test "Answers are padded and trimmed to the number of questions the host wrote"
            (\_ ->
                apply (setup 2) [ action host (answers [ " Blue ", "Dog", "Extra" ]) ]
                    |> .answers
                    |> SeqDict.get host
                    |> Maybe.map Array.toList
                    |> Expect.equal (Just [ "Blue", "Dog" ])
            )
        , Test.test "A setup with nothing but blank questions is rejected"
            (\_ ->
                SheepGame.validateSetup host { questions = Array.fromList [ "", "   " ], error = Nothing }
                    |> Expect.err
            )
        , Test.test "Blank questions are dropped from a setup that has real ones too"
            (\_ ->
                SheepGame.validateSetup host { questions = Array.fromList [ "", "Name a colour", " " ], error = Nothing }
                    |> Result.map (\setup2 -> List.Nonempty.length setup2.questions)
                    |> Expect.equal (Ok 1)
            )
        ]


scoreList : Int -> SheepGame.Shared -> List ( Id UserId, Int )
scoreList questionsRevealed shared =
    SheepGame.scoresThroughQuestion questionsRevealed shared
        |> SeqDict.toList
        |> List.sortBy (\( userId, _ ) -> Id.toInt userId)
