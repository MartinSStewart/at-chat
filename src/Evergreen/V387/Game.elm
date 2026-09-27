module Evergreen.V387.Game exposing (..)

import Array
import Evergreen.V387.Go
import Evergreen.V387.Id
import Evergreen.V387.Message
import Evergreen.V387.SecretId
import Evergreen.V387.SheepGame
import Evergreen.V387.UserSession
import Evergreen.V387.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V387.Go.GameMsg
    | GoSetupMsg Evergreen.V387.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V387.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V387.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V387.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V387.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V387.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V387.Go.ValidatedSetup (Array.Array Evergreen.V387.Go.ActionWithTime) Evergreen.V387.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V387.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V387.WordSpellingGame.ActionWithTime) Evergreen.V387.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V387.SheepGame.ValidatedSetup (Array.Array Evergreen.V387.SheepGame.ActionWithTime) Evergreen.V387.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V387.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V387.Go.ValidatedSetup (Array.Array Evergreen.V387.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V387.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V387.WordSpellingGame.ActionWithTime) Evergreen.V387.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V387.SheepGame.ValidatedSetup (Array.Array Evergreen.V387.SheepGame.ActionWithTime) Evergreen.V387.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.UserSession.ToBeFilledInByBackend (Evergreen.V387.SecretId.SecretId Evergreen.V387.Id.GamePublicId))
    | LoadMatch (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) (Evergreen.V387.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Evergreen.V387.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V387.Go.GameModel
    | WordSpellingGame_Game Evergreen.V387.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V387.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V387.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V387.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V387.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V387.Id.Id Evergreen.V387.Id.ChannelMessageId, Evergreen.V387.SheepGame.Input ) Int
    }
