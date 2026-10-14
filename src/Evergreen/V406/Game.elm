module Evergreen.V406.Game exposing (..)

import Array
import Evergreen.V406.Go
import Evergreen.V406.Id
import Evergreen.V406.Message
import Evergreen.V406.SecretId
import Evergreen.V406.SheepGame
import Evergreen.V406.UserSession
import Evergreen.V406.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V406.Go.GameMsg
    | GoSetupMsg Evergreen.V406.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V406.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V406.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V406.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V406.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V406.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V406.Go.ValidatedSetup (Array.Array Evergreen.V406.Go.ActionWithTime) Evergreen.V406.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V406.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V406.WordSpellingGame.ActionWithTime) Evergreen.V406.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V406.SheepGame.ValidatedSetup (Array.Array Evergreen.V406.SheepGame.ActionWithTime) Evergreen.V406.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V406.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V406.Go.ValidatedSetup (Array.Array Evergreen.V406.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V406.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V406.WordSpellingGame.ActionWithTime) Evergreen.V406.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V406.SheepGame.ValidatedSetup (Array.Array Evergreen.V406.SheepGame.ActionWithTime) Evergreen.V406.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.UserSession.ToBeFilledInByBackend (Evergreen.V406.SecretId.SecretId Evergreen.V406.Id.GamePublicId))
    | LoadMatch (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) (Evergreen.V406.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Evergreen.V406.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V406.Go.GameModel
    | WordSpellingGame_Game Evergreen.V406.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V406.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V406.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V406.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V406.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V406.Id.Id Evergreen.V406.Id.ChannelMessageId, Evergreen.V406.SheepGame.Input ) Int
    }
