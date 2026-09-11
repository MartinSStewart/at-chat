module Evergreen.V377.Game exposing (..)

import Array
import Evergreen.V377.Go
import Evergreen.V377.Id
import Evergreen.V377.Message
import Evergreen.V377.SecretId
import Evergreen.V377.SheepGame
import Evergreen.V377.UserSession
import Evergreen.V377.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V377.Go.GameMsg
    | GoSetupMsg Evergreen.V377.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V377.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V377.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V377.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V377.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V377.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V377.Go.ValidatedSetup (Array.Array Evergreen.V377.Go.ActionWithTime) Evergreen.V377.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V377.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V377.WordSpellingGame.ActionWithTime) Evergreen.V377.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V377.SheepGame.ValidatedSetup (Array.Array Evergreen.V377.SheepGame.ActionWithTime) Evergreen.V377.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V377.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V377.Go.ValidatedSetup (Array.Array Evergreen.V377.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V377.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V377.WordSpellingGame.ActionWithTime) Evergreen.V377.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V377.SheepGame.ValidatedSetup (Array.Array Evergreen.V377.SheepGame.ActionWithTime) Evergreen.V377.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.UserSession.ToBeFilledInByBackend (Evergreen.V377.SecretId.SecretId Evergreen.V377.Id.GamePublicId))
    | LoadMatch (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) (Evergreen.V377.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Evergreen.V377.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V377.Go.GameModel
    | WordSpellingGame_Game Evergreen.V377.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V377.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V377.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V377.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V377.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V377.Id.Id Evergreen.V377.Id.ChannelMessageId, Evergreen.V377.SheepGame.Input ) Int
    }
