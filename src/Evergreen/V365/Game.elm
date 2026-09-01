module Evergreen.V365.Game exposing (..)

import Array
import Evergreen.V365.Go
import Evergreen.V365.Id
import Evergreen.V365.Message
import Evergreen.V365.SecretId
import Evergreen.V365.SheepGame
import Evergreen.V365.UserSession
import Evergreen.V365.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V365.Go.GameMsg
    | GoSetupMsg Evergreen.V365.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V365.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V365.WordSpellingGame.SetupMsg
    | SheepGameMsg Evergreen.V365.SheepGame.GameMsg
    | SheepSetupMsg Evergreen.V365.SheepGame.SetupMsg
    | PressedShareMatch (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V365.Message.GameType
    | CheckedSheepGameQuestionsDebounce Int
    | CheckedSheepGameSaveDebounce (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.SheepGame.Input Int
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V365.Go.ValidatedSetup (Array.Array Evergreen.V365.Go.ActionWithTime) Evergreen.V365.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V365.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V365.WordSpellingGame.ActionWithTime) Evergreen.V365.WordSpellingGame.Shared
    | FrontendGameData_SheepGame Evergreen.V365.SheepGame.ValidatedSetup (Array.Array Evergreen.V365.SheepGame.ActionWithTime) Evergreen.V365.SheepGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.GamePublicId)
        }
    | MatchNotLoaded Evergreen.V365.Message.GameType


type BackendGameData
    = GameData_Go Evergreen.V365.Go.ValidatedSetup (Array.Array Evergreen.V365.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V365.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V365.WordSpellingGame.ActionWithTime) Evergreen.V365.WordSpellingGame.Shared
    | GameData_SheepGame Evergreen.V365.SheepGame.ValidatedSetup (Array.Array Evergreen.V365.SheepGame.ActionWithTime) Evergreen.V365.SheepGame.Shared


type alias LoadedMatch =
    { gameData : BackendGameData
    , publicLink : Maybe (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.GamePublicId)
    }


type LocalChange
    = CreatePublicLink (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.UserSession.ToBeFilledInByBackend (Evergreen.V365.SecretId.SecretId Evergreen.V365.Id.GamePublicId))
    | LoadMatch (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) (Evergreen.V365.UserSession.ToBeFilledInByBackend LoadedMatch)
    | LocalChange_Go (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.WordSpellingGame.LocalChange
    | LocalChange_SheepGame (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Evergreen.V365.SheepGame.LocalChange


type Game
    = GoModel_Game Evergreen.V365.Go.GameModel
    | WordSpellingGame_Game Evergreen.V365.WordSpellingGame.GameData
    | SheepGame_Game Evergreen.V365.SheepGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V365.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V365.WordSpellingGame.SetupModel
    | SheepGame_Setup Evergreen.V365.SheepGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId) Game
    , setup : Setup
    , sheepGameQuestionsCounter : Int
    , sheepGameSaveCounters : SeqDict.SeqDict ( Evergreen.V365.Id.Id Evergreen.V365.Id.ChannelMessageId, Evergreen.V365.SheepGame.Input ) Int
    }
