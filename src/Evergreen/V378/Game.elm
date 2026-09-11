module Evergreen.V378.Game exposing (..)

import Array
import Evergreen.V378.Go
import Evergreen.V378.Id
import Evergreen.V378.Message
import Evergreen.V378.SecretId
import Evergreen.V378.SheepGame
import Evergreen.V378.UserSession
import Evergreen.V378.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V378.Go.GameMsg
    | GoSetupMsg Evergreen.V378.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V378.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V378.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V378.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V378.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V378.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V378.Go.ValidatedSetup (Array.Array Evergreen.V378.Go.ActionWithTime) Evergreen.V378.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V378.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V378.WordSpellingGame.ActionWithTime) Evergreen.V378.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V378.SheepGame.ValidatedSetup (Array.Array Evergreen.V378.SheepGame.ActionWithTime) Evergreen.V378.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V378.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V378.Go.ValidatedSetup (Array.Array Evergreen.V378.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V378.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V378.WordSpellingGame.ActionWithTime) Evergreen.V378.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V378.SheepGame.ValidatedSetup (Array.Array Evergreen.V378.SheepGame.ActionWithTime) Evergreen.V378.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.UserSession.ToBeFilledInByBackend (Evergreen.V378.SecretId.SecretId Evergreen.V378.Id.GamePublicId))
    | LoadMatch (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) (Evergreen.V378.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Evergreen.V378.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V378.Go.GameModel
    | WordSpellingGame_Game Evergreen.V378.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V378.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V378.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V378.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V378.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V378.Id.Id Evergreen.V378.Id.ChannelMessageId, Evergreen.V378.SheepGame.Input ) Int
    }
