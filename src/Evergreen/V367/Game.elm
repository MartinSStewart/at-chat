module Evergreen.V367.Game exposing (..)

import Array
import Evergreen.V367.Go
import Evergreen.V367.Id
import Evergreen.V367.Message
import Evergreen.V367.SecretId
import Evergreen.V367.SheepGame
import Evergreen.V367.UserSession
import Evergreen.V367.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V367.Go.GameMsg
    | GoSetupMsg Evergreen.V367.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V367.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V367.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V367.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V367.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V367.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V367.Go.ValidatedSetup (Array.Array Evergreen.V367.Go.ActionWithTime) Evergreen.V367.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V367.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V367.WordSpellingGame.ActionWithTime) Evergreen.V367.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V367.SheepGame.ValidatedSetup (Array.Array Evergreen.V367.SheepGame.ActionWithTime) Evergreen.V367.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V367.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V367.Go.ValidatedSetup (Array.Array Evergreen.V367.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V367.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V367.WordSpellingGame.ActionWithTime) Evergreen.V367.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V367.SheepGame.ValidatedSetup (Array.Array Evergreen.V367.SheepGame.ActionWithTime) Evergreen.V367.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.UserSession.ToBeFilledInByBackend (Evergreen.V367.SecretId.SecretId Evergreen.V367.Id.GamePublicId))
    | LoadMatch (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) (Evergreen.V367.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Evergreen.V367.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V367.Go.GameModel
    | WordSpellingGame_Game Evergreen.V367.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V367.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V367.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V367.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V367.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V367.Id.Id Evergreen.V367.Id.ChannelMessageId, Evergreen.V367.SheepGame.Input ) Int
    }
