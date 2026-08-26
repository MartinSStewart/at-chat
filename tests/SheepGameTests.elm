module SheepGameTests exposing (tests)

import Effect.Browser.Dom as Dom
import Effect.Time as Time
import Expect
import FileName
import FileStatus
import Id exposing (Id, UserId)
import IdArray
import List.Nonempty exposing (Nonempty(..))
import RichText
import Scroll exposing (ScrollPosition(..))
import SeqDict exposing (SeqDict)
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


playerC : Id UserId
playerC =
    Id.fromInt 3


{-| Plain text as a question or an answer. Nobody to mention and no timezone to show a
timestamp in, which is all the parsing needs.
-}
content : String -> Nonempty (RichText.RichText (Id UserId))
content text =
    let
        ( first, rest ) =
            String.uncons text |> Maybe.withDefault ( ' ', "" )
    in
    RichText.fromNonemptyString Time.utc SeqDict.empty (NonemptyString first rest)


{-| A question, which unlike an answer can have files attached to it. None of these do.
-}
question : String -> SheepGame.ValidatedInput
question text =
    { text = content text, attachedFiles = SeqDict.empty, reactions = SeqDict.empty }


{-| A match with `questionCount` questions, whose wording never matters to these tests.
-}
setup : Int -> SheepGame.ValidatedSetup
setup questionCount =
    { questions =
        Nonempty
            (question "Q1")
            (List.range 2 questionCount |> List.map (\index -> question ("Q" ++ String.fromInt index)))
    , createdBy = host
    }


{-| One thing someone did. Actions come in lists so that the answers a player wrote, which
save a question at a time, sit in the same list as everything else.
-}
action : Id UserId -> Action -> List SheepGame.ActionWithTime
action userId change =
    [ { userId = userId, time = Time.millisToPosix 0, change = change } ]


{-| Replay a list of actions the way the backend and every client do.
-}
apply : SheepGame.ValidatedSetup -> List (List SheepGame.ActionWithTime) -> SheepGame.Shared
apply setup2 actions =
    List.foldl (SheepGame.updateAction setup2) SheepGame.initShared (List.concat actions)


{-| Everything one player wrote, as the separate actions saving each box produces.
-}
answers : Id UserId -> List String -> List SheepGame.ActionWithTime
answers userId list =
    List.indexedMap
        (\index text ->
            (if String.trim text == "" then
                Nothing

             else
                Just (question (String.trim text))
            )
                |> SubmittedAnswer (Id.fromInt index)
                |> action userId
        )
        list
        |> List.concat


{-| The answers someone submitted, back as plain text.
-}
answerTexts : Id UserId -> SheepGame.Shared -> Maybe (List String)
answerTexts userId shared =
    SeqDict.get userId shared.answers
        |> Maybe.map
            (\array ->
                IdArray.toList array
                    |> List.map
                        (\answer ->
                            case answer of
                                Just answer2 ->
                                    RichText.toString Time.utc False SeqDict.empty answer2.text

                                Nothing ->
                                    ""
                        )
            )


{-| The view state of someone watching the results, scrolled to `scrollPosition` and having
already had `questionsRevealedSeen` questions turn up in front of them.
-}
watching : ScrollPosition -> Int -> SheepGame.GameData
watching scrollPosition questionsRevealedSeen =
    { answerDrafts = IdArray.empty
    , noteDrafts = IdArray.empty
    , gridHovered = Nothing
    , scrollPosition = scrollPosition
    , questionsRevealedSeen = questionsRevealedSeen
    , newQuestionRevealed = False
    , hoveredResult = Nothing
    }


{-| What the reader is told and where they're taken, which is all these tests care about.
-}
revealed : Int -> SheepGame.GameData -> ( Bool, Maybe Dom.HtmlId )
revealed questionsRevealed model =
    SheepGame.questionRevealed questionsRevealed model
        |> Tuple.mapFirst .newQuestionRevealed


