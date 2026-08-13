module SheepGame exposing
    ( Action(..)
    , ActionWithTime
    , GameData
    , GameMsg(..)
    , LocalChange(..)
    , Phase(..)
    , SetupModel
    , SetupMsg(..)
    , SetupOrGame(..)
    , Shared
    , ValidatedSetup
    , gameView
    , initGame
    , initSetup
    , initShared
    , scoresThroughQuestion
    , setupView
    , updateAction
    , updateGame
    , updateSetup
    , validateSetup
    )

{-| The Sheep Game: everyone answers the same questions and you score points for every
player who wrote the same answer as you, so the goal is to be as unoriginal as possible.

The host writes the questions while setting the game up, everyone answers them, then the
host groups the answers that count as the same thing (people phrase things differently)
before revealing the questions one at a time.

-}

import Array exposing (Array)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Dict exposing (Dict)
import Effect.Browser.Dom as Dom
import Effect.Time as Time
import Go
import Id exposing (Id, UserId)
import List.Extra
import List.Nonempty exposing (Nonempty)
import MyUi
import SeqDict exposing (SeqDict)
import String.Nonempty exposing (NonemptyString)
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import Ui.Prose
import User exposing (LocalUser)


type alias ValidatedSetup =
    { questions : Nonempty NonemptyString
    , createdBy : Id UserId
    }


{-| Which stage the match has reached. The host drives every transition.
-}
type Phase
    = Answering
    | Grouping
    | Revealing


{-| Answers people wrote, and how the host decided to group them.

`groups` gives each answer a label, and answers sharing a label for a question count as
the same answer when scoring. It's filled in automatically when the host locks the
answers and then corrected by hand, because "a dog" and "dogs" should score together but
no amount of string comparison is going to work that out.

-}
type alias Shared =
    { phase : Phase
    , answers : SeqDict (Id UserId) (Array String)
    , groups : SeqDict ( Id UserId, Int ) String
    , notes : Dict Int String
    , questionsRevealed : Int
    }


type alias SetupModel =
    { questions : Array String
    , error : Maybe String
    }


type SetupMsg
    = TypedQuestion Int String
    | PressedAddQuestion
    | PressedRemoveQuestion Int
    | PressedStartGame
    | PressedCancel


type SetupOrGame
    = Setup SetupModel
    | Game GameData
    | CancelSetup


{-| View state that belongs to one player and never reaches anyone else.
-}
type alias GameData =
    { answerDrafts : Array String }


type GameMsg
    = TypedAnswer Int String
    | PressedSubmitAnswers
    | PressedLockAnswers
    | TypedGroup (Id UserId) Int String
    | TypedNotes Int String
    | PressedRevealScores
    | PressedShowNextQuestion
    | PressedHidePreviousQuestion


type Action
    = SubmittedAnswers (Array String)
    | LockedAnswers
    | ChangedGroup (Id UserId) Int String
    | ChangedNotes Int String
    | FinishedGrouping
    | ChangedQuestionsRevealed Int


type alias ActionWithTime =
    { userId : Id UserId, time : Time.Posix, change : Action }


type LocalChange
    = StartMatch Time.Posix ValidatedSetup
    | Action ActionWithTime


initSetup : SetupModel
initSetup =
    { questions = Array.fromList [ "", "" ], error = Nothing }


{-| Someone opening a match they've already answered gets their own answers back in the
boxes, so that reloading the page and pressing the button again doesn't replace them with
a screen full of blanks.
-}
initGame : Id UserId -> ValidatedSetup -> Shared -> GameData
initGame currentUserId setup shared =
    { answerDrafts =
        case SeqDict.get currentUserId shared.answers of
            Just answers ->
                answers

            Nothing ->
                Array.repeat (List.Nonempty.length setup.questions) ""
    }


initShared : Shared
initShared =
    { phase = Answering
    , answers = SeqDict.empty
    , groups = SeqDict.empty
    , notes = Dict.empty
    , questionsRevealed = 0
    }


maxQuestions : Int
maxQuestions =
    30


maxQuestionLength : Int
maxQuestionLength =
    200


maxAnswerLength : Int
maxAnswerLength =
    100


