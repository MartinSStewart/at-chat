module Evergreen.V379.Game exposing (..)

import Array
import Evergreen.V379.Go
import Evergreen.V379.Id
import Evergreen.V379.Message
import Evergreen.V379.SecretId
import Evergreen.V379.SheepGame
import Evergreen.V379.UserSession
import Evergreen.V379.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V379.Go.GameMsg
    | GoSetupMsg Evergreen.V379.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V379.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V379.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V379.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V379.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V379.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V379.Go.ValidatedSetup (Array.Array Evergreen.V379.Go.ActionWithTime) Evergreen.V379.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V379.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V379.WordSpellingGame.ActionWithTime) Evergreen.V379.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V379.SheepGame.ValidatedSetup (Array.Array Evergreen.V379.SheepGame.ActionWithTime) Evergreen.V379.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V379.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V379.Go.ValidatedSetup (Array.Array Evergreen.V379.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V379.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V379.WordSpellingGame.ActionWithTime) Evergreen.V379.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V379.SheepGame.ValidatedSetup (Array.Array Evergreen.V379.SheepGame.ActionWithTime) Evergreen.V379.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.UserSession.ToBeFilledInByBackend (Evergreen.V379.SecretId.SecretId Evergreen.V379.Id.GamePublicId))
    | LoadMatch (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) (Evergreen.V379.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Evergreen.V379.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V379.Go.GameModel
    | WordSpellingGame_Game Evergreen.V379.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V379.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V379.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V379.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V379.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V379.Id.Id Evergreen.V379.Id.ChannelMessageId, Evergreen.V379.SheepGame.Input ) Int
    }
