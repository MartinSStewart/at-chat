module SheepGame exposing
    ( Action(..)
    , ActionWithTime
    , GameData
    , GameMsg(..)
    , LocalChange(..)
    , LoggedIn
    , Phase(..)
    , SetupModel
    , SetupMsg(..)
    , SetupOrGame(..)
    , Shared
    , ValidatedSetup
    , clampSavedQuestions
    , gameView
    , initGame
    , initSetup
    , initSetupFromSavedQuestions
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
import Array.Extra
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import Dict exposing (Dict)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Time as Time
import Go
import Html
import Id exposing (Id, UserId)
import List.Extra
import List.Nonempty exposing (Nonempty)
import MessageInput exposing (TextInputFocus)
import MyUi
import PersonName exposing (PersonName)
import Ports
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import SeqSet
import Sticker
import String.Nonempty
import Ui exposing (Element)
import Ui.Font
import Ui.Input
import Ui.Prose
import User exposing (FrontendUser, LocalUser)


type alias ValidatedSetup =
    { questions : Nonempty (Nonempty (RichText (Id UserId)))
    , createdBy : Id UserId
    }


type alias LoggedIn a =
    { a | typedTextCounter : Int, textInputFocus : Maybe TextInputFocus }


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
    , answers : SeqDict (Id UserId) (Array (Maybe (Nonempty (RichText (Id UserId)))))
    , groups : SeqDict ( Id UserId, Int ) String
    , notes : Dict Int String
    , questionsRevealed : Int
    }


type alias SetupModel =
    { questions : Array String
    , error : Maybe String
    }


type SetupMsg
    = TypedQuestion Int MessageInput.Msg
    | PressedAddQuestion
    | PressedRemoveQuestion Int
    | PressedStartGame
    | PressedCancel
    | SetupNoOp


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
    | NoOp


type Action
    = SubmittedAnswers (Array (Maybe (Nonempty (RichText (Id UserId)))))
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
    { questions = Array.fromList [ "" ], error = Nothing }


{-| The setup someone was part way through, rebuilt from the questions their session held
onto so that a refresh doesn't cost them what they'd written.
-}
initSetupFromSavedQuestions : Array String -> SetupModel
initSetupFromSavedQuestions questions =
    if Array.isEmpty questions then
        initSetup

    else
        { questions = questions, error = Nothing }


{-| How much of what a session asks to save is worth keeping. Nothing stops a client from
sending more than the setup view lets anyone write, and this ends up in the backend's
state, so it gets the same limits here.
-}
clampSavedQuestions : Array String -> Array String
clampSavedQuestions questions =
    Array.slice 0 maxQuestions questions |> Array.map (String.left maxQuestionLength)


{-| Someone opening a match they've already answered gets their own answers back in the
boxes, so that reloading the page and pressing the button again doesn't replace them with
a screen full of blanks. They come back as the text that was typed to produce them, which
is what the boxes take.
-}
initGame : LocalUser -> ValidatedSetup -> Shared -> GameData
initGame localUser setup shared =
    { answerDrafts =
        case SeqDict.get localUser.session.userId shared.answers of
            Just answers ->
                Array.map
                    (\answer ->
                        case answer of
                            Just answer2 ->
                                toSourceText localUser answer2

                            Nothing ->
                                ""
                    )
                    answers

            Nothing ->
                Array.repeat (List.Nonempty.length setup.questions) ""
    }


{-| Everyone whose name a mention could be written with.
-}
allUsers : LocalUser -> SeqDict (Id UserId) FrontendUser
allUsers localUser =
    SeqDict.insert
        localUser.session.userId
        (User.backendToFrontendForUser localUser.user)
        localUser.otherUsers


{-| Turn typed text into a question or answer. Blank text isn't either of those.
-}
parseContent : Time.Zone -> SeqDict (Id UserId) FrontendUser -> String -> Maybe (Nonempty (RichText (Id UserId)))
parseContent timezone users text =
    String.trim text
        |> String.Nonempty.fromString
        |> Maybe.map (RichText.fromNonemptyString timezone users)


{-| The text someone would have typed to write this, so that an answer can be put back in
the box it came from.
-}
toSourceText : LocalUser -> Nonempty (RichText (Id UserId)) -> String
toSourceText localUser content =
    RichText.toString localUser.timezone False (allUsers localUser) content


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
validateSetup : Time.Zone -> SeqDict (Id UserId) FrontendUser -> Id UserId -> SetupModel -> Result String ValidatedSetup
validateSetup timezone users createdBy model =
    case
        Array.toList model.questions
            |> List.filterMap (parseContent timezone users)
            |> List.Nonempty.fromList
    of
        Just questions ->
            Ok { questions = questions, createdBy = createdBy }

        Nothing ->
            Err "Write at least one question before starting"