tests : Test
tests =
    Test.describe "Sheep game"
        [ Test.test "The first reveal is the scoring explanation rather than a question"
            (\_ ->
                watching ScrolledToBottom 0
                    |> revealed 1
                    |> Expect.equal ( False, Just SheepGame.scoringId )
            )
        , Test.test "A question revealed while the reader is at the bottom of the tab takes them to it"
            (\_ ->
                watching ScrolledToBottom 1
                    |> revealed 2
                    |> Expect.equal ( False, Just (SheepGame.revealedQuestionId 0) )
            )
        , Test.test "A question revealed while the reader is further up the tab is announced instead"
            (\_ ->
                watching ScrolledToMiddle 1
                    |> revealed 2
                    |> Expect.equal ( True, Nothing )
            )
        , Test.test "The host going back to an earlier question isn't a question turning up"
            (\_ ->
                watching ScrolledToMiddle 2
                    |> revealed 1
                    |> Expect.equal ( False, Nothing )
            )
        , Test.test "Everyone who wrote the same answer scores the size of their group"
            (\_ ->
                apply (setup 1)
                    [ answers playerA [ "Blue" ]
                    , answers playerB [ "blue " ]
                    , answers playerC [ "Red" ]
                    , action host LockedAnswers
                    , action host FinishedGrouping
                    , action host (ChangedQuestionsRevealed (Id.fromInt 1))
                    ]
                    |> SheepGame.scoresThroughQuestion 1
                    |> SeqDict.toList
                    |> List.sortBy (\( userId, _ ) -> Id.toInt userId)
                    |> Expect.equal [ ( playerA, 2 ), ( playerB, 2 ), ( playerC, 1 ) ]
            )
        , Test.test "Only the questions revealed so far count towards the score"
            (\_ ->
                let
                    shared : SheepGame.Shared
                    shared =
                        apply (setup 2)
                            [ answers playerA [ "Blue", "Dog" ]
                            , answers playerB [ "Blue", "Cat" ]
                            , action host LockedAnswers
                            , action host FinishedGrouping
                            ]
                in
                Expect.equal
                    ( [ ( playerA, 0 ), ( playerB, 0 ) ]
                    , [ ( playerA, 2 ), ( playerB, 2 ) ]
                    , [ ( playerA, 3 ), ( playerB, 3 ) ]
                    )
                    ( scoreList 0 shared, scoreList 1 shared, scoreList 2 shared )
            )
        , Test.test "The host can merge answers that don't match word for word"
            (\_ ->
                let
                    grouped : SheepGame.Shared
                    grouped =
                        apply (setup 1)
                            [ answers playerA [ "a dog" ]
                            , answers playerB [ "dogs" ]
                            , action host LockedAnswers

                            -- Auto-grouping can't see that these are the same answer, so the
                            -- host puts them in the same group by hand.
                            , action host (ChangedGroup playerB (Id.fromInt 0) "a")
                            , action host FinishedGrouping
                            ]
                in
                Expect.equal [ ( playerA, 2 ), ( playerB, 2 ) ] (scoreList 1 grouped)
            )
        , Test.test "Answers written with formatting group by what they say"
            (\_ ->
                apply (setup 1)
                    [ answers playerA [ "**blue**" ]
                    , answers playerB [ "**Blue**" ]
                    , action host LockedAnswers
                    , action host FinishedGrouping
                    ]
                    |> scoreList 1
                    |> Expect.equal [ ( playerA, 2 ), ( playerB, 2 ) ]
            )
        , Test.test "Formatting is part of the answer, so the host decides whether it matches"
            (\_ ->
                -- Bold and plain are different answers as far as auto-grouping is concerned.
                -- Merging them is exactly what the host's grouping pass is for.
                apply (setup 1)
                    [ answers playerA [ "**blue**" ]
                    , answers playerB [ "blue" ]
                    , action host LockedAnswers
                    , action host FinishedGrouping
                    ]
                    |> scoreList 1
                    |> Expect.equal [ ( playerA, 1 ), ( playerB, 1 ) ]
            )
        , Test.test "A blank answer scores nothing and keeps the player off the scoreboard"
            (\_ ->
                apply (setup 1)
                    [ answers playerA [ "Blue" ]
                    , answers playerB [ "  " ]
                    , action host LockedAnswers
                    , action host FinishedGrouping
                    ]
                    |> scoreList 1
                    |> Expect.equal [ ( playerA, 1 ) ]
            )
        , Test.test "Only the host can lock the answers"
            (\_ ->
                apply (setup 1) [ action playerA LockedAnswers ]
                    |> .phase
                    |> Expect.equal Answering
            )
        , Test.test "Unlocking hands the answers back without losing them"
            (\_ ->
                let
                    unlocked : SheepGame.Shared
                    unlocked =
                        apply (setup 1)
                            [ answers playerA [ "Blue" ]
                            , action host LockedAnswers
                            , action host UnlockedAnswers
                            ]
                in
                Expect.equal ( Answering, [ playerA ] ) ( unlocked.phase, SeqDict.keys unlocked.answers )
            )
        , Test.test "Only the host can unlock the answers"
            (\_ ->
                apply (setup 1)
                    [ action host LockedAnswers
                    , action playerA UnlockedAnswers
                    ]
                    |> .phase
                    |> Expect.equal Grouping
            )
        , Test.test "Only the host can move the reveal along"
            (\_ ->
                apply (setup 2)
                    [ answers playerA [ "Blue", "Dog" ]
                    , action host LockedAnswers
                    , action host FinishedGrouping
                    , action playerB (ChangedQuestionsRevealed (Id.fromInt 2))
                    ]
                    |> .questionsRevealed
                    |> Expect.equal 0
            )
        , Test.test "The host's note on a question is kept as the rich text they wrote"
            (\_ ->
                apply (setup 2)
                    [ answers playerA [ "Blue", "Dog" ]
                    , action host LockedAnswers
                    , action host (ChangedNotes (Id.fromInt 0) (Just (question "Nobody said **green**")))
                    ]
                    |> .notes
                    |> SeqDict.get (Id.fromInt 0)
                    |> Maybe.andThen (Maybe.map (\notes -> RichText.toString Time.utc False SeqDict.empty notes.text))
                    |> Expect.equal (Just "Nobody said **green**")
            )
        , Test.test "Only the host can write notes"
            (\_ ->
                apply (setup 2)
                    [ answers playerA [ "Blue", "Dog" ]
                    , action host LockedAnswers
                    , action playerA (ChangedNotes (Id.fromInt 0) (Just (question "Mine now")))
                    ]
                    |> .notes
                    |> Expect.equal SeqDict.empty
            )
        , Test.test "A note the host was still typing when they pressed reveal still counts"
            (\_ ->
                apply (setup 2)
                    [ answers playerA [ "Blue", "Dog" ]
                    , action host LockedAnswers
                    , action host FinishedGrouping
                    , action host (ChangedNotes (Id.fromInt 0) (Just (question "Only just made it")))
                    ]
                    |> SheepGame.resultsData (setup 2)
                    |> .questions
                    |> List.map (\result -> Maybe.map (\notes -> RichText.toString Time.utc False SeqDict.empty notes.text) result.notes)
                    |> Expect.equal [ Just "Only just made it", Nothing ]
            )
        , Test.test "Answers submitted after the host locked them are ignored"
            (\_ ->
                apply (setup 1)
                    [ answers playerA [ "Blue" ]
                    , action host LockedAnswers
                    , answers playerB [ "Blue" ]
                    ]
                    |> .answers
                    |> SeqDict.keys
                    |> Expect.equal [ playerA ]
            )
        , Test.test "Answers are fitted to the number of questions the host wrote"
            (\_ ->
                apply (setup 2) [ answers playerA [ " Blue ", "Dog", "Extra" ] ]
                    |> answerTexts playerA
                    |> Expect.equal (Just [ "Blue", "Dog" ])
            )
        , Test.test "Each box saves on its own, so writing one answer doesn't blank the rest"
            (\_ ->
                apply (setup 3)
                    [ answers playerA [ "Blue" ]
                    , action playerA (SubmittedAnswer (Id.fromInt 2) (Just (question "Apple")))
                    ]
                    |> answerTexts playerA
                    |> Expect.equal (Just [ "Blue", "", "Apple" ])
            )
        , Test.test "Emptying a box that was saved takes that answer back off again"
            (\_ ->
                apply (setup 2)
                    [ answers playerA [ "Blue", "Dog" ]
                    , action playerA (SubmittedAnswer (Id.fromInt 0) Nothing)
                    ]
                    |> answerTexts playerA
                    |> Expect.equal (Just [ "", "Dog" ])
            )
        , Test.test "A setup with nothing but blank questions is rejected"
            (\_ ->
                SheepGame.validateSetup Time.utc SeqDict.empty host (setupModel [ "", "   " ])
                    |> Expect.err
            )
        , Test.test "A blank question stops a setup that has real ones too from starting"
            (\_ ->
                SheepGame.validateSetup Time.utc SeqDict.empty host (setupModel [ "", "Name a colour", " " ])
                    |> Expect.err
            )
        , Test.test "A setup where every question was written can start"
            (\_ ->
                SheepGame.validateSetup Time.utc SeqDict.empty host (setupModel [ "Name a colour", "Name an animal" ])
                    |> Result.map (\setup2 -> List.Nonempty.length setup2.questions)
                    |> Expect.equal (Ok 2)
            )
        , Test.test "A match can't start while a file the questions refer to is still uploading"
            (\_ ->
                SheepGame.validateSetup
                    Time.utc
                    SeqDict.empty
                    host
                    (setupModelWithFiles
                        (SeqDict.singleton
                            (Id.fromInt 1)
                            (FileStatus.FileUploading
                                (FileName.fromString "sheep.png")
                                { sent = 0, size = 10 }
                                FileStatus.pngContent
                                FileStatus.IsNotEncrypted
                            )
                        )
                    )
                    |> Expect.err
            )
        , Test.test "Files that finished uploading are carried into the match"
            (\_ ->
                SheepGame.validateSetup
                    Time.utc
                    SeqDict.empty
                    host
                    (setupModelWithFiles
                        (SeqDict.singleton (Id.fromInt 1) (FileStatus.FileUploaded uploadedFile))
                    )
                    |> Result.map
                        (\setup2 ->
                            List.Nonempty.head setup2.questions |> .attachedFiles |> SeqDict.toList
                        )
                    |> Expect.equal (Ok [ ( Id.fromInt 1, uploadedFile ) ])
            )
        , attachedFileTests
        , resultsTests
        ]


