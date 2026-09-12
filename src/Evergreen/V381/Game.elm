module Evergreen.V381.Game exposing (..)

import Array
import Evergreen.V381.Go
import Evergreen.V381.Id
import Evergreen.V381.Message
import Evergreen.V381.SecretId
import Evergreen.V381.SheepGame
import Evergreen.V381.UserSession
import Evergreen.V381.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V381.Go.GameMsg
    | GoSetupMsg Evergreen.V381.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V381.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V381.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V381.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V381.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V381.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V381.Go.ValidatedSetup (Array.Array Evergreen.V381.Go.ActionWithTime) Evergreen.V381.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V381.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V381.WordSpellingGame.ActionWithTime) Evergreen.V381.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V381.SheepGame.ValidatedSetup (Array.Array Evergreen.V381.SheepGame.ActionWithTime) Evergreen.V381.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V381.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V381.Go.ValidatedSetup (Array.Array Evergreen.V381.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V381.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V381.WordSpellingGame.ActionWithTime) Evergreen.V381.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V381.SheepGame.ValidatedSetup (Array.Array Evergreen.V381.SheepGame.ActionWithTime) Evergreen.V381.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.UserSession.ToBeFilledInByBackend (Evergreen.V381.SecretId.SecretId Evergreen.V381.Id.GamePublicId))
    | LoadMatch (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) (Evergreen.V381.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Evergreen.V381.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V381.Go.GameModel
    | WordSpellingGame_Game Evergreen.V381.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V381.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V381.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V381.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V381.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V381.Id.Id Evergreen.V381.Id.ChannelMessageId, Evergreen.V381.SheepGame.Input ) Int
    }