{-| The host's questions, or a reason they can't be used yet.
-}
validateSetup : Id UserId -> SetupModel -> Result String ValidatedSetup
validateSetup createdBy model =
    case
        Array.toList model.questions
            |> List.filterMap (\question -> String.trim question |> String.Nonempty.fromString)
            |> List.Nonempty.fromList
    of
        Just questions ->
            Ok { questions = questions, createdBy = createdBy }

        Nothing ->
            Err "Write at least one question before starting"


updateSetup : Id UserId -> SetupMsg -> SetupModel -> ( SetupOrGame, Maybe ValidatedSetup )
updateSetup createdBy msg model =
    case msg of
        TypedQuestion index text ->
            ( Setup
                { model
                    | questions = Array.set index (String.left maxQuestionLength text) model.questions
                    , error = Nothing
                }
            , Nothing
            )

        PressedAddQuestion ->
            ( Setup
                { model
                    | questions =
                        if Array.length model.questions >= maxQuestions then
                            model.questions

                        else
                            Array.push "" model.questions
                    , error = Nothing
                }
            , Nothing
            )

        PressedRemoveQuestion index ->
            ( Setup
                { model
                    | questions =
                        Array.toList model.questions
                            |> List.Extra.removeAt index
                            |> Array.fromList
                    , error = Nothing
                }
            , Nothing
            )

        PressedStartGame ->
            case validateSetup createdBy model of
                Ok setup ->
                    ( Game (initGame createdBy setup initShared), Just setup )

                Err error ->
                    ( Setup { model | error = Just error }, Nothing )

        PressedCancel ->
            ( CancelSetup, Nothing )


updateGame :
    ValidatedSetup
    -> Shared
    -> GameMsg
    -> GameData
    -> ( GameData, Maybe Action )
updateGame setup shared msg model =
    case msg of
        TypedAnswer index text ->
            ( { model | answerDrafts = Array.set index (String.left maxAnswerLength text) model.answerDrafts }
            , Nothing
            )

        PressedSubmitAnswers ->
            ( model, Just (SubmittedAnswers model.answerDrafts) )

        PressedLockAnswers ->
            ( model, Just LockedAnswers )

        TypedGroup userId questionIndex group ->
            ( model, Just (ChangedGroup userId questionIndex (String.left 1 group)) )

        TypedNotes questionIndex notes ->
            ( model, Just (ChangedNotes questionIndex (String.left maxAnswerLength notes)) )

        PressedRevealScores ->
            ( model, Just FinishedGrouping )

        PressedShowNextQuestion ->
            ( model
            , min (List.Nonempty.length setup.questions) (shared.questionsRevealed + 1)
                |> ChangedQuestionsRevealed
                |> Just
            )

        PressedHidePreviousQuestion ->
            ( model
            , max 0 (shared.questionsRevealed - 1) |> ChangedQuestionsRevealed |> Just
            )


{-| Everything the host is allowed to do and nobody else is. The backend replays the same
actions through `updateAction`, so a client that sends one of these without being the host
just has it ignored rather than rejected.
-}
isHost : Id UserId -> ValidatedSetup -> Bool
isHost userId setup =
    userId == setup.createdBy


updateAction : ValidatedSetup -> ActionWithTime -> Shared -> Shared
updateAction setup action shared =
    case action.change of
        SubmittedAnswers answers ->
            case shared.phase of
                Answering ->
                    { shared
                        | answers =
                            SeqDict.insert
                                action.userId
                                (padAnswers (List.Nonempty.length setup.questions) answers)
                                shared.answers
                    }

                _ ->
                    shared

        LockedAnswers ->
            case ( shared.phase, isHost action.userId setup ) of
                ( Answering, True ) ->
                    { shared | phase = Grouping, groups = autoGroup setup shared.answers }

                _ ->
                    shared

        ChangedGroup userId questionIndex group ->
            case ( shared.phase, isHost action.userId setup ) of
                ( Grouping, True ) ->
                    { shared | groups = SeqDict.insert ( userId, questionIndex ) group shared.groups }

                _ ->
                    shared

        ChangedNotes questionIndex notes ->
            case ( shared.phase, isHost action.userId setup ) of
                ( Grouping, True ) ->
                    { shared | notes = Dict.insert questionIndex notes shared.notes }

                _ ->
                    shared

        FinishedGrouping ->
            case ( shared.phase, isHost action.userId setup ) of
                ( Grouping, True ) ->
                    { shared | phase = Revealing, questionsRevealed = 0 }

                _ ->
                    shared

        ChangedQuestionsRevealed count ->
            case ( shared.phase, isHost action.userId setup ) of
                ( Revealing, True ) ->
                    { shared
                        | questionsRevealed = clamp 0 (List.Nonempty.length setup.questions) count
                    }

                _ ->
                    shared