{-| Three players, where the second question moves two of them past each other.

    Q1  playerA "Blue"  playerB "Red"  playerC "Red"   ->  1, 2, 2
    Q2  playerA "Dog"   playerB "Dog"  playerC "Cat"   ->  3, 4, 3

-}
resultsTests : Test
resultsTests =
    let
        results : { maxPoints : Int, questions : List SheepGame.QuestionResult, winners : List (Id UserId) }
        results =
            apply (setup 2)
                [ answers playerA [ "Blue", "Dog" ]
                , answers playerB [ "Red", "Dog" ]
                , answers playerC [ "Red", "Cat" ]
                , action host LockedAnswers
                , action host FinishedGrouping
                ]
                |> SheepGame.resultsData (setup 2)

        rankChanges : Int -> List ( Id UserId, SheepGame.RankChange )
        rankChanges questionIndex =
            case List.drop questionIndex results.questions |> List.head of
                Just result ->
                    List.map (\answer -> ( answer.userId, answer.rankChange )) result.answers

                Nothing ->
                    []
    in
    Test.describe "Results"
        [ Test.test "The winner is whoever ends on the most points"
            (\_ ->
                Expect.equal ( 4, [ playerB ] ) ( results.maxPoints, results.winners )
            )
        , Test.test "Scores are the running total as each question is revealed"
            (\_ ->
                List.map (\result -> List.map .score result.answers) results.questions
                    |> Expect.equal [ [ 1, 2, 2 ], [ 3, 4, 3 ] ]
            )
        , Test.test "Nobody has moved anywhere on the first question"
            (\_ ->
                rankChanges 0
                    |> Expect.equal
                        [ ( playerA, SheepGame.RankUnchanged )
                        , ( playerB, SheepGame.RankUnchanged )
                        , ( playerC, SheepGame.RankUnchanged )
                        ]
            )
        , Test.test "Passing someone counts as moving up, and being passed as moving down"
            (\_ ->
                rankChanges 1
                    |> Expect.equal
                        [ ( playerA, SheepGame.RankUp )
                        , ( playerB, SheepGame.RankUnchanged )
                        , ( playerC, SheepGame.RankDown )
                        ]
            )
        ]


