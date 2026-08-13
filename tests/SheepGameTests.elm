module SheepGameTests exposing (tests)

import Array
import Effect.Time as Time
import Expect
import Id exposing (Id, UserId)
import List.Nonempty exposing (Nonempty(..))
import RichText
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


{-| Plain text as a question or an answer. Nobody to mention and no timezone to show a
timestamp in, which is all the parsing needs.
-}
content : String -> SheepGame.Content
content text =
    let
        ( first, rest ) =
            String.uncons text |> Maybe.withDefault ( ' ', "" )
    in
    RichText.fromNonemptyString Time.utc SeqDict.empty (NonemptyString first rest)


{-| A match with `questionCount` questions, whose wording never matters to these tests.
-}
setup : Int -> SheepGame.ValidatedSetup
setup questionCount =
    { questions =
        Nonempty
            (content "Q1")
            (List.range 2 questionCount |> List.map (\index -> content ("Q" ++ String.fromInt index)))
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
    List.map
        (\text ->
            if String.trim text == "" then
                Nothing

            else
                Just (content (String.trim text))
        )
        list
        |> Array.fromList
        |> SubmittedAnswers


{-| The answers someone submitted, back as plain text.
-}
answerTexts : Id UserId -> SheepGame.Shared -> Maybe (List String)
answerTexts userId shared =
    SeqDict.get userId shared.answers
        |> Maybe.map
            (\array ->
                Array.toList array
                    |> List.map
                        (\answer ->
                            case answer of
                                Just answer2 ->
                                    RichText.toString Time.utc False SeqDict.empty answer2

                                Nothing ->
                                    ""
                        )
            )


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
        , Test.test "Answers written with formatting group by what they say"
            (\_ ->
                apply (setup 1)
                    [ action host (answers [ "**blue**" ])
                    , action playerA (answers [ "**Blue**" ])
                    , action host LockedAnswers
                    , action host FinishedGrouping
                    ]
                    |> scoreList 1
                    |> Expect.equal [ ( host, 2 ), ( playerA, 2 ) ]
            )
        , Test.test "Formatting is part of the answer, so the host decides whether it matches"
            (\_ ->
                -- Bold and plain are different answers as far as auto-grouping is concerned.
                -- Merging them is exactly what the host's grouping pass is for.
                apply (setup 1)
                    [ action host (answers [ "**blue**" ])
                    , action playerA (answers [ "blue" ])
                    , action host LockedAnswers
                    , action host FinishedGrouping
                    ]
                    |> scoreList 1
                    |> Expect.equal [ ( host, 1 ), ( playerA, 1 ) ]
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
                    |> answerTexts host
                    |> Expect.equal (Just [ "Blue", "Dog" ])
            )
        , Test.test "A setup with nothing but blank questions is rejected"
            (\_ ->
                SheepGame.validateSetup Time.utc SeqDict.empty host { questions = Array.fromList [ "", "   " ], error = Nothing }
                    |> Expect.err
            )
        , Test.test "Blank questions are dropped from a setup that has real ones too"
            (\_ ->
                SheepGame.validateSetup Time.utc SeqDict.empty host { questions = Array.fromList [ "", "Name a colour", " " ], error = Nothing }
                    |> Result.map (\setup2 -> List.Nonempty.length setup2.questions)
                    |> Expect.equal (Ok 1)
            )
        ]


scoreList : Int -> SheepGame.Shared -> List ( Id UserId, Int )
scoreList questionsRevealed shared =
    SheepGame.scoresThroughQuestion questionsRevealed shared
        |> SeqDict.toList
        |> List.sortBy (\( userId, _ ) -> Id.toInt userId)