updateSetup : LocalUser -> SetupMsg -> SetupModel -> ( SetupOrGame, Maybe ValidatedSetup )
updateSetup localUser msg model =
    case msg of
        TypedQuestion index messageInputMsg ->
            case messageInputMsg of
                MessageInput.PressedTextInput ->
                    -- Clicking the input is how the rich text drawn in front of it gets edited, but
                    -- the focus itself is handled by the port that watches the text selection.
                    ( Setup model, Nothing )

                MessageInput.TypedMessage text ->
                    ( Setup
                        { model
                            | questions = Array.set index text model.questions
                            , error = Nothing
                        }
                    , Nothing
                    )

                MessageInput.PressedSendMessage record ->
                    ( Setup model, Nothing )

                MessageInput.TypedArrowInDropdown int ->
                    Debug.todo ""

                MessageInput.TypedArrowUpInEmptyInput ->
                    Debug.todo ""

                MessageInput.PressedDropdownItem int ->
                    Debug.todo ""

                MessageInput.PressedPingDropdownContainer ->
                    Debug.todo ""

                MessageInput.PressedUploadFile ->
                    Debug.todo ""

                MessageInput.PressedOpenEmojiSelector ->
                    Debug.todo ""

                MessageInput.OnPasteFiles nonempty ->
                    Debug.todo ""

                MessageInput.TypedPageUp ->
                    ( Setup model, Nothing )

                MessageInput.TypedPageDown ->
                    ( Setup model, Nothing )

                MessageInput.TypedTabInCodeBlock range ->
                    ( Setup model, Nothing )

                MessageInput.IgnoredKeyPress ->
                    ( Setup model, Nothing )

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
            case validateSetup localUser.timezone (allUsers localUser) localUser.session.userId model of
                Ok setup ->
                    ( Game (initGame localUser setup initShared), Just setup )

                Err error ->
                    ( Setup { model | error = Just error }, Nothing )

        SetupNoOp ->
            ( Setup model, Nothing )

        PressedCancel ->
            ( CancelSetup, Nothing )


updateGame :
    LocalUser
    -> ValidatedSetup
    -> Shared
    -> GameMsg
    -> GameData
    -> ( GameData, Maybe Action )
updateGame localUser setup shared msg model =
    case msg of
        TypedAnswer index text ->
            ( { model | answerDrafts = Array.set index (String.left maxAnswerLength text) model.answerDrafts }
            , Nothing
            )

        PressedSubmitAnswers ->
            ( model
            , Array.map
                (parseContent localUser.timezone (allUsers localUser))
                model.answerDrafts
                |> SubmittedAnswers
                |> Just
            )

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

        NoOp ->
            ( model, Nothing )


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
padAnswers : Int -> Array (Maybe (Nonempty (RichText (Id UserId)))) -> Array (Maybe (Nonempty (RichText (Id UserId))))
padAnswers questionCount answers =
    List.range 0 (questionCount - 1)
        |> List.map (\index -> Array.get index answers |> Maybe.withDefault Nothing)
        |> Array.fromList


{-| What two answers have to share to count as the same answer. Rendering the text with
no timezone and nobody's name keeps this identical everywhere it's worked out, which is
what matters when the backend and every client have to reach the same grouping.
-}
answerKey : Nonempty (RichText (Id UserId)) -> String
answerKey content =
    RichText.toString Time.utc False SeqDict.empty content
        |> String.trim
        |> String.toLower


