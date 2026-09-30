module Evergreen.V395.Game exposing (..)

import Array
import Evergreen.V395.Go
import Evergreen.V395.Id
import Evergreen.V395.Message
import Evergreen.V395.SecretId
import Evergreen.V395.SheepGame
import Evergreen.V395.UserSession
import Evergreen.V395.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V395.Go.GameMsg
    | GoSetupMsg Evergreen.V395.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V395.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V395.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V395.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V395.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V395.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V395.Go.ValidatedSetup (Array.Array Evergreen.V395.Go.ActionWithTime) Evergreen.V395.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V395.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V395.WordSpellingGame.ActionWithTime) Evergreen.V395.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V395.SheepGame.ValidatedSetup (Array.Array Evergreen.V395.SheepGame.ActionWithTime) Evergreen.V395.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V395.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V395.Go.ValidatedSetup (Array.Array Evergreen.V395.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V395.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V395.WordSpellingGame.ActionWithTime) Evergreen.V395.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V395.SheepGame.ValidatedSetup (Array.Array Evergreen.V395.SheepGame.ActionWithTime) Evergreen.V395.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.UserSession.ToBeFilledInByBackend (Evergreen.V395.SecretId.SecretId Evergreen.V395.Id.GamePublicId))
    | LoadMatch (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) (Evergreen.V395.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Evergreen.V395.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V395.Go.GameModel
    | WordSpellingGame_Game Evergreen.V395.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V395.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V395.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V395.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V395.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V395.Id.Id Evergreen.V395.Id.ChannelMessageId, Evergreen.V395.SheepGame.Input ) Int
    }
