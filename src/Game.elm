module Game exposing (..)

import Array exposing (Array)
import Go
import Id exposing (ChannelMessageId, GamePublicId, Id, UserId)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import WordSpellingGame


type BackendGameData
    = GameData_Go Go.ValidatedSetup (Array Go.ActionWithTime)
    | GameData_WordSpellingGame WordSpellingGame.ValidatedSetup (Array WordSpellingGame.ActionWithTime)


type FrontendGameData
    = FrontendGameData_Go Go.ValidatedSetup (Array Go.ActionWithTime) Go.GameState
    | FrontendGameData_WordSpellingGame WordSpellingGame.ValidatedSetup (Array WordSpellingGame.ActionWithTime) WordSpellingGame.GameState


{-| OpaqueVariants
-}
type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (SecretId GamePublicId)
        }


addPublicLink : SecretId GamePublicId -> MatchData -> MatchData
addPublicLink publicLink (MatchData match) =
    { match | publicLink = Just publicLink } |> MatchData


initMatchData : BackendGameData -> Maybe (SecretId GamePublicId) -> MatchData
initMatchData gameData publicLink =
    { data =
        case gameData of
            GameData_Go setup actions ->
                FrontendGameData_Go setup actions (Go.foldActions setup actions)

            GameData_WordSpellingGame setup actions ->
                FrontendGameData_WordSpellingGame setup actions (WordSpellingGame.foldActions setup actions)
    , publicLink = publicLink
    }
        |> MatchData


addGoAction : Go.ActionWithTime -> MatchData -> MatchData
addGoAction action (MatchData match) =
    { match
        | data =
            case match.data of
                FrontendGameData_Go setup actions cache ->
                    FrontendGameData_Go setup (Array.push action actions) (Go.updateAction setup action cache)

                FrontendGameData_WordSpellingGame setup actions cache ->
                    match.data

        --FrontendGameData_WordSpellingGame setup (Array.push action actions) (WordSpellingGame.updateAction setup action cache)
    }
        |> MatchData


hasPendingTurn : Id UserId -> SeqDict (Id ChannelMessageId) MatchData -> SeqSet (Id ChannelMessageId)
hasPendingTurn userId matches =
    SeqDict.foldl
        (\matchId (MatchData match) set ->
            case match.data of
                FrontendGameData_Go setup actions cache ->
                    case cache.phase of
                        Go.Scored _ ->
                            set

                        _ ->
                            if Go.isLocalUsersTurn userId setup cache then
                                SeqSet.insert matchId set

                            else
                                set

                FrontendGameData_WordSpellingGame setup array gameState ->
                    Debug.todo ""
        )
        SeqSet.empty
        matches
