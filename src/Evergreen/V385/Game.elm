module Evergreen.V385.Game exposing (..)

import Array
import Evergreen.V385.Go
import Evergreen.V385.Id
import Evergreen.V385.Message
import Evergreen.V385.SecretId
import Evergreen.V385.SheepGame
import Evergreen.V385.UserSession
import Evergreen.V385.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V385.Go.GameMsg
    | GoSetupMsg Evergreen.V385.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V385.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V385.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V385.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V385.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V385.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V385.Go.ValidatedSetup (Array.Array Evergreen.V385.Go.ActionWithTime) Evergreen.V385.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V385.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V385.WordSpellingGame.ActionWithTime) Evergreen.V385.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V385.SheepGame.ValidatedSetup (Array.Array Evergreen.V385.SheepGame.ActionWithTime) Evergreen.V385.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V385.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V385.Go.ValidatedSetup (Array.Array Evergreen.V385.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V385.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V385.WordSpellingGame.ActionWithTime) Evergreen.V385.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V385.SheepGame.ValidatedSetup (Array.Array Evergreen.V385.SheepGame.ActionWithTime) Evergreen.V385.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.UserSession.ToBeFilledInByBackend (Evergreen.V385.SecretId.SecretId Evergreen.V385.Id.GamePublicId))
    | LoadMatch (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) (Evergreen.V385.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Evergreen.V385.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V385.Go.GameModel
    | WordSpellingGame_Game Evergreen.V385.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V385.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V385.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V385.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V385.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V385.Id.Id Evergreen.V385.Id.ChannelMessageId, Evergreen.V385.SheepGame.Input ) Int
    }