{-| Answers arrive from a client that might disagree with us about how many questions
there are, so they're trimmed or padded to fit rather than trusted.
-}
padAnswers : Int -> Array String -> Array String
padAnswers questionCount answers =
    List.range 0 (questionCount - 1)
        |> List.map
            (\index ->
                Array.get index answers |> Maybe.withDefault "" |> String.trim |> String.left maxAnswerLength
            )
        |> Array.fromList


{-| The host's starting point for grouping: answers that already match once case and
surrounding whitespace are ignored get the same label.
-}
autoGroup : ValidatedSetup -> SeqDict (Id UserId) (Array String) -> SeqDict ( Id UserId, Int ) String
autoGroup setup answers =
    List.range 0 (List.Nonempty.length setup.questions - 1)
        |> List.concatMap
            (\questionIndex ->
                SeqDict.toList answers
                    |> List.filterMap
                        (\( userId, userAnswers ) ->
                            case Array.get questionIndex userAnswers of
                                Just answer ->
                                    if String.trim answer == "" then
                                        Nothing

                                    else
                                        Just ( userId, String.toLower (String.trim answer) )

                                Nothing ->
                                    Nothing
                        )
                    |> List.Extra.gatherEqualsBy Tuple.second
                    |> List.indexedMap
                        (\groupIndex ( first, rest ) ->
                            List.map
                                (\( userId, _ ) -> ( ( userId, questionIndex ), groupLabel groupIndex ))
                                (first :: rest)
                        )
                    |> List.concat
            )
        |> SeqDict.fromList


groupLabel : Int -> String
groupLabel index =
    Char.fromCode (Char.toCode 'a' + modBy 26 index) |> String.fromChar


{-| Who wrote an answer to at least one question. Someone who joined the channel but never
answered isn't in the running and shouldn't clutter the scoreboard.
-}
players : Shared -> List (Id UserId)
players shared =
    SeqDict.toList shared.answers
        |> List.filterMap
            (\( userId, answers ) ->
                if List.any (\answer -> String.trim answer /= "") (Array.toList answers) then
                    Just userId

                else
                    Nothing
            )


{-| Scores once `questionCount` questions have been revealed. Each question awards every
player the size of the group their answer landed in, so matching two other people is worth
three points and writing something nobody else thought of is worth one.
-}
scoresThroughQuestion : Int -> Shared -> SeqDict (Id UserId) Int
scoresThroughQuestion questionCount shared =
    List.range 0 (questionCount - 1)
        |> List.foldl
            (\questionIndex scores ->
                List.foldl
                    (\( _, group ) scores2 ->
                        List.foldl
                            (\userId scores3 ->
                                SeqDict.update
                                    userId
                                    (\maybe -> Maybe.withDefault 0 maybe + List.length group |> Just)
                                    scores3
                            )
                            scores2
                            group
                    )
                    scores
                    (groupsForQuestion questionIndex shared)
            )
            (players shared |> List.map (\userId -> ( userId, 0 )) |> SeqDict.fromList)


{-| The players who answered a question, bucketed by the label the host gave their answer.
-}
groupsForQuestion : Int -> Shared -> List ( String, List (Id UserId) )
groupsForQuestion questionIndex shared =
    players shared
        |> List.filterMap
            (\userId ->
                case answerFor userId questionIndex shared of
                    Just _ ->
                        Just
                            ( SeqDict.get ( userId, questionIndex ) shared.groups |> Maybe.withDefault ""
                            , userId
                            )

                    Nothing ->
                        Nothing
            )
        |> List.Extra.gatherEqualsBy Tuple.first
        |> List.map
            (\( ( group, userId ), rest ) -> ( group, userId :: List.map Tuple.second rest ))