{-| The host's starting point for grouping: answers that already match once case and
surrounding whitespace are ignored get the same label.
-}
autoGroup : ValidatedSetup -> SeqDict (Id UserId) (Array (Maybe (Nonempty (RichText (Id UserId))))) -> SeqDict ( Id UserId, Int ) String
autoGroup setup answers =
    List.range 0 (List.Nonempty.length setup.questions - 1)
        |> List.concatMap
            (\questionIndex ->
                SeqDict.toList answers
                    |> List.filterMap
                        (\( userId, userAnswers ) ->
                            case Array.get questionIndex userAnswers |> Maybe.withDefault Nothing of
                                Just answer ->
                                    Just ( userId, answerKey answer )

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
                if List.any (\answer -> answer /= Nothing) (Array.toList answers) then
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


answerFor : Id UserId -> Int -> Shared -> Maybe (Nonempty (RichText (Id UserId)))
answerFor userId questionIndex shared =
    SeqDict.get userId shared.answers
        |> Maybe.andThen (Array.get questionIndex)
        |> Maybe.withDefault Nothing


setupView :
    Time.Posix
    -> Coord CssPixels
    -> Bool
    -> LocalUser
    -> LoggedIn a
    -> SeqDict (Id UserId) FrontendUser
    -> SetupModel
    -> Element SetupMsg
setupView time windowSize showMemberTab localUser loggedIn users model =
    let
        isMobile : Bool
        isMobile =
            MyUi.isMobileAlt windowSize

        horizontalPadding : Int
        horizontalPadding =
            if isMobile then
                8

            else
                16

        questionWidth : Int
        questionWidth =
            MyUi.conversationWidthIgnoreScrollbar windowSize showMemberTab - horizontalPadding * 2
    in
    Ui.column
        [ Ui.spacing 16
        , Ui.paddingXY horizontalPadding 16
        , Ui.background MyUi.tabBackground
        ]
        [ Go.setupSection
            (Ui.text "Questions")
            Nothing
            (Ui.column
                [ Ui.spacing 8 ]
                (List.indexedMap
                    (questionInput time questionWidth isMobile localUser loggedIn users)
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


questionInputId : Int -> HtmlId
questionInputId index =
    Dom.id ("sheepGame_question_" ++ String.fromInt index)


questionInput :
    Time.Posix
    -> Int
    -> Bool
    -> LocalUser
    -> LoggedIn a
    -> SeqDict (Id UserId) FrontendUser
    -> Int
    -> String
    -> Element SetupMsg
questionInput time questionWidth isMobile localUser loggedIn users index question =
    let
        htmlId : HtmlId
        htmlId =
            questionInputId index

        isFocused : Bool
        isFocused =
            case loggedIn.textInputFocus of
                Just textInputFocus ->
                    textInputFocus.htmlId == htmlId

                Nothing ->
                    False

        richText : Maybe (Nonempty (RichText (Id UserId)))
        richText =
            String.Nonempty.fromString question |> Maybe.map (RichText.fromNonemptyString localUser.timezone users)
    in
    Ui.row
        [ Ui.spacing 8 ]
        [ Ui.el
            (Ui.heightMax 300 :: MessageInput.containerAttributes True)
            (MessageInput.textarea
                isMobile
                htmlId
                "Pick a random number between 1 and 10"
                (maxQuestionLength - String.length question)
                question
                richText
                SeqDict.empty
                localUser
                loggedIn
                users
                |> Ui.html
                |> Ui.map (TypedQuestion index)
                |> Ui.el
                    [ case ( isFocused, richText ) of
                        ( False, Just content ) ->
                            Ui.inFront (questionPreview time questionWidth localUser index content)

                        _ ->
                            Ui.noAttr
                    ]
            )
            |> Ui.el []
        , MyUi.deleteButton
            (Dom.id ("sheepGame_removeQuestion_" ++ String.fromInt index))
            (PressedRemoveQuestion index)
        ]


{-| A question the host isn't editing right now, drawn the way it will look in the game so
they see the formatting instead of the markdown they typed.

It covers the textarea it's drawn in front of and ignores pointer events, so clicking it
puts the caret in that textarea instead, which swaps this back for the markdown.

-}
questionPreview : Time.Posix -> Int -> LocalUser -> Int -> Nonempty (RichText (Id UserId)) -> Element SetupMsg
questionPreview time questionWidth localUser index content =
    RichText.view
        (Dom.id ("sheepGame_questionPreview_" ++ String.fromInt index))
        questionWidth
        (\_ -> SetupNoOp)
        (\_ -> SetupNoOp)
        (\_ -> SetupNoOp)
        { domainWhitelist = localUser.user.domainWhitelist
        , revealedSpoilers = SeqSet.empty
        , users = allUsers localUser
        , attachedFiles = SeqDict.empty
        , stickers = localUser.stickers
        , customEmojis = localUser.customEmojis
        , animationMode = Sticker.LoopAFewTimesOnLoad
        , timezone = localUser.timezone
        , time = time
        , drawings = SeqDict.empty
        , embedDrawings = SeqDict.empty
        , drawingUserColor = \_ -> ""
        , isSelectingAnchor = False
        , devicePixelRatio = localUser.devicePixelRatio
        , isHovered = False
        }
        Array.empty
        content
        |> Html.div []
        |> Ui.html
        |> Ui.el
            [ Ui.padding 8
            , Ui.background MyUi.background2
            , MyUi.prewrap
            , MyUi.noPointerEvents
            ]


gameView : Time.Posix -> Coord CssPixels -> LocalUser -> ValidatedSetup -> Shared -> GameData -> Element GameMsg
gameView time windowSize localUser setup shared model =
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
        ]
        (case shared.phase of
            Answering ->
                answeringView time localUser setup shared model

            Grouping ->
                groupingView time localUser setup shared

            Revealing ->
                revealingView time localUser setup shared
        )


{-| Questions and answers are drawn the same way a message is, minus the parts a game has
no use for: nothing here has attachments and there's nothing to reveal a spoiler with.
-}
contentView : Time.Posix -> LocalUser -> Nonempty (RichText (Id UserId)) -> Element GameMsg
contentView time localUser content =
    RichText.preview
        (\_ -> NoOp)
        { revealedSpoilers = SeqSet.empty
        , users = allUsers localUser
        , attachedFiles = SeqDict.empty
        , customEmojis = localUser.customEmojis
        , domainWhitelist = localUser.user.domainWhitelist
        , timezone = localUser.timezone
        , time = time
        }
        content
        |> Html.span []
        |> Ui.html


answeringView : Time.Posix -> LocalUser -> ValidatedSetup -> Shared -> GameData -> List (Element GameMsg)
answeringView time localUser setup shared model =
    let
        currentUserId : Id UserId
        currentUserId =
            localUser.session.userId
    in
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
                                [ Ui.Font.color MyUi.font3, Ui.Font.size 14 ]
                                (Ui.text "Your answer")
                    in
                    Ui.column
                        [ Ui.spacing 4 ]
                        [ Ui.el [ Ui.Font.weight 600 ] (contentView time localUser question)
                        , label.element
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
groupingView : Time.Posix -> LocalUser -> ValidatedSetup -> Shared -> List (Element GameMsg)
groupingView time localUser setup shared =
    if isHost localUser.session.userId setup then
        [ Ui.el [ Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Group the answers")
        , Ui.Prose.paragraph
            [ Ui.Font.color MyUi.font3 ]
            [ Ui.text "Answers sharing a letter score together. Change a letter to split an answer off or to merge it with another." ]
        , Ui.column
            [ Ui.spacing 16 ]
            (List.Nonempty.toList setup.questions
                |> List.indexedMap (groupingQuestionView time localUser shared)
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


groupingQuestionView : Time.Posix -> LocalUser -> Shared -> Int -> Nonempty (RichText (Id UserId)) -> Element GameMsg
groupingQuestionView time localUser shared questionIndex question =
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
        [ Ui.el [ Ui.Font.weight 600 ] (contentView time localUser question)
        , Ui.column
            [ Ui.spacing 4 ]
            (players shared
                |> List.filterMap
                    (\userId ->
                        Maybe.map
                            (groupingAnswerView time localUser questionIndex userId shared)
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


groupingAnswerView : Time.Posix -> LocalUser -> Int -> Id UserId -> Shared -> Nonempty (RichText (Id UserId)) -> Element GameMsg
groupingAnswerView time localUser questionIndex userId shared answer =
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
        , contentView time localUser answer
        ]


revealingView : Time.Posix -> LocalUser -> ValidatedSetup -> Shared -> List (Element GameMsg)
revealingView time localUser setup shared =
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
            |> List.indexedMap (revealedQuestionView time localUser shared)
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


revealedQuestionView : Time.Posix -> LocalUser -> Shared -> Int -> Nonempty (RichText (Id UserId)) -> Element GameMsg
revealedQuestionView time localUser shared questionIndex question =
    Ui.column
        [ Ui.spacing 4 ]
        [ Ui.el [ Ui.Font.weight 600 ] (contentView time localUser question)
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
                            , Ui.column
                                [ Ui.spacing 2 ]
                                (List.map
                                    (\userId ->
                                        Ui.row
                                            [ Ui.spacing 4 ]
                                            [ Ui.text (User.toStringAlt userId localUser ++ ":")
                                            , case answerFor userId questionIndex shared of
                                                Just answer ->
                                                    contentView time localUser answer

                                                Nothing ->
                                                    Ui.none
                                            ]
                                    )
                                    group
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
