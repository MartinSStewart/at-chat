module Evergreen.V364.Game exposing (..)

import Array
import Evergreen.V364.Go
import Evergreen.V364.Id
import Evergreen.V364.Message
import Evergreen.V364.SecretId
import Evergreen.V364.SheepGame
import Evergreen.V364.UserSession
import Evergreen.V364.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V364.Go.GameMsg
    | GoSetupMsg Evergreen.V364.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V364.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V364.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V364.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V364.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V364.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V364.Go.ValidatedSetup (Array.Array Evergreen.V364.Go.ActionWithTime) Evergreen.V364.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V364.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V364.WordSpellingGame.ActionWithTime) Evergreen.V364.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V364.SheepGame.ValidatedSetup (Array.Array Evergreen.V364.SheepGame.ActionWithTime) Evergreen.V364.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V364.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V364.Go.ValidatedSetup (Array.Array Evergreen.V364.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V364.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V364.WordSpellingGame.ActionWithTime) Evergreen.V364.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V364.SheepGame.ValidatedSetup (Array.Array Evergreen.V364.SheepGame.ActionWithTime) Evergreen.V364.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.UserSession.ToBeFilledInByBackend (Evergreen.V364.SecretId.SecretId Evergreen.V364.Id.GamePublicId))
    | LoadMatch (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) (Evergreen.V364.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Evergreen.V364.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V364.Go.GameModel
    | WordSpellingGame_Game Evergreen.V364.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V364.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V364.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V364.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V364.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V364.Id.Id Evergreen.V364.Id.ChannelMessageId, Evergreen.V364.SheepGame.Input ) Int
    }