attachedFileTests : Test
attachedFileTests =
    Test.describe "Attached files"
        [ Test.test "Deleting a file takes the reference to it out of the question"
            (\_ ->
                SheepGame.removeAttachedFileFromText Time.utc SeqDict.empty (Id.fromInt 1) "Name a colour [!1] [!2]"
                    |> Expect.equal "Name a colour  [!2]"
            )
        , Test.test "A question that was nothing but the file it referred to is left empty"
            (\_ ->
                SheepGame.removeAttachedFileFromText Time.utc SeqDict.empty (Id.fromInt 1) "[!1]"
                    |> Expect.equal ""
            )
        , Test.test "A file another question refers to is left alone"
            (\_ ->
                SheepGame.removeAttachedFileFromText Time.utc SeqDict.empty (Id.fromInt 3) "Name a colour [!1]"
                    |> Expect.equal "Name a colour [!1]"
            )
        , Test.test "Marking a file as a spoiler and back leaves the question as it was"
            (\_ ->
                let
                    spoilered : String
                    spoilered =
                        SheepGame.mapQuestionRichText
                            Time.utc
                            SeqDict.empty
                            (RichText.spoilerAttachedFile (Id.fromInt 1))
                            "Name a colour [!1]"
                in
                ( spoilered
                , SheepGame.mapQuestionRichText
                    Time.utc
                    SeqDict.empty
                    (RichText.unspoilerAttachedFile (Id.fromInt 1))
                    spoilered
                )
                    |> Expect.equal ( "Name a colour ||[!1]||", "Name a colour [!1]" )
            )
        ]


