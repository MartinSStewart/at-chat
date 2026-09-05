module Evergreen.V368.Game exposing (..)

import Array
import Evergreen.V368.Go
import Evergreen.V368.Id
import Evergreen.V368.Message
import Evergreen.V368.SecretId
import Evergreen.V368.SheepGame
import Evergreen.V368.UserSession
import Evergreen.V368.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V368.Go.GameMsg
    | GoSetupMsg Evergreen.V368.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V368.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V368.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V368.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V368.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V368.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V368.Go.ValidatedSetup (Array.Array Evergreen.V368.Go.ActionWithTime) Evergreen.V368.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V368.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V368.WordSpellingGame.ActionWithTime) Evergreen.V368.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V368.SheepGame.ValidatedSetup (Array.Array Evergreen.V368.SheepGame.ActionWithTime) Evergreen.V368.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V368.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V368.Go.ValidatedSetup (Array.Array Evergreen.V368.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V368.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V368.WordSpellingGame.ActionWithTime) Evergreen.V368.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V368.SheepGame.ValidatedSetup (Array.Array Evergreen.V368.SheepGame.ActionWithTime) Evergreen.V368.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.UserSession.ToBeFilledInByBackend (Evergreen.V368.SecretId.SecretId Evergreen.V368.Id.GamePublicId))
    | LoadMatch (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) (Evergreen.V368.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Evergreen.V368.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V368.Go.GameModel
    | WordSpellingGame_Game Evergreen.V368.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V368.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V368.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V368.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V368.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V368.Id.Id Evergreen.V368.Id.ChannelMessageId, Evergreen.V368.SheepGame.Input ) Int
    }