answerFor : Id UserId -> Int -> Shared -> Maybe String
answerFor userId questionIndex shared =
    case SeqDict.get userId shared.answers |> Maybe.andThen (Array.get questionIndex) of
        Just answer ->
            if String.trim answer == "" then
                Nothing

            else
                Just answer

        Nothing ->
            Nothing


setupView : Coord CssPixels -> SetupModel -> Element SetupMsg
setupView windowSize model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobileAlt windowSize
    in
    Ui.column
        [ Ui.spacing 16
        , Ui.paddingXY
            (if isMobile then
                8

             else
                16
            )
            16
        , Ui.background MyUi.tabBackground
        ]
        [ Go.setupSection
            (Ui.text "Questions")
            (Just " everyone answers these, so keep them open ended")
            (Ui.column
                [ Ui.spacing 8 ]
                (List.indexedMap
                    (questionInput isMobile)
                    (Array.toList model.questions)
                    ++ [ MyUi.secondaryButton
                            (Dom.id "sheepGame_addQuestion")
                            PressedAddQuestion
                            "Add question"
                       ]
                )
            )
        , case model.error of
            Just error ->
                Ui.el [ Ui.Font.color MyUi.errorColor ] (Ui.text error)

            Nothing ->
                Ui.none
        , Go.startOrCancel "sheepGame" isMobile PressedCancel PressedStartGame
        ]


questionInput : Bool -> Int -> String -> Element SetupMsg
questionInput isMobile index question =
    let
        label : { element : Element SetupMsg, id : Ui.Input.Label }
        label =
            MyUi.label
                (Dom.id ("sheepGame_question_" ++ String.fromInt index))
                []
                (Ui.text ("Question " ++ String.fromInt (index + 1)))
    in
    Ui.row
        [ Ui.spacing 8 ]
        [ Ui.Input.text
            [ Ui.border 1
            , Ui.borderColor MyUi.inputBorder
            , Ui.background MyUi.inputBackground
            , Ui.rounded 4
            , Ui.paddingXY 8 8
            ]
            { onChange = TypedQuestion index
            , text = question
            , placeholder =
                if isMobile then
                    Nothing

                else
                    Just "Name a colour"
            , label = label.id
            }
        , MyUi.secondaryButton
            (Dom.id ("sheepGame_removeQuestion_" ++ String.fromInt index))
            (PressedRemoveQuestion index)
            "Remove"
        ]


gameView : Coord CssPixels -> LocalUser -> ValidatedSetup -> Shared -> GameData -> Element GameMsg
gameView windowSize localUser setup shared model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobileAlt windowSize

        currentUserId : Id UserId
        currentUserId =
            localUser.session.userId
    in
    Ui.column
        [ Ui.spacing 16
        , Ui.paddingXY
            (if isMobile then
                8

             else
                16
            )
            16
        ]
        (case shared.phase of
            Answering ->
                answeringView currentUserId setup shared model

            Grouping ->
                groupingView localUser setup shared

            Revealing ->
                revealingView localUser setup shared
        )