{-| A setup the host has typed questions into and attached nothing to.
-}
setupModel : List String -> SheepGame.SetupModel
setupModel questions =
    { questions =
        List.map (\text -> { text = text, attachedFiles = SeqDict.empty }) questions
            |> IdArray.fromList
    , error = Nothing
    , pressedSubmit = False
    }


{-| A setup with a single question that has files attached to it.
-}
setupModelWithFiles : SeqDict (Id FileStatus.FileId) FileStatus.FileStatus -> SheepGame.SetupModel
setupModelWithFiles attachedFiles =
    { questions = IdArray.fromList [ { text = "Name a colour", attachedFiles = attachedFiles } ]
    , error = Nothing
    , pressedSubmit = False
    }


uploadedFile : FileStatus.FileData
uploadedFile =
    { fileName = FileName.fromString "sheep.png"
    , fileSize = 10
    , metadata = Nothing
    , contentType = FileStatus.pngContent
    , fileHash = FileStatus.fileHash "abc"
    , isEncrypted = FileStatus.IsNotEncrypted
    }


scoreList : Int -> SheepGame.Shared -> List ( Id UserId, Int )
scoreList questionsRevealed shared =
    SheepGame.scoresThroughQuestion questionsRevealed shared
        |> SeqDict.toList
        |> List.sortBy (\( userId, _ ) -> Id.toInt userId)