answeringView : Id UserId -> ValidatedSetup -> Shared -> GameData -> List (Element GameMsg)
answeringView currentUserId setup shared model =
    [ Ui.el [ Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Answer like everyone else")
    , Ui.Prose.paragraph
        [ Ui.Font.color MyUi.font3 ]
        [ Ui.text "You score a point for every player who wrote the same answer as you, yourself included." ]
    , Ui.column
        [ Ui.spacing 8 ]
        (List.Nonempty.toList setup.questions
            |> List.indexedMap
                (\index question ->
                    let
                        label : { element : Element GameMsg, id : Ui.Input.Label }
                        label =
                            MyUi.label
                                (Dom.id ("sheepGame_answer_" ++ String.fromInt index))
                                [ Ui.Font.weight 600 ]
                                (Ui.text (String.Nonempty.toString question))
                    in
                    Ui.column
                        [ Ui.spacing 4 ]
                        [ label.element
                        , Ui.Input.text
                            [ Ui.border 1
                            , Ui.borderColor MyUi.inputBorder
                            , Ui.background MyUi.inputBackground
                            , Ui.rounded 4
                            , Ui.paddingXY 8 8
                            ]
                            { onChange = TypedAnswer index
                            , text = Array.get index model.answerDrafts |> Maybe.withDefault ""
                            , placeholder = Nothing
                            , label = label.id
                            }
                        ]
                )
        )
    , Ui.row
        [ Ui.spacing 8 ]
        [ MyUi.simpleButton
            (Dom.id "sheepGame_submitAnswers")
            PressedSubmitAnswers
            (Ui.text
                (if SeqDict.member currentUserId shared.answers then
                    "Update answers"

                 else
                    "Submit answers"
                )
            )
        , if isHost currentUserId setup then
            MyUi.secondaryButton
                (Dom.id "sheepGame_lockAnswers")
                PressedLockAnswers
                "Lock answers and tally score"

          else
            Ui.none
        ]
    , Ui.el
        [ Ui.Font.color MyUi.font3 ]
        (Ui.text (answeredCountText (players shared |> List.length)))
    ]


answeredCountText : Int -> String
answeredCountText count =
    if count == 1 then
        "1 player has answered so far"

    else
        String.fromInt count ++ " players have answered so far"


{-| The host decides which answers count as the same thing. Everyone else waits.
-}
groupingView : LocalUser -> ValidatedSetup -> Shared -> List (Element GameMsg)
groupingView localUser setup shared =
    if isHost localUser.session.userId setup then
        [ Ui.el [ Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Group the answers")
        , Ui.Prose.paragraph
            [ Ui.Font.color MyUi.font3 ]
            [ Ui.text "Answers sharing a letter score together. Change a letter to split an answer off or to merge it with another." ]
        , Ui.column
            [ Ui.spacing 16 ]
            (List.Nonempty.toList setup.questions
                |> List.indexedMap (groupingQuestionView localUser shared)
            )
        , MyUi.simpleButton
            (Dom.id "sheepGame_revealScores")
            PressedRevealScores
            (Ui.text "Reveal scores")
        ]

    else
        [ Ui.el [ Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Answers are locked")
        , Ui.Prose.paragraph
            [ Ui.Font.color MyUi.font3 ]
            [ Ui.text "The host is grouping the answers together. The scores show up here once they're done." ]
        ]


groupingQuestionView : LocalUser -> Shared -> Int -> NonemptyString -> Element GameMsg
groupingQuestionView localUser shared questionIndex question =
    let
        notesLabel : { element : Element GameMsg, id : Ui.Input.Label }
        notesLabel =
            MyUi.label
                (Dom.id ("sheepGame_notes_" ++ String.fromInt questionIndex))
                [ Ui.Font.color MyUi.font3 ]
                (Ui.text "Notes")
    in
    Ui.column
        [ Ui.spacing 8 ]
        [ Ui.el [ Ui.Font.weight 600 ] (Ui.text (String.Nonempty.toString question))
        , Ui.column
            [ Ui.spacing 4 ]
            (players shared
                |> List.filterMap
                    (\userId ->
                        Maybe.map
                            (groupingAnswerView localUser questionIndex userId shared)
                            (answerFor userId questionIndex shared)
                    )
            )
        , Ui.column
            [ Ui.spacing 2 ]
            [ notesLabel.element
            , Ui.Input.text
                [ Ui.border 1
                , Ui.borderColor MyUi.inputBorder
                , Ui.background MyUi.inputBackground
                , Ui.rounded 4
                , Ui.paddingXY 8 8
                ]
                { onChange = TypedNotes questionIndex
                , text = Dict.get questionIndex shared.notes |> Maybe.withDefault ""
                , placeholder = Nothing
                , label = notesLabel.id
                }
            ]
        ]


groupingAnswerView : LocalUser -> Int -> Id UserId -> Shared -> String -> Element GameMsg
groupingAnswerView localUser questionIndex userId shared answer =
    let
        groupLabel2 : { element : Element GameMsg, id : Ui.Input.Label }
        groupLabel2 =
            MyUi.label
                (Dom.id ("sheepGame_group_" ++ String.fromInt questionIndex ++ "_" ++ Id.toString userId))
                []
                (Ui.text "Group")
    in
    Ui.row
        [ Ui.spacing 8 ]
        [ Ui.el [ Ui.width (Ui.px 40) ] groupLabel2.element
        , Ui.el
            [ Ui.width (Ui.px 48) ]
            (Ui.Input.text
                [ Ui.border 1
                , Ui.borderColor MyUi.inputBorder
                , Ui.background MyUi.inputBackground
                , Ui.rounded 4
                , Ui.paddingXY 8 4
                ]
                { onChange = TypedGroup userId questionIndex
                , text = SeqDict.get ( userId, questionIndex ) shared.groups |> Maybe.withDefault ""
                , placeholder = Nothing
                , label = groupLabel2.id
                }
            )
        , Ui.el [ Ui.Font.weight 600 ] (Ui.text (User.toStringAlt userId localUser))
        , Ui.text answer
        ]


revealingView : LocalUser -> ValidatedSetup -> Shared -> List (Element GameMsg)
revealingView localUser setup shared =
    let
        questionCount : Int
        questionCount =
            List.Nonempty.length setup.questions

        scores : SeqDict (Id UserId) Int
        scores =
            scoresThroughQuestion shared.questionsRevealed shared
    in
    [ Ui.el
        [ Ui.Font.bold, Ui.Font.size 20 ]
        (Ui.text
            (if shared.questionsRevealed >= questionCount then
                "Final scores"

             else
                "Scores after "
                    ++ String.fromInt shared.questionsRevealed
                    ++ " of "
                    ++ String.fromInt questionCount
                    ++ " questions"
            )
        )
    , scoreboardView localUser scores
    , if isHost localUser.session.userId setup then
        Ui.row
            [ Ui.spacing 8 ]
            [ MyUi.secondaryButton
                (Dom.id "sheepGame_hidePreviousQuestion")
                PressedHidePreviousQuestion
                "Back"
            , MyUi.simpleButton
                (Dom.id "sheepGame_showNextQuestion")
                PressedShowNextQuestion
                (Ui.text "Show next question")
            ]

      else
        Ui.none
    , Ui.column
        [ Ui.spacing 16 ]
        (List.Nonempty.toList setup.questions
            |> List.take shared.questionsRevealed
            |> List.indexedMap (revealedQuestionView localUser shared)
            |> List.reverse
        )
    ]


scoreboardView : LocalUser -> SeqDict (Id UserId) Int -> Element msg
scoreboardView localUser scores =
    Ui.column
        [ Ui.spacing 4 ]
        (SeqDict.toList scores
            |> List.sortBy (\( _, score ) -> -score)
            |> List.map
                (\( userId, score ) ->
                    Ui.row
                        [ Ui.spacing 8 ]
                        [ Ui.el [ Ui.width (Ui.px 40), Ui.Font.bold ] (Ui.text (String.fromInt score))
                        , Ui.text (User.toStringAlt userId localUser)
                        ]
                )
        )


revealedQuestionView : LocalUser -> Shared -> Int -> NonemptyString -> Element msg
revealedQuestionView localUser shared questionIndex question =
    Ui.column
        [ Ui.spacing 4 ]
        [ Ui.el [ Ui.Font.weight 600 ] (Ui.text (String.Nonempty.toString question))
        , Ui.column
            [ Ui.spacing 2 ]
            (groupsForQuestion questionIndex shared
                |> List.sortBy (\( _, group ) -> -(List.length group))
                |> List.map
                    (\( _, group ) ->
                        Ui.row
                            [ Ui.spacing 8 ]
                            [ Ui.el
                                [ Ui.width (Ui.px 40), Ui.Font.bold ]
                                (Ui.text ("+" ++ String.fromInt (List.length group)))
                            , Ui.text
                                (List.map
                                    (\userId ->
                                        User.toStringAlt userId localUser
                                            ++ ": "
                                            ++ (answerFor userId questionIndex shared |> Maybe.withDefault "")
                                    )
                                    group
                                    |> String.join ", "
                                )
                            ]
                    )
            )
        , case Dict.get questionIndex shared.notes of
            Just notes ->
                if String.trim notes == "" then
                    Ui.none

                else
                    Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text notes)

            Nothing ->
                Ui.none
        ]
